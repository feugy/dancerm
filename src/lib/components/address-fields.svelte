<script lang="ts">
	import ConfirmableButton from '$lib/components/confirmable-button.svelte'
	import SaveIcon from '$lib/components/icons/pencil.svelte'
	import RemoveIcon from '$lib/components/icons/trash.svelte'
	import { saveDancer } from '$lib/dancers.remote'
	import type { Address, Dancer } from '$lib/server/models'

	const {
		value,
		onChange,
		onDelete,
		canDelete = false,
		dancerId
	}: {
		value?: Address
		dancerId: Dancer['id']
		canDelete?: boolean
		onChange?: (args: { value: Address; modified: boolean }) => void
		onDelete?: (args: { value: Address }) => void
	} = $props()

	const form = $derived(saveDancer.for(dancerId))

	const modified = $derived(
		form?.fields.address?.id.value() !== (value?.id ?? '') ||
			form?.fields.address?.street.value() !== (value?.street ?? '') ||
			form?.fields.address?.zipcode.value() !== (value?.zipcode ?? 0) ||
			form?.fields.address?.city.value() !== (value?.city ?? '') ||
			form?.fields.address?.phone.value() !== (value?.phone ?? '')
	)

	$effect(() => {
		if (!value) return
		onChange?.({ value, modified })
	})

	function remove(event: Event) {
		event.preventDefault()
		if (value) {
			onDelete?.({ value })
		}
	}
</script>

<span class="flex flex-col gap-6 flex-1">
  <h1 class="card-title mt-4 h-8">
    <span class="flex-1">Adresse {#if modified}<SaveIcon class="size-4 inline-block" />{/if}</span>
      {#if value && canDelete}<ConfirmableButton
        class="btn-square btn-ghost btn-sm hover:btn-error"
        onclick={remove}
        title="Supprimer l'adresse"
  >
    <RemoveIcon class="size-4" />
    {#snippet heading ()}
      Êtes-vous sûr de vouloir supprimer cette adresse ?
    {/snippet}
    {#snippet content ()}
      Cette action est irréversible. L'adresse sera remplacée par l'adresse du premier danseur.
    {/snippet}
    {#snippet confirmAction ()}Supprimer{/snippet}
    {#snippet cancelAction ()}Annuler{/snippet}
  </ConfirmableButton>
  {/if}
  </h1>
  <input type="hidden" name="address.id" value={form.fields.address.id.value()} />
  <label class="floating-label">
    <span>Voie</span>
    <input
      class="input w-full capitalize"
      {...form.fields.address.street.as("text")}
    />
  </label>
  <span class="flex gap-6"
    ><label class="floating-label w-24">
      <span>Code postal</span>
      <input
        class="input w-full capitalize"
        {...form.fields.address.zipcode.as("number")}
      />
    </label>
    <label class="floating-label flex-1">
      <span>Ville</span>
      <input class="input w-full" {...form.fields.address.city.as("text")} />
    </label></span
  >
  <label class="floating-label">
    <span>Téléphone</span>
    <input class="input w-full" {...form.fields.address.phone.as("text")} />
  </label>
</span>
