<script lang="ts">
  import type { PageData } from "./$types";

  let { data }: { data: PageData } = $props();
</script>

<div class="p-4">Liste des danseurs ({data.dancers.total})</div>
<ul>
  {#each data.dancers.results as dancer (dancer.id)}
    <li class="p-4 border-b">
      <a href="/dancers/{dancer.id}" class="inline-block">
        <span class="text-lg font-bold"
          >{dancer.firstname} {dancer.lastname}</span
        >
        <span class="text-sm text-gray-600">ID: {dancer.id}</span>
      </a>
    </li>
  {/each}
</ul>
