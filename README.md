# Personal Telegram → Local LLM Bot

A tiny Telegram bot that runs on your PC and lets you chat with your local LLM
(LM Studio by default; Ollama, llama.cpp server, or anything with an
OpenAI-compatible API also works) from anywhere. It **only responds to your
Telegram account**; everyone else is silently ignored.

It uses long polling, so it works behind your home router with **no port
forwarding, public IP, or webhook setup**.

## Features

- 🔒 Locked to your Telegram user ID, and only in private chats — it stays
  silent in groups even if someone adds it to one
- 🎛️ Auto-detects whatever model you have loaded in LM Studio (no config
  change needed when you swap models)
- 🧠 Per-chat conversation memory with `/reset` to clear it
- ✂️ Automatically splits replies longer than Telegram's 4096-character limit
- ⌨️ Shows "typing…" while the model is thinking
- 🔌 Works with any OpenAI-compatible endpoint

## Setup

### 1. Create the bot

1. Open Telegram and message [@BotFather](https://t.me/BotFather)
2. Send `/newbot`, pick a name and a username
3. Copy the token it gives you (looks like `123456789:AAxxx...`)

Optional but recommended: send BotFather `/setjoingroups` → **Disable** so the
bot can't be added to groups.

### 2. Find your Telegram user ID

Message [@userinfobot](https://t.me/userinfobot) — it replies with your numeric
ID (e.g. `123456789`). This is what locks the bot to you.

### 3. Start LM Studio's local server

1. In LM Studio, load the model you want to chat with
2. Open the **Developer** tab and start the server (default: port 1234)
3. Optionally enable "Run server on startup" so it survives reboots

Leave "Serve on Local Network" **off** — the bot runs on the same PC, so the
server only needs to listen on localhost.

The bot auto-detects the loaded model, so you don't need to configure a model
name — swap models in LM Studio whenever you like.

(Using Ollama or llama.cpp instead? Just point `LLM_BASE_URL` at it and set
`LLM_MODEL`.)

### 4. Configure and run the bot

```bash
git clone <this repo> && cd Anticode
python -m venv .venv
source .venv/bin/activate        # Windows: .venv\Scripts\activate
pip install -r requirements.txt

cp .env.example .env             # Windows: copy .env.example .env
# edit .env: set TELEGRAM_BOT_TOKEN and ALLOWED_USER_IDS

python bot.py
```

Message your bot on Telegram — it should reply using your local model.

## Commands

| Command  | What it does                       |
|----------|------------------------------------|
| `/start` | Sanity check that the bot is alive |
| `/reset` | Clear the conversation history     |

## Run it in the background

**Linux (systemd)** — create `/etc/systemd/system/telegram-llm-bot.service`:

```ini
[Unit]
Description=Telegram local LLM bot
After=network-online.target

[Service]
WorkingDirectory=/path/to/Anticode
ExecStart=/path/to/Anticode/.venv/bin/python bot.py
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

Then `sudo systemctl enable --now telegram-llm-bot`.

**Windows** — easiest option is Task Scheduler: create a task that runs
`C:\path\to\Anticode\.venv\Scripts\pythonw.exe bot.py` at logon, with
"Start in" set to the repo folder.

## Security notes

- The auth check happens **before** anything is sent to the LLM — strangers
  who find your bot get no response and never touch your model. Unauthorized
  attempts are logged with the sender's user ID.
- Group/channel messages are ignored entirely; the bot only answers you in a
  private chat.
- Keep `.env` private; the bot token lets anyone impersonate your bot
  (it's gitignored here). If it leaks, revoke it with BotFather's `/revoke`.
- The bot makes outbound connections only (to Telegram and to localhost);
  it doesn't open any listening ports on your PC.
