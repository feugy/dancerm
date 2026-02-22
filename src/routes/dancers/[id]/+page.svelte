<script lang="ts">
	import { SvelteMap } from 'svelte/reactivity'
	import { goto } from '$app/navigation'
	import Button from '$lib/components/button.svelte'
	import EditCard from '$lib/components/edit-card.svelte'
	import EditDancer from '$lib/components/edit-dancer.svelte'
	import SaveIcon from '$lib/components/icons/pencil-square.svelte'
	import AddIcon from '$lib/components/icons/user-plus.svelte'
	import {
		deleteDancer,
		getDancer,
		getRelatedDancers,
		removeFromAddress
	} from '$lib/dancers.remote.js'
	import type { Card } from '$lib/server/models/card.js'
	import type { Dancer } from '$lib/server/models/dancer.js'
	import { isNew } from '$lib/utils/models.js'
	import type { OnChangeProps } from '$lib/utils/types.js'

	const { params } = $props()

	const states = new SvelteMap<string, OnChangeProps<Dancer | Card>>()

	const addedDancers = $state<Dancer[]>([])

	const dancerPromise = $derived(getDancer(params.id))

	const buttonProps = $derived.by(() => {
		const props = { disabled: true, saving: false }
		for (const [, state] of states) {
			if (state.saving) {
				props.disabled = true
				props.saving = true
			}
			if (state.modified) {
				props.disabled = false
			}
		}
		return props
	})

	function handleChange<T extends Dancer | Card>(args: OnChangeProps<T>) {
		states.set(args.value.id, args)
	}

	function triggerSaves() {
		for (const { save } of states.values()) {
			save()
		}
		addedDancers.splice(0, addedDancers.length)
	}

	async function addDancer() {
		const { card, address } = await dancerPromise
		addedDancers.push({
			id: crypto.randomUUID(),
			_v: 0,
			card,
			address,
			created: new Date(),
			title: null,
			firstname: null,
			lastname: null,
			birth: null,
			email: null,
			cellphone: null,
			danceClassIds: []
		})
	}

	async function handleDelete({ value }: { value: Dancer }) {
		await deleteDancer(value)
		if (value.id === (await dancerPromise).id) {
			goto('/')
		}
	}

	async function removeAddress({ value: dancer }: { value: Dancer }) {
		const { address, card } = await dancerPromise
		if (!isNew(dancer) && address) {
			await removeFromAddress({ dancer: { ...dancer, card }, newAddressId: address.id })
		}
		dancer.address = address
	}
</script>

<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<Button
  disabled={buttonProps.disabled}
  class="btn-primary m-2"
  onclick={triggerSaves}
	
>
  {#if buttonProps.saving}<span class="loading loading-spinner size-5"
    ></span>{:else}<SaveIcon class="size-5" />{/if}
  Save</Button>
<div class="flex flex-col p-2 gap-2">
  <div class="flex gap-2">
    {#await dancerPromise}
      <EditDancer />
    {:then dancer}
      <EditDancer value={dancer} onChange={handleChange} onDelete={handleDelete}/>
      {#each await getRelatedDancers(dancer.card.id) as related}
        {#if related.id !== dancer.id}
          <EditDancer
            value={related}
            mainAddressId={dancer.address?.id}
            onChange={handleChange}
            onDelete={handleDelete}
						onRemoveAddress={removeAddress}
          />
        {/if}
      {/each}
      {#each addedDancers as added}
        <EditDancer
          value={added}
          mainAddressId={dancer.address?.id}
          onChange={handleChange}
					onRemoveAddress={removeAddress}
        />
      {/each}
    {/await}
    <Button class="btn-primary btn-square btn-xl rounded-lg" onclick={addDancer} title="Ajouter un danseur">
      <AddIcon />
    </Button>
  </div>
  {#await dancerPromise}
    <EditCard />
  {:then dancer}
    <EditCard value={dancer.card} onChange={handleChange} />
  {/await}
</div>
