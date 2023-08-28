<script setup>
import { watch } from "vue";
import { useRoute, useRouter } from "vue-router";
import { storeToRefs } from "pinia";
import { useAccountStore } from "@/stores/accounts";

const route = useRoute();
const router = useRouter();
const accountStore = useAccountStore();

const { getAccountById } = storeToRefs(accountStore);

let account = getAccountById.value(Number(route.params.id));
watch(
  () => route.params,
  (current, previous) => {
    console.log(
      `Previous Account ID: ${previous.id} Current Account ID: ${current.id}`
    );
    account = getAccountById.value(Number(route.params.id));
  }
);

// Close Account
const closeAccount = () => {
  accountStore.closeAccount(account.ID);
  console.log(`Account ${account.Name} has been closed!`);
  router.push({ name: "home" });
};
</script>

<template>
  <div class="text-gray-100">
    <div class="w-full mx-auto flex">
      <div>Withdraw</div>

      <div>Deposit</div>

      <div>Transfer</div>

      <div>Account Access</div>
    </div>
    {{ account }}
    <div>
      <button @click="closeAccount">Close Account</button>
    </div>
  </div>
</template>

<style scoped></style>
