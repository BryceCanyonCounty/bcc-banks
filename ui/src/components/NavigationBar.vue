<script setup>
import NavigationItem from './NavigationItem.vue';
import { useAccountStore } from '@/stores/accounts';

const accountStore = useAccountStore();
</script>

<template>
    <nav class="w-full">
        <div>
            <h1
                class="text-gray-200 text-center text-xl mt-5 font-semibold font-crock"
            >
                Navigation
            </h1>
        </div>
        <div class="mt-10">
            <NavigationItem route="home" label="Home" />
            <p class="text-center font-semibold text-gray-200 mt-5">Accounts</p>
            <button
                @click="$emit('create-account')"
                class="text-gray-100 py-2 w-full text-center border-y border-1 border-gray-800 nav-item"
            >
                Create Account
            </button>

            <NavigationItem
                v-for="account in accountStore.getAccounts"
                :key="account.id"
                route="accounts"
                :id="account.id"
                :label="account.name"
            />
        </div>
    </nav>
</template>

<style scoped>
.font-crock {
    font-family: 'crock';
}

.nav-item {
    background-color: rgb(30, 30, 30);
}
.nav-item:hover {
    background-color: rgb(70, 70, 70);
}
</style>
