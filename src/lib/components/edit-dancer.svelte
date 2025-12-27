<script lang="ts">
import { saveDancer } from '$lib/dancers.remote'
import type { Address, Dancer } from '$lib/server/models'
import { dateToDateInput } from '$lib/utils/forms'
import type { OnChangeProps } from '$lib/utils/types'
import AddressFields from './address-fields.svelte'
import DancerFields from './dancer-fields.svelte'

const {
	value,
	onchange,
	mainAddressId
}: {
	value?: Dancer
	mainAddressId?: Address['id']
	onchange?: (props: OnChangeProps<Dancer>) => void
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

$effect(() => {
	if (!value) return
	const modified = isDancerChanged || isAddressChanged
	onchange?.({
		value,
		modified,
		saving: (form?.pending ?? 0) > 0,
		save: modified ? () => formNode?.requestSubmit() : () => void 0
	})
})
</script>

<form
  bind:this={formNode}
  class="card bg-base-100 border border-primary"
  {...form}
>
  <div class="card-body flex-col pt-0 gap-6">
    <div class="flex gap-6">
      <DancerFields
        {value}
        onchange={({ modified }) => {
          isDancerChanged = modified;
        }}
      />
      {#if value?.address && value.address.id !== mainAddressId}
        <AddressFields
          value={value.address}
          dancerId={value.id}
          onchange={({ modified }) => {
            isAddressChanged = modified;
          }}
        />
      {/if}
    </div>
  </div>

  {#each form?.fields.allIssues() as issue}
    <p>{issue.message}</p>
  {/each}
</form>
