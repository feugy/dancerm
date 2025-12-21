<script lang="ts">
  import { saveDancer } from "$lib/dancers.remote";
  import type { Dancer } from "$lib/server/models";

  let { dancerId }: { dancerId?: Dancer["id"] } = $props();
  const loading = $derived(dancerId === undefined);
  const save = $derived(dancerId ? saveDancer.for(dancerId) : undefined);
</script>

<span class="flex flex-col gap-6 flex-1">
  <h1 class="card-title pt-4">Danseur</h1>
  <input type="hidden" name="id" value={save?.fields.id.value()} />
  <span class="flex gap-6">
    <select
      class="select w-20"
      class:skeleton={loading}
      disabled={loading}
      {...save?.fields.title.as("select")}
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
        {...save?.fields.firstname.as("text")}
      />
    </label>
  </span>
  <label class="floating-label">
    <span>Nom</span>
    <input
      class="input w-full capitalize"
      class:skeleton={loading}
      disabled={loading}
      {...save?.fields.lastname.as("text")}
    />
  </label>
  <label class="floating-label">
    <span>Téléphone portable</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...save?.fields.cellphone.as("text")}
      class="input w-full"
    />
  </label>
  <label class="floating-label">
    <span>Email</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...save?.fields.email.as("email")}
      class="input w-full"
    />
  </label>
  <label class="floating-label">
    <span>Date de naissance</span>
    <input
      class:skeleton={loading}
      disabled={loading}
      {...save?.fields.birth.as("date")}
      class="input w-full"
    />
  </label>
</span>
