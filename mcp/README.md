# Anticode MCP server

Exposes your Anticode intranet — the private **calendar** and **project
tracker** — as tools your local LLM can call. With this loaded, you can say
things like *"add dentist Thursday at 3pm with Mum"* or *"what's on this
weekend?"* in your chat and the model will actually read and write your
calendar.

It's an [MCP](https://modelcontextprotocol.io) server that speaks over stdio, so
an MCP host (LM Studio, Claude Desktop, etc.) launches it directly. It talks to
the Anticode HTTP API over your LAN — by default `http://192.168.0.180:8080`.

```
LLM host (LM Studio)  ──stdio──▶  anticode-mcp  ──HTTP──▶  Anticode (192.168.0.180:8080)
```

## Tools

| tool | what it does |
|---|---|
| `get_current_time` | current date/time + timezone (anchor for "tomorrow", "Thursday 3pm") |
| `list_events` | events overlapping an optional `from`/`to` window |
| `create_event` | add an event (title, start/end, all-day, location, attendees, notes, colour) |
| `update_event` | change fields of an event by id |
| `delete_event` | remove an event by id |
| `list_projects` | all projects with their updates |
| `create_project` | add a project |
| `add_project_update` | add a progress update under a project |

## Setup

```bash
cd mcp
npm install
```

Configure via environment variables:

| var | default | purpose |
|---|---|---|
| `ANTICODE_BASE` | `http://192.168.0.180:8080` | your Anticode server's base URL |
| `APP_PASSWORD` | — | the Anticode login password (required) |

The server logs in once with `APP_PASSWORD`, keeps the session cookie, and
re-authenticates automatically if it expires.

### LM Studio

LM Studio → **Program** → edit `mcp.json` and add:

```json
{
  "mcpServers": {
    "anticode": {
      "command": "node",
      "args": ["C:\\path\\to\\Anticode\\mcp\\server.js"],
      "env": {
        "ANTICODE_BASE": "http://192.168.0.180:8080",
        "APP_PASSWORD": "your-password"
      }
    }
  }
}
```

Restart LM Studio, enable the `anticode` tools in a chat, and pick a model that
supports tool use.

### Quick manual check

```bash
ANTICODE_BASE=http://192.168.0.180:8080 APP_PASSWORD=your-password npm start
```

It should print `[anticode-mcp] connected …` and then wait on stdin for an MCP
host. (It won't do anything interactive on its own — that's expected.)

## Notes on time

Pass wall-clock ISO datetimes like `2026-07-09T15:00:00`; the server converts
them to UTC instants the same way the web app does, so events line up in the
calendar. Call `get_current_time` first so the model can turn relative phrases
into concrete datetimes in your timezone.
