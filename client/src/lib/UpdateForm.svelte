<script>
  // Pass the parent project so we can prefill from its current figures.
  export let project;
  // async (payload) => void ; may throw to surface an error.
  export let onSubmit;
  export let onCancel;

  let percentComplete = project?.percentComplete ?? "";
  let estimatedEngHours = project?.estimatedEngineerHours ?? "";
  let estimatedAgentHours = project?.estimatedAgentHours ?? "";
  let estimatedTimeToCompletion = "";
  let notes = "";
  let bugsFound = "";
  let bugsFixed = "";

  let error = "";
  let saving = false;

  function num(v) {
    if (v === "" || v === null || v === undefined) return 0;
    const n = Number(v);
    return Number.isFinite(n) ? n : 0;
  }

  async function submit() {
    error = "";
    saving = true;
    try {
      await onSubmit({
        percentComplete: num(percentComplete),
        estimatedEngHours: num(estimatedEngHours),
        estimatedAgentHours: num(estimatedAgentHours),
        estimatedTimeToCompletion,
        notes,
        bugsFound: Math.trunc(num(bugsFound)),
        bugsFixed: Math.trunc(num(bugsFixed)),
      });
    } catch (e) {
      error = e.message || "Something went wrong.";
      saving = false;
    }
  }
</script>

<form on:submit|preventDefault={submit}>
  <div class="field-row">
    <div class="field">
      <label for="u-pct">Percent complete</label>
      <!-- svelte-ignore a11y-autofocus -->
      <input id="u-pct" type="number" step="any" min="0" max="100" bind:value={percentComplete} autofocus />
    </div>
    <div class="field">
      <label for="u-ttc">Est. time to completion</label>
      <input id="u-ttc" type="text" bind:value={estimatedTimeToCompletion} placeholder="e.g. 2 weeks, 40h" />
    </div>
  </div>

  <div class="field-row">
    <div class="field">
      <label for="u-eng">Estimated eng hours</label>
      <input id="u-eng" type="number" step="any" min="0" bind:value={estimatedEngHours} />
    </div>
    <div class="field">
      <label for="u-agent">Estimated agent hours</label>
      <input id="u-agent" type="number" step="any" min="0" bind:value={estimatedAgentHours} />
    </div>
  </div>

  <div class="field-row">
    <div class="field">
      <label for="u-bf">Bugs found</label>
      <input id="u-bf" type="number" step="1" min="0" bind:value={bugsFound} />
    </div>
    <div class="field">
      <label for="u-bx">Bugs fixed</label>
      <input id="u-bx" type="number" step="1" min="0" bind:value={bugsFixed} />
    </div>
  </div>

  <div class="field">
    <label for="u-notes">Notes</label>
    <textarea id="u-notes" bind:value={notes} placeholder="What changed since the last update?"></textarea>
  </div>

  {#if error}<p class="error">{error}</p>{/if}

  <div class="modal-actions">
    <button type="button" class="btn ghost" on:click={onCancel}>Cancel</button>
    <button type="submit" class="btn primary" disabled={saving}>
      {saving ? "Saving…" : "Add update"}
    </button>
  </div>
</form>
