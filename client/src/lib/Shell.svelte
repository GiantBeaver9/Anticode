<script>
  import { createEventDispatcher } from "svelte";
  import { api } from "./api.js";
  import ProjectsView from "./ProjectsView.svelte";
  import CalendarView from "./CalendarView.svelte";

  const dispatch = createEventDispatcher();

  // Which intranet section is showing. Persisted so a refresh stays put.
  let view = localStorage.getItem("anticode:view") || "calendar";
  $: localStorage.setItem("anticode:view", view);

  // The local-LLM chat lives in its own app (LocalLLM). Point the Chat tab at
  // it via VITE_CHAT_URL; falls back to the Create-React-App default port.
  const chatUrl = import.meta.env.VITE_CHAT_URL || "http://localhost:3000";

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
      <span class="sub">home intranet</span>
    </div>

    <nav class="nav">
      <button class="nav-tab" class:active={view === "calendar"} on:click={() => (view = "calendar")}>
        Calendar
      </button>
      <button class="nav-tab" class:active={view === "projects"} on:click={() => (view = "projects")}>
        Projects
      </button>
      <a class="nav-tab" href={chatUrl} target="_blank" rel="noopener noreferrer">
        Chat ↗
      </a>
    </nav>

    <div class="topbar-actions">
      <button class="btn ghost" on:click={logout}>Sign out</button>
    </div>
  </div>

  {#if view === "calendar"}
    <CalendarView on:unauthorized={() => dispatch("unauthorized")} />
  {:else}
    <ProjectsView on:unauthorized={() => dispatch("unauthorized")} />
  {/if}
</div>

<style>
  .nav {
    display: flex;
    gap: 2px;
    background: var(--bg-elev);
    border: 1px solid var(--border);
    border-radius: 10px;
    padding: 3px;
  }
  .nav-tab {
    background: transparent;
    border: none;
    color: var(--text-dim);
    padding: 7px 14px;
    border-radius: 7px;
    font-size: 14px;
    text-decoration: none;
    display: inline-flex;
    align-items: center;
    transition: background 0.12s, color 0.12s;
  }
  .nav-tab:hover {
    color: var(--text);
    background: var(--bg-elev-2);
  }
  .nav-tab.active {
    background: var(--accent);
    color: #04122b;
    font-weight: 600;
  }
</style>
