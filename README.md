# Anticode — Personal Intranet

A small, self-hostable home intranet. **C# (ASP.NET Core) backend + Svelte
frontend**, single-password auth, SQLite storage, no external services. Two
sections, switched from the top nav:

- **Calendar** — a private month calendar for you and your family. Events carry
  a time (or all-day), location, who's involved, a colour, and notes. Nothing
  leaves your server.
- **Projects** — the original project-assessment tracker (described below).

A third nav item, **Chat ↗**, links out to the companion LocalLLM app; set its
URL with `VITE_CHAT_URL` at build time (defaults to `http://localhost:3000`).

### Let your LLM act on the calendar

`mcp/` is an MCP server that exposes the calendar and projects as tools your
local LLM can call — so you can just say *"add dentist Thursday 3pm"* in chat.
See [`mcp/README.md`](mcp/README.md) for LM Studio setup.

## Projects tracker

Each **project** has headline figures (hours, % complete, bugs, first-pass
status). Every project row expands with a dropdown arrow to reveal a timeline of
**updates** — point-in-time snapshots that reference the project's GUID and
record percent complete, engineer/agent hour estimates, estimated time to
completion, bugs found/fixed, and free-form notes.

## Stack

| layer | tech |
|---|---|
| Backend | ASP.NET Core 8 minimal API, EF Core (SQLite) |
| Auth | cookie session, one shared password |
| Frontend | Svelte 4 + Vite |
| Storage | SQLite file (easy to back up — just copy it) |

In production the backend serves the compiled Svelte app out of
`server/wwwroot`, so it deploys as a **single process**.

## Schema

**Project**
| field | type | notes |
|---|---|---|
| `id` | guid | the "project id" |
| `name` | text | |
| `description` | text | |
| `firstPassCompletion` | bool | first pass done? |
| `estimatedEngineerHours` | number | |
| `estimatedAgentHours` | number | |
| `percentComplete` | number | 0–100 |
| `bugs` | int | current open bug count |
| `createdAt` / `updatedAt` | timestamp | |

**Update** (spawns under a project)
| field | type | notes |
|---|---|---|
| `id` | guid | the "update id" |
| `projectId` | guid | references the parent project's GUID |
| `percentComplete` | number | 0–100 |
| `estimatedEngHours` | number | |
| `estimatedAgentHours` | number | |
| `estimatedTimeToCompletion` | text | e.g. "2 weeks", "40h" |
| `notes` | text | |
| `bugsFound` | int | |
| `bugsFixed` | int | |
| `createdAt` | timestamp | |

Adding an update also rolls its percent-complete and hour estimates up onto the
parent project, so the project row always shows the latest status.

**CalendarEvent**
| field | type | notes |
|---|---|---|
| `id` | guid | |
| `title` | text | required |
| `notes` | text | free-form |
| `location` | text | |
| `attendees` | text | comma-separated people, e.g. "Mum, Ava" |
| `startsAt` / `endsAt` | timestamp | UTC instants (client renders local) |
| `allDay` | bool | ignore the time components when true |
| `color` | text | hex tint for the calendar grid |
| `createdAt` / `updatedAt` | timestamp | |

Calendar API (all require the session):
`GET /api/events?from=<iso>&to=<iso>` (overlapping the window) ·
`POST /api/events` · `PUT /api/events/{id}` · `DELETE /api/events/{id}`.

## Prerequisites

- [.NET SDK 8](https://dotnet.microsoft.com/download) (`dotnet --version`)
- [Node.js 18+](https://nodejs.org) (`node --version`)

## Develop locally

Run the backend and the Vite dev server in two terminals. Vite proxies `/api`
to the backend (`http://localhost:5059`).

```bash
# terminal 1 — backend
cd server
APP_PASSWORD=dev dotnet run          # http://localhost:5059

# terminal 2 — frontend (hot reload)
cd client
npm install
npm run dev                          # http://localhost:5173
```

Open http://localhost:5173 and log in with the password you set.

## Run as a single process (production-style)

Build the Svelte app into `server/wwwroot`, then run the server, which serves
both the API and the SPA:

```bash
cd client && npm install && npm run build     # -> server/wwwroot
cd ../server
APP_PASSWORD='your-password' \
ASPNETCORE_URLS='http://0.0.0.0:8080' \
dotnet run -c Release                          # http://localhost:8080
```

## Environment variables

| var | required | default | purpose |
|---|---|---|---|
| `APP_PASSWORD` | yes | — | the login password |
| `DATABASE_PATH` | no | `<app>/data/assessment.db` | SQLite file location |
| `ASPNETCORE_URLS` | no | framework default | bind address/port |

## Docker

```bash
docker build -t anticode .
docker run -d -p 8080:8080 \
  -e APP_PASSWORD='your-password' \
  -v anticode-data:/data \
  anticode
```

The database lives in the `/data` volume, so it survives restarts and
upgrades. Back it up by copying `assessment.db`.

## Auth model

One shared password (`APP_PASSWORD`). On login the server issues an httpOnly
cookie session (30-day sliding expiry). API routes require the session; the
Svelte app checks `GET /api/auth/me` on load to decide whether to show the
login screen or the dashboard. Intended for a single user deploying the app for
themselves — put it behind HTTPS in production.

## Project layout

```
server/            ASP.NET Core API + static host
  Program.cs       endpoints, auth, DB bootstrap
  Models/          Project, ProjectUpdate, DTOs
  Data/            EF Core DbContext
  wwwroot/         built SPA (generated; git-ignored)
client/            Svelte + Vite SPA
  src/
    App.svelte     auth gate
    lib/           Login, Dashboard, ProjectRow, forms, Modal, api.js
```
