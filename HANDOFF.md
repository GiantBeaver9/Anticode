# Anticode — Integration Handoff

Notes for another agent/developer incorporating this app into an intranet.

- **Branch:** `claude/personal-assessment-app-wc4d2p` on GiantBeaver9/Anticode
- **Layout:** `server/` (ASP.NET Core 8 minimal API + EF Core/SQLite, also serves
  the SPA) · `client/` (Svelte 4 + Vite)
- **Prereqs:** .NET SDK 8, Node 18+

## Run (single process)

Build the client into `server/wwwroot`, then run the server:

```bash
cd client && npm install && npm run build
cd ../server && APP_PASSWORD=secret ASPNETCORE_URLS=http://0.0.0.0:8080 dotnet run -c Release
```

## Environment variables

| var | required | default | purpose |
|---|---|---|---|
| `APP_PASSWORD` | yes | — | login password |
| `DATABASE_PATH` | no | `<app>/data/assessment.db` | SQLite file location |
| `ASPNETCORE_URLS` | no | framework default | bind address/port |

## Auth

Single shared password → httpOnly cookie session (`anticode_session`, 30-day
sliding expiry). All `/api/*` routes except `/api/auth/*` require the session.

## API

- `POST /api/auth/login` `{password}` · `POST /api/auth/logout` · `GET /api/auth/me`
- `GET /api/projects` (projects with nested `updates`) · `POST /api/projects`
  · `PUT /api/projects/{id}` · `DELETE /api/projects/{id}`
- `POST /api/projects/{id}/updates` · `DELETE /api/updates/{id}`

## Data model

**Project**: id, name, description, firstPassCompletion, estimatedEngineerHours,
estimatedAgentHours, percentComplete, bugs
→ has many **Update**: id, projectId, percentComplete, estimatedEngHours,
estimatedAgentHours, estimatedTimeToCompletion, notes, bugsFound, bugsFixed

Adding an update rolls its latest figures onto the parent project (latest-wins).

## Storage

Single SQLite file. Schema is auto-created on first run via `EnsureCreated()` —
**not** migrations. If you extend the schema, either delete the dev DB or switch
the project to EF Core migrations. Back up by copying the `.db` file.

## Intranet notes

- Put it behind HTTPS. The cookie uses `SecurePolicy = SameAsRequest`, so it
  becomes a Secure cookie automatically once served over HTTPS.
- Single-user by design. Multi-user would mean replacing the shared-password
  auth with real accounts.

See `README.md` for the full dev workflow, Docker instructions, and project
layout.
