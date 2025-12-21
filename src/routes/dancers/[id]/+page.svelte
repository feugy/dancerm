<script lang="ts">
  import EditCard from "$lib/components/edit-card.svelte";
  import EditDancer from "$lib/components/edit-dancer.svelte";
  import { getDancer, getRelatedDancers } from "$lib/dancers.remote.js";

  let { params } = $props();
</script>

<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<div class="flex flex-col p-2 gap-2">
  <div class="flex gap-2">
    {#await getDancer(params.id)}
      <EditDancer />
    {:then dancer}
      <EditDancer value={dancer} />
      {#each await getRelatedDancers(dancer.card.id) as related}
        {#if related.id !== dancer.id}
          <EditDancer value={related} mainAddressId={dancer.address?.id} />
        {/if}
      {/each}
    {/await}
  </div>
  {#await getDancer(params.id)}
    <EditCard />
  {:then dancer}
    <EditCard value={dancer.card} />
  {/await}
</div>
