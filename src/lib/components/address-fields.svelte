<script lang="ts">
  import { saveDancer } from "$lib/dancers.remote";
  import type { Address, Dancer } from "$lib/server/models";

  let {
    addressId,
    dancerId,
  }: { addressId: Address["id"]; dancerId: Dancer["id"] } = $props();

  const save = $derived(saveDancer.for(dancerId));
</script>

<span class="flex flex-col gap-6 flex-1">
  <h1 class="card-title pt-4">Adresse</h1>
  <input type="hidden" name="address.id" value={addressId} />
  <label class="floating-label">
    <span>Voie</span>
    <input
      class="input w-full capitalize"
      {...save.fields.address.street.as("text")}
    />
  </label>
  <span class="flex gap-6"
    ><label class="floating-label w-24">
      <span>Code postal</span>
      <input
        class="input w-full capitalize"
        {...save.fields.address.zipcode.as("number")}
      />
    </label>
    <label class="floating-label flex-1">
      <span>Ville</span>
      <input class="input w-full" {...save.fields.address.city.as("text")} />
    </label></span
  >
  <label class="floating-label">
    <span>Téléphone</span>
    <input class="input w-full" {...save.fields.address.phone.as("text")} />
  </label>
</span>
