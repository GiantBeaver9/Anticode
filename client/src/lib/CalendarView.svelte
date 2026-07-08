<script>
  import { createEventDispatcher, onMount } from "svelte";
  import { api } from "./api.js";
  import Modal from "./Modal.svelte";
  import EventForm from "./EventForm.svelte";
  import {
    MONTHS,
    WEEKDAYS,
    toDateKey,
    monthGrid,
    eventOnDay,
    formatEventTime,
  } from "./dates.js";

  const dispatch = createEventDispatcher();

  let viewDate = new Date();
  let events = [];
  let loading = true;
  let error = "";

  let creating = false; // holds a defaultDate string when creating
  let editing = null; // event being edited
  let viewing = null; // event being previewed

  const todayKey = toDateKey(new Date());

  $: grid = monthGrid(viewDate);
  $: monthLabel = `${MONTHS[viewDate.getMonth()]} ${viewDate.getFullYear()}`;

  async function load() {
    loading = true;
    error = "";
    try {
      const cells = monthGrid(viewDate);
      const from = cells[0].toISOString();
      const last = new Date(cells[cells.length - 1]);
      last.setHours(23, 59, 59, 999);
      events = await api.listEvents(from, last.toISOString());
    } catch (e) {
      if (e.status === 401) {
        dispatch("unauthorized");
        return;
      }
      error = e.message || "Failed to load events.";
    } finally {
      loading = false;
    }
  }

  onMount(load);

  function eventsForDay(day) {
    return events
      .filter((ev) => eventOnDay(ev, day))
      .sort((a, b) => {
        if (a.allDay !== b.allDay) return a.allDay ? -1 : 1;
        return new Date(a.startsAt) - new Date(b.startsAt);
      });
  }

  function prevMonth() {
    viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() - 1, 1);
    load();
  }
  function nextMonth() {
    viewDate = new Date(viewDate.getFullYear(), viewDate.getMonth() + 1, 1);
    load();
  }
  function goToday() {
    viewDate = new Date();
    load();
  }

  async function createEvent(payload) {
    await api.createEvent(payload);
    creating = false;
    await load();
  }
  async function saveEvent(payload) {
    await api.updateEvent(editing.id, payload);
    editing = null;
    await load();
  }
  async function deleteEvent(ev) {
    if (!confirm(`Delete "${ev.title}"?`)) return;
    await api.deleteEvent(ev.id);
    viewing = null;
    editing = null;
    await load();
  }
</script>

<div class="view-bar">
  <div class="cal-nav">
    <button class="btn small ghost" on:click={prevMonth} aria-label="Previous month">‹</button>
    <h2 class="view-title cal-month">{monthLabel}</h2>
    <button class="btn small ghost" on:click={nextMonth} aria-label="Next month">›</button>
    <button class="btn small" on:click={goToday}>Today</button>
  </div>
  <button class="btn primary" on:click={() => (creating = todayKey)}>
    <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
      <path d="M8 3v10M3 8h10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
    </svg>
    New event
  </button>
</div>

