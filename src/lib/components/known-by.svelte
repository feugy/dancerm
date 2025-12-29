<script lang="ts">
	import { saveCard } from '$lib/cards.remote'
	import SaveIcon from '$lib/components/icons/pencil.svelte'
	import type { Card } from '$lib/server/models'

	const options = [
		{ label: 'anciens', value: 'elders' },
		{ label: 'annuaire', value: 'directory' },
		{ label: 'biennale asso.', value: 'associationsBiennal' },
		{ label: 'bouche à oreille', value: 'mouth' },
		{ label: 'groupon', value: 'groupon' },
		{ label: 'moteur de recherche', value: 'searchEngine' },
		{ label: 'pagesjaunes.fr', value: 'pagesjaunesFr' },
		{ label: 'réseaux sociaux', value: 'socialMedia' },
		{ label: 'site web', value: 'website' },
		{ label: 'tract', value: 'leaflets' }
	]

	const {
		value,
		onChange
	}: {
		value?: Card
		onChange?: (args: { value: Card; modified: boolean }) => void
	} = $props()
	const loading = $derived(value?.id === undefined)
	const form = $derived(value?.id ? saveCard.for(value.id) : undefined)

	const modified = $derived(
		form?.fields.knownBy.value()?.toSorted().join() !== value?.knownBy?.toSorted().join()
	)

	$effect(() => {
		if (!value) return
		onChange?.({ value, modified })
	})
</script>

<div class="card-body pt-0 flex flex-col gap-6 flex-1">
  <h1 class="card-title pt-4">
    Connu par {#if modified}<SaveIcon class="size-4" />{/if}
  </h1>
  <input type="hidden" name="id" value={form?.fields.id.value()} />
  <span class="flex flex-wrap gap-6">
    {#each options as { label, value } (value)}
      <label class="label">
        <input
          class="checkbox checkbox-sm"
          class:skeleton={loading}
          disabled={loading}
          {...form?.fields.knownBy.as("checkbox", value)}
        />{label}</label
      >
    {/each}
  </span>
</div>
