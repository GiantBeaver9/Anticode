// Small date helpers for the calendar. Events are stored as UTC instants on the
// server; here we convert to/from the browser's local time for display and for
// the <input type="date">/<input type="time"> fields (which are always local).

const MONTHS = [
  "January", "February", "March", "April", "May", "June",
  "July", "August", "September", "October", "November", "December",
];
const WEEKDAYS = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"];

export { MONTHS, WEEKDAYS };

// Local YYYY-MM-DD for a Date (used both as a grid key and for date inputs).
export function toDateKey(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, "0");
  const day = String(d.getDate()).padStart(2, "0");
  return `${y}-${m}-${day}`;
}

// Local HH:MM for a Date (for time inputs).
export function toTimeInput(d) {
  const h = String(d.getHours()).padStart(2, "0");
  const min = String(d.getMinutes()).padStart(2, "0");
  return `${h}:${min}`;
}

// Combine a local date string + time string into a UTC ISO string for the API.
export function localToIso(dateStr, timeStr) {
  const local = new Date(`${dateStr}T${timeStr || "00:00"}`);
  return local.toISOString();
}

// Format a time range for display, honouring the all-day flag.
export function formatEventTime(ev) {
  if (ev.allDay) return "All day";
  const start = new Date(ev.startsAt);
  const end = new Date(ev.endsAt);
  const fmt = (d) =>
    d.toLocaleTimeString(undefined, { hour: "numeric", minute: "2-digit" });
  const sameDay = toDateKey(start) === toDateKey(end);
  if (sameDay && start.getTime() === end.getTime()) return fmt(start);
  return sameDay ? `${fmt(start)} – ${fmt(end)}` : `${fmt(start)} →`;
}

// Build the 6-week grid (42 cells) for the month containing `viewDate`,
// starting on Sunday.
export function monthGrid(viewDate) {
  const first = new Date(viewDate.getFullYear(), viewDate.getMonth(), 1);
  const start = new Date(first);
  start.setDate(first.getDate() - first.getDay()); // back up to Sunday
  const cells = [];
  for (let i = 0; i < 42; i++) {
    const d = new Date(start);
    d.setDate(start.getDate() + i);
    cells.push(d);
  }
  return cells;
}

// Does an event overlap the given local calendar day?
export function eventOnDay(ev, day) {
  const dayStart = new Date(day.getFullYear(), day.getMonth(), day.getDate());
  const dayEnd = new Date(day.getFullYear(), day.getMonth(), day.getDate(), 23, 59, 59, 999);
  const evStart = new Date(ev.startsAt);
  const evEnd = new Date(ev.endsAt);
  return evStart <= dayEnd && evEnd >= dayStart;
}
