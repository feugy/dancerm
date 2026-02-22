<script lang="ts">
	import type { ChangeEventHandler } from 'svelte/elements'
	import { goto } from '$app/navigation'
	import { page } from '$app/state'
	import Planning from '$lib/components/planning.svelte'
	import { listDanceClassDancers } from '$lib/dancers.remote'
	import { getSeasonsAndPlanning } from '$lib/planning.remote'
	import type { DanceClass, Dancer } from '$lib/server/models'

	let season = $state(page.url.searchParams.get('season'))
	let { seasons, selectedSeason, planning } = $derived(await getSeasonsAndPlanning(season))

	let dancers = $state<Dancer[]>([])

	const changeSeason: ChangeEventHandler<HTMLSelectElement> = async ({
		currentTarget: { value }
	}) => {
		if (value !== season && value) {
			season = value
			page.url.searchParams.set('season', season)
			goto(`?${page.url.searchParams.toString()}`)
		}
	}

	async function selectDanceClass({ danceClass }: { danceClass: DanceClass }) {
		dancers = await listDanceClassDancers(danceClass.id)
	}
</script>

<a href="/" class="text-blue-500 hover:underline mb-4 inline-block">Back</a>

<div class="grid grid-cols-[minmax(30%,250px)_70%] gap-2">
	<aside class="flex flex-col gap-2 p-2">
		<h1 class="mb-4">Liste des danseurs ({dancers.length})</h1>
		<ul>
			{#each dancers as dancer (dancer.id)}
				<li class="py-4 border-b">
					<a href="/dancers/{dancer.id}" class="inline-block">
						<span class="text-lg font-bold"
							>{dancer.firstname} {dancer.lastname}</span
						>
						<span class="text-sm text-gray-600">ID: {dancer.id}</span>
					</a>
				</li>
			{/each}
		</ul>
	</aside>
	<main class="flex flex-col gap-2">
		<select class="select select-ghost" onchange={changeSeason}>
			{#each seasons as value}
				{@const selected = value === selectedSeason}
				<option {selected}>{value}</option>
			{/each}
		</select>

		<Planning danceClasses={planning} class="p-6 h-[90vh]" onSelect={selectDanceClass} />
	</main>
</div>