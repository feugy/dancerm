<script lang="ts">
import { SvelteMap } from 'svelte/reactivity'
import EditCard from '$lib/components/edit-card.svelte'
import EditDancer from '$lib/components/edit-dancer.svelte'
import SaveIcon from '$lib/components/icons/pencil-square.svelte'
import { getDancer, getRelatedDancers } from '$lib/dancers.remote.js'
import type { Card } from '$lib/server/models/card.js'
import type { Dancer } from '$lib/server/models/dancer.js'
import type { OnChangeProps } from '$lib/utils/types.js'

let { params } = $props()

const dancerPromise = $derived(getDancer(params.id))
let states = new SvelteMap<string, OnChangeProps<Dancer | Card>>()
let buttonProps = $derived.by(() => {
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
}
</script>

<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<button
  disabled={buttonProps.disabled}
  class="btn btn-primary m-2"
  onclick={triggerSaves}
>
  {#if buttonProps.saving}<span class="loading loading-spinner size-5"
    ></span>{:else}<SaveIcon class="size-5" />{/if}
  Save</button
>
<div class="flex flex-col p-2 gap-2">
  <div class="flex gap-2">
    {#await dancerPromise}
      <EditDancer />
    {:then dancer}
      <EditDancer value={dancer} onchange={handleChange} />
      {#each await getRelatedDancers(dancer.card.id) as related}
        {#if related.id !== dancer.id}
          <EditDancer
            value={related}
            mainAddressId={dancer.address?.id}
            onchange={handleChange}
          />
        {/if}
      {/each}
    {/await}
  </div>
  {#await dancerPromise}
    <EditCard />
  {:then dancer}
    <EditCard value={dancer.card} onchange={handleChange} />
  {/await}
</div>
