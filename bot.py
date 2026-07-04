"""Personal Telegram bot bridged to a local LLM.

Only responds to the Telegram user IDs listed in ALLOWED_USER_IDS.
Talks to any OpenAI-compatible chat completions endpoint
(Ollama, LM Studio, llama.cpp server, vLLM, ...).
"""

import logging
import os

import httpx
from dotenv import load_dotenv
from telegram import Update
from telegram.constants import ChatAction
from telegram.ext import (
    Application,
    CommandHandler,
    ContextTypes,
    MessageHandler,
    filters,
)

load_dotenv()

TELEGRAM_TOKEN = os.environ["TELEGRAM_BOT_TOKEN"]
ALLOWED_USER_IDS = {
    int(uid) for uid in os.environ["ALLOWED_USER_IDS"].replace(",", " ").split()
}

LLM_BASE_URL = os.getenv("LLM_BASE_URL", "http://localhost:11434/v1")
LLM_MODEL = os.getenv("LLM_MODEL", "llama3.1")
LLM_API_KEY = os.getenv("LLM_API_KEY", "not-needed")  # local servers usually ignore it
SYSTEM_PROMPT = os.getenv("SYSTEM_PROMPT", "You are a helpful assistant.")
MAX_HISTORY_MESSAGES = int(os.getenv("MAX_HISTORY_MESSAGES", "40"))
LLM_TIMEOUT_SECONDS = float(os.getenv("LLM_TIMEOUT_SECONDS", "300"))

TELEGRAM_MESSAGE_LIMIT = 4096

logging.basicConfig(
    format="%(asctime)s %(levelname)s %(name)s: %(message)s", level=logging.INFO
)
# The HTTP libraries log every polling request at INFO; quiet them down.
logging.getLogger("httpx").setLevel(logging.WARNING)
log = logging.getLogger("bot")

# chat_id -> list of {"role": ..., "content": ...} (system prompt not stored)
histories: dict[int, list[dict[str, str]]] = {}


def is_allowed(update: Update) -> bool:
    user = update.effective_user
    allowed = user is not None and user.id in ALLOWED_USER_IDS
    if not allowed and user is not None:
        log.warning("Ignoring message from unauthorized user %s (%s)",
                    user.id, user.username)
    return allowed


async def query_llm(messages: list[dict[str, str]]) -> str:
    payload = {
        "model": LLM_MODEL,
        "messages": [{"role": "system", "content": SYSTEM_PROMPT}, *messages],
        "stream": False,
    }
    headers = {"Authorization": f"Bearer {LLM_API_KEY}"}
    async with httpx.AsyncClient(timeout=LLM_TIMEOUT_SECONDS) as client:
        resp = await client.post(
            f"{LLM_BASE_URL.rstrip('/')}/chat/completions",
            json=payload,
            headers=headers,
        )
        resp.raise_for_status()
        data = resp.json()
    return data["choices"][0]["message"]["content"]


def split_message(text: str, limit: int = TELEGRAM_MESSAGE_LIMIT) -> list[str]:
    """Split text into Telegram-sized chunks, preferring newline boundaries."""
    chunks = []
    while len(text) > limit:
        cut = text.rfind("\n", 0, limit)
        if cut <= 0:
            cut = limit
        chunks.append(text[:cut])
        text = text[cut:].lstrip("\n")
    if text:
        chunks.append(text)
    return chunks


async def cmd_start(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not is_allowed(update):
        return
    await update.message.reply_text(
        f"Hi! I'm your local LLM ({LLM_MODEL}). Send me a message.\n"
        "Commands: /reset — clear conversation history"
    )


async def cmd_reset(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not is_allowed(update):
        return
    histories.pop(update.effective_chat.id, None)
    await update.message.reply_text("Conversation history cleared.")


async def handle_message(update: Update, context: ContextTypes.DEFAULT_TYPE) -> None:
    if not is_allowed(update):
        return

    chat_id = update.effective_chat.id
    history = histories.setdefault(chat_id, [])
    history.append({"role": "user", "content": update.message.text})

    await context.bot.send_chat_action(chat_id=chat_id, action=ChatAction.TYPING)
    try:
        reply = await query_llm(history)
    except httpx.ConnectError:
        history.pop()
        await update.message.reply_text(
            f"Can't reach the LLM server at {LLM_BASE_URL}. Is it running?"
        )
        return
    except Exception:
        history.pop()
        log.exception("LLM request failed")
        await update.message.reply_text("LLM request failed — check the bot logs.")
        return

    history.append({"role": "assistant", "content": reply})
    # Trim in pairs so history always starts with a user message.
    if len(history) > MAX_HISTORY_MESSAGES:
        del history[: len(history) - MAX_HISTORY_MESSAGES]
        if history and history[0]["role"] == "assistant":
            del history[0]

    for chunk in split_message(reply):
        await update.message.reply_text(chunk)


def main() -> None:
    app = Application.builder().token(TELEGRAM_TOKEN).build()
    app.add_handler(CommandHandler("start", cmd_start))
    app.add_handler(CommandHandler("reset", cmd_reset))
    app.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_message))

    log.info("Bot starting. Allowed users: %s. LLM: %s at %s",
             sorted(ALLOWED_USER_IDS), LLM_MODEL, LLM_BASE_URL)
    app.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()
