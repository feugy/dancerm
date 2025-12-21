<script lang="ts">
  import { saveCard } from "$lib/cards.remote";
  import type { Card } from "$lib/server/models";

  let { cardId }: { cardId?: Card["id"] } = $props();
  const loading = $derived(cardId === undefined);
  const save = $derived(cardId ? saveCard.for(cardId) : undefined);

  const options = [
    { label: "anciens", value: "elders" },
    { label: "annuaire", value: "directory" },
    { label: "biennale asso.", value: "associationsBiennal" },
    { label: "bouche à oreille", value: "mouth" },
    { label: "groupon", value: "groupon" },
    { label: "moteur de recherche", value: "searchEngine" },
    { label: "pagesjaunes.fr", value: "pagesjaunesFr" },
    { label: "réseaux sociaux", value: "socialMedia" },
    { label: "site web", value: "website" },
    { label: "tract", value: "leaflets" },
  ];
</script>

<div class="card-body pt-0 flex flex-col gap-6 flex-1">
  <h1 class="card-title pt-4">Connu par</h1>
  <input type="hidden" name="id" value={save?.fields.id.value()} />
  <span class="flex flex-wrap gap-6">
    {#each options as { label, value } (value)}
      <label class="label">
        <input
          class="checkbox checkbox-sm"
          class:skeleton={loading}
          disabled={loading}
          {...save?.fields.knownBy.as("checkbox", value)}
        />{label}</label
      >
    {/each}
  </span>
</div>
