<script>
  // When editing, pass the existing project; otherwise it's a create form.
  export let project = null;
  // async (payload) => void ; may throw to surface an error.
  export let onSubmit;
  export let onCancel;

  const isEdit = !!project;

  let name = project?.name ?? "";
  let description = project?.description ?? "";
  let firstPassCompletion = project?.firstPassCompletion ?? false;
  let estimatedEngineerHours = project?.estimatedEngineerHours ?? "";
  let estimatedAgentHours = project?.estimatedAgentHours ?? "";
  let percentComplete = project?.percentComplete ?? "";
  let bugs = project?.bugs ?? "";

  let error = "";
  let saving = false;

  function num(v) {
    if (v === "" || v === null || v === undefined) return 0;
    const n = Number(v);
    return Number.isFinite(n) ? n : 0;
  }

  async function submit() {
    if (!name.trim()) {
      error = "Project name is required.";
      return;
    }
    error = "";
    saving = true;
    try {
      await onSubmit({
        name: name.trim(),
        description,
        firstPassCompletion,
        estimatedEngineerHours: num(estimatedEngineerHours),
        estimatedAgentHours: num(estimatedAgentHours),
        percentComplete: num(percentComplete),
        bugs: Math.trunc(num(bugs)),
      });
    } catch (e) {
      error = e.message || "Something went wrong.";
      saving = false;
    }
  }
</script>

<form on:submit|preventDefault={submit}>
  <div class="field">
    <label for="p-name">Project name</label>
    <!-- svelte-ignore a11y-autofocus -->
    <input id="p-name" type="text" bind:value={name} autofocus placeholder="e.g. Anticode API" />
  </div>

  <div class="field">
    <label for="p-desc">Description</label>
    <textarea id="p-desc" bind:value={description} placeholder="What is this project?"></textarea>
  </div>

  <div class="field-row">
    <div class="field">
      <label for="p-eng">Estimated engineer hours</label>
      <input id="p-eng" type="number" step="any" min="0" bind:value={estimatedEngineerHours} />
    </div>
    <div class="field">
      <label for="p-agent">Estimated agent hours</label>
      <input id="p-agent" type="number" step="any" min="0" bind:value={estimatedAgentHours} />
    </div>
  </div>

  <div class="field-row">
    <div class="field">
      <label for="p-pct">Percent complete</label>
      <input id="p-pct" type="number" step="any" min="0" max="100" bind:value={percentComplete} />
    </div>
    <div class="field">
      <label for="p-bugs">Open bugs</label>
      <input id="p-bugs" type="number" step="1" min="0" bind:value={bugs} />
    </div>
  </div>

  <div class="field checkbox">
    <input id="p-fpc" type="checkbox" bind:checked={firstPassCompletion} />
    <label for="p-fpc">First pass complete</label>
  </div>

  {#if error}<p class="error">{error}</p>{/if}

  <div class="modal-actions">
    <button type="button" class="btn ghost" on:click={onCancel}>Cancel</button>
    <button type="submit" class="btn primary" disabled={saving}>
      {saving ? "Saving…" : isEdit ? "Save changes" : "Create project"}
    </button>
  </div>
</form>
