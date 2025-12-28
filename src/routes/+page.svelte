<script lang="ts">
	import { getDancers } from '$lib/dancers.remote'
</script>

{#await getDancers()}
  <p>Chargement...</p>
{:then dancers}
  <div class="p-4">Liste des danseurs ({dancers.total})</div>
  <ul>
    {#each dancers.results as dancer (dancer.id)}
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
{/await}
