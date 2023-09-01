<script setup>
import NavigationItem from './NavigationItem.vue';
import { useAccountStore } from '@/stores/accounts';

const accountStore = useAccountStore();
</script>

<template>
    <nav class="w-full">
        <div>
            <h1 class="text-gray-200 text-center font-crock title">
                Navigation
            </h1>
        </div>
        <div class="mt-10">
            <NavigationItem route="home" label="Home" />
            <button
                @click="$emit('create-account')"
                class="text-gray-100 py-2 w-full text-center border-y border-1 border-gray-800 nav-item"
            >
                Open Account
            </button>
            <p class="text-center text-gray-200 menu-title font-crock">
                Accounts
            </p>
            <NavigationItem
                v-for="account in accountStore.getAccounts"
                :key="account.id"
                route="accounts"
                :id="account.id"
                :label="account.account_name"
            />
        </div>
    </nav>
</template>

<style scoped>
.font-crock {
    font-family: 'crock';
}

.title {
    margin-top: 1em;
    font-size: 1.5em;
}

.menu-title {
    font-size: 1.2em;
    margin-top: 1.25em;
    margin-bottom: 0.5em;
}

.nav-item {
    font-size: 1.15em;
    background-color: rgb(30, 30, 30);
}
.nav-item:hover {
    background-color: rgb(70, 70, 70);
}
</style>
