// Thin client for the Anticode intranet API. Anticode uses a single shared
// password and an httpOnly cookie session, so we log in once, keep the cookie,
// and re-authenticate automatically if the session expires (401).

const BASE = (process.env.ANTICODE_BASE || "http://192.168.0.180:8080").replace(/\/+$/, "");
const PASSWORD = process.env.APP_PASSWORD || "";

let cookie = null;

async function login() {
  if (!PASSWORD) {
    throw new Error("APP_PASSWORD is not set — the MCP server can't log in to Anticode.");
  }
  const res = await fetch(`${BASE}/api/auth/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ password: PASSWORD }),
  });
  if (!res.ok) {
    const detail = await res.text().catch(() => "");
    throw new Error(
      `Login to Anticode at ${BASE} failed (${res.status}). ` +
        `Check ANTICODE_BASE and APP_PASSWORD. ${detail}`.trim()
    );
  }
  const setCookie = res.headers.get("set-cookie");
  cookie = setCookie ? setCookie.split(";")[0] : cookie;
  return cookie;
}

async function req(method, path, body) {
  const send = () =>
    fetch(`${BASE}${path}`, {
      method,
      headers: {
        ...(body !== undefined ? { "Content-Type": "application/json" } : {}),
        ...(cookie ? { Cookie: cookie } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

  if (!cookie) await login();
  let res = await send();
  if (res.status === 401) {
    await login();
    res = await send();
  }

  const text = await res.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }
  if (!res.ok) {
    const msg = data && data.error ? data.error : `Request failed (${res.status})`;
    throw new Error(typeof msg === "string" ? msg : JSON.stringify(msg));
  }
  return data;
}

export const anticode = {
  base: BASE,

  // Calendar
  listEvents(from, to) {
    const p = new URLSearchParams();
    if (from) p.set("from", from);
    if (to) p.set("to", to);
    const qs = p.toString();
    return req("GET", `/api/events${qs ? `?${qs}` : ""}`);
  },
  createEvent: (data) => req("POST", "/api/events", data),
  updateEvent: (id, data) => req("PUT", `/api/events/${id}`, data),
  deleteEvent: (id) => req("DELETE", `/api/events/${id}`),

  // Projects
  listProjects: () => req("GET", "/api/projects"),
  createProject: (data) => req("POST", "/api/projects", data),
  updateProject: (id, data) => req("PUT", `/api/projects/${id}`, data),
  addUpdate: (id, data) => req("POST", `/api/projects/${id}/updates`, data),
};
