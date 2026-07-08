// Thin fetch wrapper. All requests are same-origin and rely on the session
// cookie set by the backend, so we just send `credentials: same-origin`.

async function request(method, url, body) {
  const opts = {
    method,
    headers: {},
    credentials: "same-origin",
  };
  if (body !== undefined) {
    opts.headers["Content-Type"] = "application/json";
    opts.body = JSON.stringify(body);
  }

  const res = await fetch(url, opts);

  if (res.status === 204) return null;

  let data = null;
  const text = await res.text();
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }

  if (!res.ok) {
    const message =
      (data && data.error) || `Request failed (${res.status})`;
    const err = new Error(message);
    err.status = res.status;
    throw err;
  }
  return data;
}

export const api = {
  // auth
  me: () => request("GET", "/api/auth/me"),
  login: (password) => request("POST", "/api/auth/login", { password }),
  logout: () => request("POST", "/api/auth/logout"),

  // projects
  listProjects: () => request("GET", "/api/projects"),
  createProject: (data) => request("POST", "/api/projects", data),
  updateProject: (id, data) => request("PUT", `/api/projects/${id}`, data),
  deleteProject: (id) => request("DELETE", `/api/projects/${id}`),

  // updates
  addUpdate: (projectId, data) =>
    request("POST", `/api/projects/${projectId}/updates`, data),
  deleteUpdate: (id) => request("DELETE", `/api/updates/${id}`),

  // calendar
  listEvents: (from, to) => {
    const params = new URLSearchParams();
    if (from) params.set("from", from);
    if (to) params.set("to", to);
    const qs = params.toString();
    return request("GET", `/api/events${qs ? `?${qs}` : ""}`);
  },
  createEvent: (data) => request("POST", "/api/events", data),
  updateEvent: (id, data) => request("PUT", `/api/events/${id}`, data),
  deleteEvent: (id) => request("DELETE", `/api/events/${id}`),
};
