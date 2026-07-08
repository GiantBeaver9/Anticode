<script>
  import { createEventDispatcher } from "svelte";
  import { api } from "./api.js";

  const dispatch = createEventDispatcher();

  let password = "";
  let error = "";
  let loading = false;

  async function submit() {
    error = "";
    loading = true;
    try {
      await api.login(password);
      dispatch("authenticated");
    } catch (e) {
      error = e.message || "Login failed.";
    } finally {
      loading = false;
    }
  }
</script>

<div class="login-wrap">
  <form class="login-card" on:submit|preventDefault={submit}>
    <h1>Anticode</h1>
    <p>Project assessment tracker</p>

    <div class="field">
      <label for="pw">Password</label>
      <!-- svelte-ignore a11y-autofocus -->
      <input
        id="pw"
        type="password"
        bind:value={password}
        autofocus
        placeholder="Enter password"
      />
    </div>

    {#if error}<p class="error">{error}</p>{/if}

    <div class="modal-actions" style="margin-top:16px">
      <button class="btn primary" type="submit" disabled={loading}>
        {loading ? "Signing in…" : "Sign in"}
      </button>
    </div>
  </form>
</div>
