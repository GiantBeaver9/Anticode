<script>
  import { onMount } from "svelte";
  import { api } from "./lib/api.js";
  import Login from "./lib/Login.svelte";
  import Dashboard from "./lib/Dashboard.svelte";

  let ready = false;
  let authed = false;

  async function check() {
    try {
      const me = await api.me();
      authed = !!me?.authenticated;
    } catch {
      authed = false;
    } finally {
      ready = true;
    }
  }

  onMount(check);
</script>

{#if !ready}
  <div class="page"><div class="state">Loading…</div></div>
{:else if authed}
  <Dashboard on:unauthorized={() => (authed = false)} />
{:else}
  <Login on:authenticated={() => (authed = true)} />
{/if}
