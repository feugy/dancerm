<script lang="ts">
	import { saveDancer } from '$lib/dancers.remote'
	import type { Address, Dancer } from '$lib/server/models'
	import { dateToDateInput } from '$lib/utils/forms'
	import { isNew } from '$lib/utils/models'
	import type { OnChangeProps } from '$lib/utils/types'
	import AddressFields from './address-fields.svelte'
	import DancerFields from './dancer-fields.svelte'

	const {
		value,
		onChange,
		onDelete,
		onRemoveAddress,
		mainAddressId
	}: {
		value?: Dancer
		mainAddressId?: Address['id']
		onChange?: (props: OnChangeProps<Dancer>) => void
		onDelete?: (args: { value: Dancer }) => void
		onRemoveAddress?: (args: { value: Dancer }) => void
	} = $props()

	let formNode: HTMLFormElement | null = null
	const form = $derived(value ? saveDancer.for(value.id) : undefined)

	$effect(() => {
		if (!value || !form) return

		form.fields.set({
			...value,
			title: value.title ?? 'Mlle',
			firstname: value.firstname ?? '',
			lastname: value.lastname ?? '',
			cellphone: value.cellphone ?? '',
			email: value.email ?? '',
			birth: dateToDateInput(value.birth),
			address: value.address
				? {
						...value.address,
						street: value.address.street ?? '',
						zipcode: value.address.zipcode ?? 0,
						city: value.address.city ?? '',
						phone: value.address.phone ?? ''
					}
				: undefined
		})
	})

	let isDancerChanged = $state(false)
	let isAddressChanged = $state(false)
	const hasOwnAddress = $derived(
		Boolean(value?.address) &&
			(value?.address?.id !== mainAddressId ||
				value?.address?.id !== form?.fields.address.id.value())
	)

	$effect(() => {
		if (!value) return
		const modified = isDancerChanged || isAddressChanged
		onChange?.({
			value,
			modified,
			saving: (form?.pending ?? 0) > 0,
			save: modified ? () => formNode?.requestSubmit() : () => void 0
		})
	})

	function addAddress() {
		if (!form) return

		form.fields.address.set({
			id: crypto.randomUUID(),
			street: '',
			zipcode: 0,
			city: '',
			phone: ''
		})
	}

	function removeAddress() {
		if (!value) return
		onRemoveAddress?.({ value })
	}
</script>

<form
  bind:this={formNode}
  class="card bg-base-100 border border-primary"
  {...form}
>
  <div class="card-body flex-col pt-0 gap-6">
    <div class="flex gap-6">
			{#if isNew(value)} 
				<input type="hidden" name="card.id" value={value?.card.id} />
				<input type="hidden" name="address.id" value={mainAddressId} />
			{/if}
      <DancerFields
        {value}
				{hasOwnAddress}
        onChange={({ modified }) => {
          isDancerChanged = modified;
        }}
				{onDelete}
				onAddAddress={addAddress}
      />
      {#if value?.address && hasOwnAddress}
        <AddressFields
          value={value.address}
          dancerId={value.id}
					canDelete={Boolean(mainAddressId) && mainAddressId !== value.address.id}
          onChange={({ modified }) => {
            isAddressChanged = modified;
          }}
					onDelete={removeAddress}
        />
      {/if}
    </div>
  </div>

  {#each form?.fields.allIssues() as issue}
    <p>{issue.message}</p>
  {/each}
</form>
