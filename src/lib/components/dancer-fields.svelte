<script lang="ts">
import SaveIcon from '$lib/components/icons/pencil.svelte'
import { saveDancer } from '$lib/dancers.remote'
import type { Dancer } from '$lib/server/models'
import { dateToDateInput } from '$lib/utils/forms'

const {
	value,
	onchange
}: {
	value?: Dancer
	onchange?: (ags: { value: Dancer; modified: boolean }) => void
} = $props()
const loading = $derived(value?.id === undefined)
const form = $derived(value?.id ? saveDancer.for(value.id) : undefined)

const modified = $derived(
	form?.fields.title.value() !== value?.title ||
		form?.fields.firstname.value() !== (value?.firstname ?? '') ||
		form?.fields.lastname.value() !== (value?.lastname ?? '') ||
		form?.fields.cellphone.value() !== (value?.cellphone ?? '') ||
		form?.fields.email.value() !== (value?.email ?? '') ||
		form?.fields.birth.value() !== (dateToDateInput(value?.birth) ?? '')
)

$effect(() => {
	if (!value) return
	onchange?.({ value, modified })
})
</script>

<span class="flex flex-col gap-6 flex-1">
  <h1 class="card-title pt-4">
    Danseur {#if modified}<SaveIcon class="size-4" />{/if}
  </h1>
  <input type="hidden" name="id" value={form?.fields.id.value()} />
  <span class="flex gap-6">
    <select
      class="select w-20"
      class:skeleton={loading}
      disabled={loading}
      {...form?.fields.title.as("select")}
    >
      <option disabled selected>Civilité:</option>
      <option>M.</option>
      <option>Mlle</option>
      <option>Mme</option>
    </select>

    <label class="floating-label flex-1">
      <span>Prénom</span>
      <input
        class="input w-full capitalize"
        class:skeleton={loading}
        disabled={loading}
        {...form?.fields.firstname.as("text")}
      />
    </label>
  </span>
  <label class="floating-label">
    <span>Nom</span>
    <input
      class="input w-full capitalize"
      class:skeleton={loading}
      disabled={loading}
      {...form?.fields.lastname.as("text")}
    />
  </label>
  <label class="floating-label">
    <span>Téléphone portable</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...form?.fields.cellphone.as("text")}
      class="input w-full"
    />
  </label>
  <label class="floating-label">
    <span>Email</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...form?.fields.email.as("email")}
      class="input w-full"
    />
  </label>
  <label class="floating-label">
    <span>Date de naissance</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...form?.fields.birth.as("date")}
      class="input w-full"
    />
  </label>
</span>
