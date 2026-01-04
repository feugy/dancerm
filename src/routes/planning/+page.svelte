<script lang="ts">
	import type { ChangeEventHandler } from 'svelte/elements'
	import { goto } from '$app/navigation'
	import { page } from '$app/state'
	import Planning from '$lib/components/planning.svelte'
	import { getSeasonsAndPlanning } from '$lib/planning.remote'
	import type { DanceClass } from '$lib/server/models'

	let season = $state(page.url.searchParams.get('season'))
	let { seasons, selectedSeason, planning } = $derived(await getSeasonsAndPlanning(season))

	const changeSeason: ChangeEventHandler<HTMLSelectElement> = async ({
		currentTarget: { value }
	}) => {
		if (value !== season && value) {
			season = value
			page.url.searchParams.set('season', season)
			goto(`?${page.url.searchParams.toString()}`)
		}
	}

	function selectDanceClass({ danceClass }: { danceClass: DanceClass }) {
		console.log(`click on`, danceClass)
	}
</script>
<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<select class="select select-ghost" onchange={changeSeason}>
  {#each seasons as value}
		{@const selected = value === selectedSeason}
		<option {selected}>{value}</option>
	{/each}
</select>

<Planning danceClasses={planning} class="p-6 h-[90vh]" onSelect={selectDanceClass} />