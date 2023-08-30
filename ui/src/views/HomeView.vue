<script setup>
import AccountPreviewItem from '@/components/AccountPreviewItem.vue';
import { useAccountStore } from '@/stores/accounts';

const accountStore = useAccountStore();
</script>

<template>
    <div class="w-full">
        <div class="grid grid-cols-3 gap-4 mt-10 px-5">
            <AccountPreviewItem
                v-for="account in accountStore.getAccounts"
                :key="account.id"
                :accountName="account.account_name"
                :accountId="account.id"
                :ownerName="account.owner_name"
            />
        </div>
    </div>
</template>

<style scoped></style>
