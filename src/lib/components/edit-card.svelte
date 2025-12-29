<script lang="ts">
	import { saveCard } from '$lib/cards.remote'
	import KnownBy from '$lib/components/known-by.svelte'
	import type { Card } from '$lib/server/models'
	import type { OnChangeProps } from '$lib/utils/types'

	const {
		value,
		onChange
	}: {
		value?: Card
		onChange?: (props: OnChangeProps<Card>) => void
	} = $props()

	let formNode: HTMLFormElement | null = null
	const form = $derived(value ? saveCard.for(value.id) : undefined)
	let isKnownByChanged = $state(false)

	$effect(() => {
		if (!value || !form) return

		form.fields.set({
			...value,
			knownBy: value.knownBy ?? []
		})
	})

	$effect(() => {
		if (!value) return
		onChange?.({
			value,
			modified: isKnownByChanged,
			saving: (form?.pending ?? 0) > 0,
			save: isKnownByChanged ? () => formNode?.requestSubmit() : () => void 0
		})
	})
</script>

<form
  bind:this={formNode}
  class="card bg-base-100 border border-primary"
  {...form}
>
  <KnownBy
    {value}
    onChange={({ modified }) => {
      isKnownByChanged = modified;
    }}
  />

  {#each form?.fields.allIssues() as issue}
    <p>{issue.message}</p>
  {/each}
</form>
