<script lang="ts">
  import { saveCard } from "$lib/cards.remote";
  import SaveIcon from "$lib/components/icons/save.svelte";
  import KnownBy from "$lib/components/known-by.svelte";
  import type { Card } from "$lib/server/models";

  let { value }: { value?: Card } = $props();

  const save = $derived(value ? saveCard.for(value.id) : undefined);

  $effect(() => {
    if (!value || !save) return;

    save.fields.set({
      ...value,
      knownBy: value.knownBy ?? [],
    });
  });

  const isModified = $derived(
    save?.fields.knownBy.value()?.toSorted().join() !==
      value?.knownBy?.toSorted().join()
  );
</script>

<form class="card bg-base-100 border border-primary" {...save}>
  <KnownBy cardId={value?.id} />

  {#each save?.fields.allIssues() as issue}
    <p>{issue.message}</p>
  {/each}
  <button
    disabled={!isModified || !save || save.pending > 0}
    class="btn btn-primary m-2"
  >
    {#if save?.pending}<span class="loading loading-spinner size-5"></span>
    {:else}<SaveIcon class="size-5" />{/if}Save</button
  >
</form>
