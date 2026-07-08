<script>
  import { toDateKey, toTimeInput, localToIso } from "./dates.js";

  // When editing, pass the existing event; otherwise it's a create form.
  export let event = null;
  // Optional default date (YYYY-MM-DD) when creating from a clicked day cell.
  export let defaultDate = null;
  // async (payload) => void ; may throw to surface an error.
  export let onSubmit;
  export let onCancel;

  const isEdit = !!event;

  const PALETTE = [
    { name: "Blue", value: "#5b9dff" },
    { name: "Green", value: "#3ecf8e" },
    { name: "Amber", value: "#f5a623" },
    { name: "Red", value: "#f6685e" },
    { name: "Purple", value: "#a884ff" },
    { name: "Teal", value: "#39c5cf" },
  ];

  const start = event ? new Date(event.startsAt) : null;
  const end = event ? new Date(event.endsAt) : null;
  const today = defaultDate ?? toDateKey(new Date());

  let title = event?.title ?? "";
  let allDay = event?.allDay ?? false;
  let startDate = start ? toDateKey(start) : today;
  let startTime = start ? toTimeInput(start) : "09:00";
  let endDate = end ? toDateKey(end) : today;
  let endTime = end ? toTimeInput(end) : "10:00";
  let location = event?.location ?? "";
  let attendees = event?.attendees ?? "";
  let notes = event?.notes ?? "";
  let color = event?.color ?? PALETTE[0].value;

  let error = "";
  let saving = false;

  async function submit() {
    if (!title.trim()) {
      error = "Event title is required.";
      return;
    }
    let startsAt, endsAt;
    if (allDay) {
      startsAt = localToIso(startDate, "00:00");
      endsAt = localToIso(endDate || startDate, "23:59");
    } else {
      startsAt = localToIso(startDate, startTime);
      endsAt = localToIso(endDate || startDate, endTime || startTime);
    }
    if (new Date(endsAt) < new Date(startsAt)) {
      error = "End must be after the start.";
      return;
    }
    error = "";
    saving = true;
    try {
      await onSubmit({
        title: title.trim(),
        allDay,
        startsAt,
        endsAt,
        location: location.trim(),
        attendees: attendees.trim(),
        notes,
        color,
      });
    } catch (e) {
      error = e.message || "Something went wrong.";
      saving = false;
    }
  }
</script>

<form on:submit|preventDefault={submit}>
  <div class="field">
    <label for="e-title">Title</label>
    <!-- svelte-ignore a11y-autofocus -->
    <input id="e-title" type="text" bind:value={title} autofocus placeholder="e.g. Dentist, Ava's football" />
  </div>

  <div class="field checkbox">
    <input id="e-allday" type="checkbox" bind:checked={allDay} />
    <label for="e-allday">All day</label>
  </div>

  <div class="field-row">
    <div class="field">
      <label for="e-sdate">Starts</label>
      <input id="e-sdate" type="date" bind:value={startDate} />
    </div>
    {#if !allDay}
      <div class="field">
        <label for="e-stime">Start time</label>
        <input id="e-stime" type="time" bind:value={startTime} />
      </div>
    {/if}
  </div>

  <div class="field-row">
    <div class="field">
      <label for="e-edate">Ends</label>
      <input id="e-edate" type="date" bind:value={endDate} />
    </div>
    {#if !allDay}
      <div class="field">
        <label for="e-etime">End time</label>
        <input id="e-etime" type="time" bind:value={endTime} />
      </div>
    {/if}
  </div>

  <div class="field-row">
    <div class="field">
      <label for="e-loc">Location</label>
      <input id="e-loc" type="text" bind:value={location} placeholder="Optional" />
    </div>
    <div class="field">
      <label for="e-who">Who</label>
      <input id="e-who" type="text" bind:value={attendees} placeholder="Family members, comma-separated" />
    </div>
  </div>

  <div class="field" role="group" aria-label="Colour">
    <span class="field-label">Colour</span>
    <div class="swatches">
      {#each PALETTE as p}
        <button
          type="button"
          class="swatch"
          class:selected={color === p.value}
          style={`--sw:${p.value}`}
          title={p.name}
          aria-label={p.name}
          on:click={() => (color = p.value)}
        ></button>
      {/each}
    </div>
  </div>

  <div class="field">
    <label for="e-notes">Notes</label>
    <textarea id="e-notes" bind:value={notes} placeholder="Anything to remember?"></textarea>
  </div>

  {#if error}<p class="error">{error}</p>{/if}

  <div class="modal-actions">
    <button type="button" class="btn ghost" on:click={onCancel}>Cancel</button>
    <button type="submit" class="btn primary" disabled={saving}>
      {saving ? "Saving…" : isEdit ? "Save changes" : "Create event"}
    </button>
  </div>
</form>

<style>
  .field-label {
    font-size: 12px;
    color: var(--text-dim);
    text-transform: uppercase;
    letter-spacing: 0.04em;
  }
  .swatches {
    display: flex;
    gap: 8px;
    flex-wrap: wrap;
  }
  .swatch {
    width: 26px;
    height: 26px;
    border-radius: 50%;
    background: var(--sw);
    border: 2px solid transparent;
    padding: 0;
    transition: transform 0.1s, border-color 0.1s;
  }
  .swatch:hover {
    transform: scale(1.08);
  }
  .swatch.selected {
    border-color: var(--text);
    box-shadow: 0 0 0 2px var(--bg);
  }
</style>
