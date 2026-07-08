#!/usr/bin/env node
// MCP server exposing the Anticode intranet (private family calendar + project
// tracker) as tools your local LLM can call. Runs over stdio, so an MCP host
// like LM Studio launches it directly.
//
// Config (env):
//   ANTICODE_BASE   base URL of the Anticode server (default http://192.168.0.180:8080)
//   APP_PASSWORD    the Anticode login password (required)

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { z } from "zod";
import { anticode } from "./client.js";

// Normalize a caller-supplied date/time into a UTC ISO instant, matching how
// the web client stores events. Accepts wall-clock ISO ("2026-07-09T15:00:00",
// interpreted in this machine's local zone) or a zoned/UTC ISO string.
function toIso(value) {
  if (value == null || value === "") return undefined;
  const d = new Date(value);
  if (Number.isNaN(d.getTime())) {
    throw new Error(`Invalid date/time: "${value}". Use ISO 8601, e.g. 2026-07-09T15:00:00`);
  }
  return d.toISOString();
}

function text(obj) {
  return {
    content: [
      { type: "text", text: typeof obj === "string" ? obj : JSON.stringify(obj, null, 2) },
    ],
  };
}

function fail(err) {
  return {
    isError: true,
    content: [{ type: "text", text: `Error: ${err instanceof Error ? err.message : String(err)}` }],
  };
}

const server = new McpServer({ name: "anticode", version: "0.1.0" });

// ------------------------------------------------------------------ context
server.registerTool(
  "get_current_time",
  {
    description:
      "Get the current date and time and this machine's timezone. Call this " +
      "first to resolve relative dates like 'tomorrow' or 'Thursday 3pm' into " +
      "concrete ISO datetimes before creating or querying events.",
    inputSchema: {},
    annotations: { readOnlyHint: true },
  },
  async () => {
    const now = new Date();
    return text({
      iso: now.toISOString(),
      local: now.toLocaleString(),
      today: now.toISOString().slice(0, 10),
      timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
      weekday: now.toLocaleDateString(undefined, { weekday: "long" }),
    });
  }
);

// ------------------------------------------------------------------ calendar
server.registerTool(
  "list_events",
  {
    description:
      "List calendar events overlapping an optional time window. Times are ISO " +
      "8601. Omit both bounds to list everything.",
    inputSchema: {
      from: z.string().optional().describe("Window start, ISO 8601"),
      to: z.string().optional().describe("Window end, ISO 8601"),
    },
    annotations: { readOnlyHint: true },
  },
  async ({ from, to }) => {
    try {
      const events = await anticode.listEvents(toIso(from), toIso(to));
      return text(events);
    } catch (e) {
      return fail(e);
    }
  }
);

server.registerTool(
  "create_event",
  {
    description:
      "Create a calendar event. `startsAt` is required (ISO 8601 wall-clock, " +
      "e.g. 2026-07-09T15:00:00). For an all-day event set allDay=true and pass " +
      "startsAt at 00:00:00 (and endsAt at 23:59:59 of the last day).",
    inputSchema: {
      title: z.string().describe("Event title"),
      startsAt: z.string().describe("Start, ISO 8601"),
      endsAt: z.string().optional().describe("End, ISO 8601 (defaults to start)"),
      allDay: z.boolean().optional(),
      location: z.string().optional(),
      attendees: z.string().optional().describe("Comma-separated people, e.g. 'Mum, Ava'"),
      notes: z.string().optional(),
      color: z.string().optional().describe("Hex colour, e.g. #5b9dff"),
    },
  },
  async (a) => {
    try {
      const created = await anticode.createEvent({
        title: a.title,
        startsAt: toIso(a.startsAt),
        endsAt: toIso(a.endsAt),
        allDay: a.allDay ?? false,
        location: a.location ?? "",
        attendees: a.attendees ?? "",
        notes: a.notes ?? "",
        color: a.color,
      });
      return text({ ok: true, event: created });
    } catch (e) {
      return fail(e);
    }
  }
);

server.registerTool(
  "update_event",
  {
    description: "Update fields of an existing event by id. Only pass the fields to change.",
    inputSchema: {
      id: z.string().describe("Event id (GUID)"),
      title: z.string().optional(),
      startsAt: z.string().optional(),
      endsAt: z.string().optional(),
      allDay: z.boolean().optional(),
      location: z.string().optional(),
      attendees: z.string().optional(),
      notes: z.string().optional(),
      color: z.string().optional(),
    },
  },
  async (a) => {
    try {
      const patch = {};
      if (a.title !== undefined) patch.title = a.title;
      if (a.startsAt !== undefined) patch.startsAt = toIso(a.startsAt);
      if (a.endsAt !== undefined) patch.endsAt = toIso(a.endsAt);
      if (a.allDay !== undefined) patch.allDay = a.allDay;
      if (a.location !== undefined) patch.location = a.location;
      if (a.attendees !== undefined) patch.attendees = a.attendees;
      if (a.notes !== undefined) patch.notes = a.notes;
      if (a.color !== undefined) patch.color = a.color;
      const updated = await anticode.updateEvent(a.id, patch);
      return text({ ok: true, event: updated });
    } catch (e) {
      return fail(e);
    }
  }
);

server.registerTool(
  "delete_event",
  {
    description: "Delete a calendar event by id.",
    inputSchema: { id: z.string().describe("Event id (GUID)") },
    annotations: { destructiveHint: true },
  },
  async ({ id }) => {
    try {
      await anticode.deleteEvent(id);
      return text({ ok: true, deleted: id });
    } catch (e) {
      return fail(e);
    }
  }
);

// ------------------------------------------------------------------ projects
server.registerTool(
  "list_projects",
  {
    description: "List all projects with their nested updates.",
    inputSchema: {},
    annotations: { readOnlyHint: true },
  },
  async () => {
    try {
      return text(await anticode.listProjects());
    } catch (e) {
      return fail(e);
    }
  }
);

server.registerTool(
  "create_project",
  {
    description: "Create a project in the tracker.",
    inputSchema: {
      name: z.string(),
      description: z.string().optional(),
      firstPassCompletion: z.boolean().optional(),
      estimatedEngineerHours: z.number().optional(),
      estimatedAgentHours: z.number().optional(),
      percentComplete: z.number().optional().describe("0–100"),
      bugs: z.number().int().optional(),
    },
  },
  async (a) => {
    try {
      return text({ ok: true, project: await anticode.createProject(a) });
    } catch (e) {
      return fail(e);
    }
  }
);

server.registerTool(
  "add_project_update",
  {
    description:
      "Add a point-in-time update under a project. Its latest figures roll up " +
      "onto the parent project.",
    inputSchema: {
      projectId: z.string().describe("Parent project id (GUID)"),
      percentComplete: z.number().optional().describe("0–100"),
      estimatedEngHours: z.number().optional(),
      estimatedAgentHours: z.number().optional(),
      estimatedTimeToCompletion: z.string().optional().describe("e.g. '2 weeks'"),
      notes: z.string().optional(),
      bugsFound: z.number().int().optional(),
      bugsFixed: z.number().int().optional(),
    },
  },
  async (a) => {
    try {
      const { projectId, ...body } = a;
      return text({ ok: true, update: await anticode.addUpdate(projectId, body) });
    } catch (e) {
      return fail(e);
    }
  }
);

const transport = new StdioServerTransport();
await server.connect(transport);
// eslint-disable-next-line no-console
console.error(`[anticode-mcp] connected — proxying ${anticode.base}`);
