<script>
  import { createEventDispatcher } from "svelte";

  export let project;
  export let open = false;

  const dispatch = createEventDispatcher();

  function fmtNum(n) {
    const v = Number(n) || 0;
    return Number.isInteger(v) ? String(v) : v.toFixed(1);
  }

  function fmtDate(iso) {
    try {
      return new Date(iso).toLocaleString(undefined, {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch {
      return iso;
    }
  }

  $: pct = Math.min(100, Math.max(0, Number(project.percentComplete) || 0));
  $: updates = project.updates ?? [];
</script>

<div class="project">
  <div class="project-head">
    <button
      class="disclosure {open ? 'open' : ''}"
      on:click={() => dispatch("toggle")}
      aria-label={open ? "Collapse" : "Expand"}
      aria-expanded={open}
    >
      <svg width="16" height="16" viewBox="0 0 16 16" fill="none">
        <path d="M6 4l4 4-4 4" stroke="currentColor" stroke-width="1.8"
          stroke-linecap="round" stroke-linejoin="round" />
      </svg>
    </button>

    <div class="project-title">
      <div class="name">
        {project.name}
        {#if project.firstPassCompletion}
          <span class="pill done">1st pass</span>
        {:else}
          <span class="pill pending">in progress</span>
        {/if}
        {#if project.bugs > 0}
          <span class="pill bugs">{project.bugs} bugs</span>
        {/if}
      </div>
      {#if project.description}
        <div class="desc">{project.description}</div>
      {/if}
    </div>

    <div class="project-metrics">
      <div class="metric">
        <span class="label">Eng h</span>
        <span class="value">{fmtNum(project.estimatedEngineerHours)}</span>
      </div>
      <div class="metric">
        <span class="label">Agent h</span>
        <span class="value">{fmtNum(project.estimatedAgentHours)}</span>
      </div>
      <div class="metric">
        <span class="label">{fmtNum(pct)}% done</span>
        <span class="progress"><span style="width:{pct}%"></span></span>
      </div>
    </div>
  </div>

  {#if open}
    <div class="project-body">
      <div class="updates-head">
        <h3>Updates ({updates.length})</h3>
        <div style="display:flex; gap:8px; flex-wrap:wrap">
          <button class="btn small" on:click={() => dispatch("addUpdate")}>
            <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
              <path d="M8 3v10M3 8h10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
            </svg>
            Add update
          </button>
          <button class="btn small ghost" on:click={() => dispatch("edit")}>Edit</button>
          <button class="btn small danger" on:click={() => dispatch("delete")}>Delete</button>
        </div>
      </div>

      {#if updates.length === 0}
        <div class="empty">No updates yet. Add one to log progress over time.</div>
      {:else}
        {#each updates as u (u.id)}
          <div class="update">
            <div class="update-top">
              <span class="update-date">{fmtDate(u.createdAt)}</span>
              <button class="btn danger small" on:click={() => dispatch("deleteUpdate", u.id)}>
                Remove
              </button>
            </div>
            <div class="update-grid">
              <div class="kv"><div class="k">% complete</div><div class="v">{fmtNum(u.percentComplete)}%</div></div>
              <div class="kv"><div class="k">Eng hours</div><div class="v">{fmtNum(u.estimatedEngHours)}</div></div>
              <div class="kv"><div class="k">Agent hours</div><div class="v">{fmtNum(u.estimatedAgentHours)}</div></div>
              <div class="kv"><div class="k">Time to done</div><div class="v">{u.estimatedTimeToCompletion || "—"}</div></div>
              <div class="kv"><div class="k">Bugs found</div><div class="v">{fmtNum(u.bugsFound)}</div></div>
              <div class="kv"><div class="k">Bugs fixed</div><div class="v">{fmtNum(u.bugsFixed)}</div></div>
            </div>
            {#if u.notes}<div class="update-notes">{u.notes}</div>{/if}
          </div>
        {/each}
      {/if}
    </div>
  {/if}
</div>
