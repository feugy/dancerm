<script lang="ts">
  import SaveIcon from "$lib/components/icons/save.svelte";
  import { saveDancer } from "$lib/dancers.remote";
  import type { Address, Dancer } from "$lib/server/models";
  import { dateToDateInput } from "$lib/utils/forms";
  import AddressFields from "./address-fields.svelte";
  import DancerFields from "./dancer-fields.svelte";

  let {
    value,
    mainAddressId,
  }: { value?: Dancer; mainAddressId?: Address["id"] } = $props();

  const save = $derived(value ? saveDancer.for(value.id) : undefined);

  $effect(() => {
    if (!value || !save) return;

    save.fields.set({
      ...value,
      title: value.title ?? "Mlle",
      firstname: value.firstname ?? "",
      lastname: value.lastname ?? "",
      cellphone: value.cellphone ?? "",
      email: value.email ?? "",
      birth: dateToDateInput(value.birth),
      address: value.address
        ? {
            ...value.address,
            street: value.address.street ?? "",
            zipcode: value.address.zipcode ?? 0,
            city: value.address.city ?? "",
            phone: value.address.phone ?? "",
          }
        : undefined,
    });
  });

  const isModified = $derived(
    save?.fields.title.value() !== value?.title ||
      save?.fields.firstname.value() !== (value?.firstname ?? "") ||
      save?.fields.lastname.value() !== (value?.lastname ?? "") ||
      save?.fields.cellphone.value() !== (value?.cellphone ?? "") ||
      save?.fields.email.value() !== (value?.email ?? "") ||
      save?.fields.birth.value() !== (dateToDateInput(value?.birth) ?? "") ||
      save?.fields.address?.street.value() !== (value?.address?.street ?? "") ||
      save?.fields.address?.zipcode.value() !==
        (value?.address?.zipcode ?? 0) ||
      save?.fields.address?.city.value() !== (value?.address?.city ?? "") ||
      save?.fields.address?.phone.value() !== (value?.address?.phone ?? "")
  );
</script>

<form class="card bg-base-100 border border-primary" {...save}>
  <div class="card-body flex-col pt-0 gap-6">
    <div class="flex gap-6">
      <DancerFields dancerId={value?.id} />
      {#if value?.address && value.address.id !== mainAddressId}
        <AddressFields addressId={value.address.id} dancerId={value.id} />
      {/if}
    </div>
  </div>

  {#each save?.fields.allIssues() as issue}
    <p>{issue.message}</p>
  {/each}
  <button
    disabled={!isModified || !save || save.pending > 0}
    class="btn btn-primary m-2"
  >
    {#if save?.pending}<span class="loading loading-spinner size-5"></span>
    {:else}<SaveIcon class="size-5" />{/if}Save</button
  >
</form>
