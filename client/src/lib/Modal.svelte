<script>
  import { createEventDispatcher, onMount, onDestroy } from "svelte";

  export let title = "";

  const dispatch = createEventDispatcher();
  const close = () => dispatch("close");

  function onKey(e) {
    if (e.key === "Escape") close();
  }

  onMount(() => document.addEventListener("keydown", onKey));
  onDestroy(() => document.removeEventListener("keydown", onKey));
</script>

<div
  class="overlay"
  on:mousedown={close}
  role="presentation"
>
  <div class="modal" on:mousedown|stopPropagation role="dialog" aria-modal="true">
    <h2>{title}</h2>
    <slot />
  </div>
</div>
