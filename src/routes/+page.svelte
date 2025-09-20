<script lang="ts">
  import { greet } from "$lib";

  function sayHi() {
    alert(greet('Damien'));
  }
</script>
<div class="flex flex-col h-full w-full justify-center items-center gap-4 p-10">
  <h1>Welcome to SvelteKit!!</h1>
  <p>Visit <a href="https://svelte.dev/docs/kit">svelte.dev/docs/kit</a> to read the documentation</p>

  <button class="border border-amber-600 p-2 rounded" on:click={sayHi}>Click me</button>
</div>