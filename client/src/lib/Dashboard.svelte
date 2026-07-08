<script>
  import { createEventDispatcher, onMount } from "svelte";
  import { api } from "./api.js";
  import Modal from "./Modal.svelte";
  import ProjectForm from "./ProjectForm.svelte";
  import UpdateForm from "./UpdateForm.svelte";
  import ProjectRow from "./ProjectRow.svelte";

  const dispatch = createEventDispatcher();

  let projects = [];
  let loading = true;
  let error = "";
  let expanded = new Set();

  let creating = false;
  let editing = null; // project
  let addingUpdate = null; // project

  async function load() {
    error = "";
    try {
      projects = await api.listProjects();
    } catch (e) {
      if (e.status === 401) {
        dispatch("unauthorized");
        return;
      }
      error = e.message || "Failed to load.";
    } finally {
      loading = false;
    }
  }

  onMount(load);

  function toggle(id) {
    const next = new Set(expanded);
    next.has(id) ? next.delete(id) : next.add(id);
    expanded = next;
  }

  async function createProject(payload) {
    await api.createProject(payload);
    creating = false;
    await load();
  }

  async function saveProject(payload) {
    await api.updateProject(editing.id, payload);
    editing = null;
    await load();
  }

  async function deleteProject(project) {
    if (!confirm(`Delete "${project.name}" and all its updates? This cannot be undone.`)) return;
    await api.deleteProject(project.id);
    await load();
  }

  async function addUpdate(payload) {
    const id = addingUpdate.id;
    await api.addUpdate(id, payload);
    const next = new Set(expanded);
    next.add(id);
    expanded = next;
    addingUpdate = null;
    await load();
  }

  async function deleteUpdate(updateId) {
    if (!confirm("Delete this update?")) return;
    await api.deleteUpdate(updateId);
    await load();
  }

  async function logout() {
    try {
      await api.logout();
    } finally {
      dispatch("unauthorized");
    }
  }
</script>

<div class="page">
  <div class="topbar">
    <div class="brand">
      <h1>Anticode</h1>
      <span class="sub">project assessment</span>
    </div>
    <div class="topbar-actions">
      <button class="btn primary" on:click={() => (creating = true)}>
        <svg width="14" height="14" viewBox="0 0 16 16" fill="none">
          <path d="M8 3v10M3 8h10" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
        </svg>
        New project
      </button>
      <button class="btn ghost" on:click={logout}>Sign out</button>
    </div>
  </div>

  {#if loading}
    <div class="state">Loading…</div>
  {:else if error}
    <div class="state error">{error}</div>
  {:else if projects.length === 0}
    <div class="state">No projects yet. Create your first one to start tracking.</div>
  {:else}
    <div class="projects">
      {#each projects as p (p.id)}
        <ProjectRow
          project={p}
          open={expanded.has(p.id)}
          on:toggle={() => toggle(p.id)}
          on:edit={() => (editing = p)}
          on:delete={() => deleteProject(p)}
          on:addUpdate={() => (addingUpdate = p)}
          on:deleteUpdate={(e) => deleteUpdate(e.detail)}
        />
      {/each}
    </div>
  {/if}
</div>

{#if creating}
  <Modal title="New project" on:close={() => (creating = false)}>
    <ProjectForm onSubmit={createProject} onCancel={() => (creating = false)} />
  </Modal>
{/if}

{#if editing}
  <Modal title="Edit project" on:close={() => (editing = null)}>
    <ProjectForm project={editing} onSubmit={saveProject} onCancel={() => (editing = null)} />
  </Modal>
{/if}

{#if addingUpdate}
  <Modal title={`Add update — ${addingUpdate.name}`} on:close={() => (addingUpdate = null)}>
    <UpdateForm project={addingUpdate} onSubmit={addUpdate} onCancel={() => (addingUpdate = null)} />
  </Modal>
{/if}
