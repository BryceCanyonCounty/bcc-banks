<script setup>
import { ref, watch, computed } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useAccountStore } from '@/stores/accounts';
import api from '@/api';
import { useSessionStore } from '@/stores/session';

const route = useRoute();
const router = useRouter();
const accountStore = useAccountStore();
const sessionStore = useSessionStore();

const { getAccountById } = storeToRefs(accountStore);
const { getBankId } = storeToRefs(sessionStore);

const getAccountDetails = (accountId) => {
    api.post('Feather:Banks:GetAccount', {
        account: accountId,
    })
        .then((e) => {
            accountDetails.value = e.data;
        })
        .catch((e) => {
            console.error(e.message);
        });
};

let account = getAccountById.value(Number(route.params.id));
const accountDetails = ref(null);
getAccountDetails(route.params.id);
watch(
    () => route.params,
    (current, previous) => {
        account = getAccountById.value(Number(route.params.id));
        getAccountDetails(route.params.id);
    }
);

// Close Account
const closeAccount = () => {
    api.post('Feather:Banks:CloseAccount', {
        bank: getBankId.value,
        account: account.id,
    })
        .then((e) => {
            if (e.data.status !== false) {
                accountStore.storeAccounts(e.data.accounts);
                router.push({ name: 'home' });
            } else {
                console.error(e.data.message);
            }
        })
        .catch((e) => {
            console.error(e.message);
        });
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
        {{ accountDetails }}
        <div>
            <button @click="closeAccount">Close Account</button>
        </div>
    </div>
</template>

<style scoped></style>