{#if error}
  <div class="state error">{error}</div>
{/if}

<div class="cal">
  <div class="cal-weekdays">
    {#each WEEKDAYS as wd}
      <div class="cal-weekday">{wd}</div>
    {/each}
  </div>
  <div class="cal-grid" class:dim={loading}>
    {#each grid as day (day.toISOString())}
      {@const key = toDateKey(day)}
      {@const inMonth = day.getMonth() === viewDate.getMonth()}
      {@const dayEvents = eventsForDay(day)}
      <div
        class="cal-cell"
        class:out={!inMonth}
        class:today={key === todayKey}
        on:click={() => (creating = key)}
        on:keydown={(e) => (e.key === "Enter" ? (creating = key) : null)}
        role="button"
        tabindex="0"
      >
        <div class="cal-daynum">{day.getDate()}</div>
        <div class="cal-events">
          {#each dayEvents.slice(0, 4) as ev (ev.id)}
            <button
              class="cal-chip"
              class:allday={ev.allDay}
              style={`--c:${ev.color}`}
              on:click|stopPropagation={() => (viewing = ev)}
            >
              {#if !ev.allDay}
                <span class="chip-time">{formatEventTime(ev)}</span>
              {/if}
              <span class="chip-title">{ev.title}</span>
            </button>
          {/each}
          {#if dayEvents.length > 4}
            <span class="cal-more">+{dayEvents.length - 4} more</span>
          {/if}
        </div>
      </div>
    {/each}
  </div>
</div>

{#if creating}
  <Modal title="New event" on:close={() => (creating = false)}>
    <EventForm
      defaultDate={typeof creating === "string" ? creating : null}
      onSubmit={createEvent}
      onCancel={() => (creating = false)}
    />
  </Modal>
{/if}

{#if editing}
  <Modal title="Edit event" on:close={() => (editing = null)}>
    <EventForm event={editing} onSubmit={saveEvent} onCancel={() => (editing = null)} />
  </Modal>
{/if}

{#if viewing}
  <Modal title={viewing.title} on:close={() => (viewing = null)}>
    <div class="ev-detail">
      <div class="ev-row">
        <span class="ev-dot" style={`background:${viewing.color}`}></span>
        <span>{formatEventTime(viewing)}</span>
      </div>
      <div class="ev-when">
        {new Date(viewing.startsAt).toLocaleDateString(undefined, {
          weekday: "long", month: "long", day: "numeric", year: "numeric",
        })}
      </div>
      {#if viewing.location}
        <div class="ev-meta"><span class="ev-k">Where</span> {viewing.location}</div>
      {/if}
      {#if viewing.attendees}
        <div class="ev-meta"><span class="ev-k">Who</span> {viewing.attendees}</div>
      {/if}
      {#if viewing.notes}
        <div class="ev-notes">{viewing.notes}</div>
      {/if}
    </div>
    <div class="modal-actions">
      <button class="btn danger" on:click={() => deleteEvent(viewing)}>Delete</button>
      <button class="btn" on:click={() => { editing = viewing; viewing = null; }}>Edit</button>
    </div>
  </Modal>
{/if}

<style>
  .cal-nav {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .cal-month {
    min-width: 190px;
  }
  .cal {
    background: var(--bg-elev);
    border: 1px solid var(--border);
    border-radius: var(--radius);
    overflow: hidden;
    box-shadow: var(--shadow);
  }
  .cal-weekdays,
  .cal-grid {
    display: grid;
    grid-template-columns: repeat(7, 1fr);
  }
  .cal-weekday {
    padding: 8px 10px;
    font-size: 11px;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    color: var(--text-faint);
    border-bottom: 1px solid var(--border);
    text-align: left;
  }
  .cal-grid.dim {
    opacity: 0.5;
    transition: opacity 0.1s;
  }
  .cal-cell {
    min-height: 108px;
    border-right: 1px solid var(--border);
    border-bottom: 1px solid var(--border);
    padding: 6px;
    display: flex;
    flex-direction: column;
    gap: 4px;
    cursor: pointer;
    transition: background 0.1s;
  }
  .cal-cell:hover {
    background: var(--bg-elev-2);
  }
  .cal-cell:nth-child(7n) {
    border-right: none;
  }
  .cal-cell.out {
    background: rgba(0, 0, 0, 0.18);
  }
  .cal-cell.out .cal-daynum {
    color: var(--text-faint);
  }
  .cal-daynum {
    font-size: 12px;
    font-variant-numeric: tabular-nums;
    color: var(--text-dim);
    align-self: flex-start;
    width: 22px;
    height: 22px;
    display: flex;
    align-items: center;
    justify-content: center;
    border-radius: 50%;
  }
  .cal-cell.today .cal-daynum {
    background: var(--accent);
    color: #04122b;
    font-weight: 700;
  }
  .cal-events {
    display: flex;
    flex-direction: column;
    gap: 3px;
    min-width: 0;
  }
  .cal-chip {
    display: flex;
    align-items: baseline;
    gap: 5px;
    text-align: left;
    border: none;
    background: color-mix(in srgb, var(--c) 20%, transparent);
    border-left: 3px solid var(--c);
    color: var(--text);
    border-radius: 4px;
    padding: 2px 6px;
    font-size: 12px;
    line-height: 1.35;
    overflow: hidden;
    white-space: nowrap;
    text-overflow: ellipsis;
  }
  .cal-chip:hover {
    background: color-mix(in srgb, var(--c) 32%, transparent);
  }
  .cal-chip .chip-time {
    color: var(--text-dim);
    font-variant-numeric: tabular-nums;
    flex-shrink: 0;
  }
  .cal-chip .chip-title {
    overflow: hidden;
    text-overflow: ellipsis;
  }
  .cal-more {
    font-size: 11px;
    color: var(--text-faint);
    padding-left: 4px;
  }

  /* event detail */
  .ev-detail {
    display: flex;
    flex-direction: column;
    gap: 8px;
    margin-bottom: 16px;
  }
  .ev-row {
    display: flex;
    align-items: center;
    gap: 8px;
  }
  .ev-dot {
    width: 12px;
    height: 12px;
    border-radius: 50%;
    display: inline-block;
  }
  .ev-when {
    color: var(--text-dim);
  }
  .ev-meta {
    font-size: 14px;
  }
  .ev-k {
    color: var(--text-faint);
    text-transform: uppercase;
    font-size: 11px;
    letter-spacing: 0.04em;
    margin-right: 8px;
  }
  .ev-notes {
    margin-top: 4px;
    color: var(--text-dim);
    white-space: pre-wrap;
    border-top: 1px solid var(--border);
    padding-top: 10px;
  }

  @media (max-width: 640px) {
    .cal-cell {
      min-height: 76px;
    }
    .cal-chip .chip-time {
      display: none;
    }
  }
</style>
