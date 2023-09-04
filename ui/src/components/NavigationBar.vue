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
            <select class="w-full account-select" v-model="currentAccount">
                <option value="0" disabled>Select an account</option>
                <option
                    v-for="account in accountStore.getAccounts"
                    :key="account.id"
                    :value="account.id"
                >
                    {{ account.account_name }}
                </option>
            </select>
            <!-- <NavigationItem
                v-for="account in accountStore.getAccounts"
                :key="account.id"
                route="accounts"
                :id="account.id"
                :label="account.account_name"
            /> -->
        </div>
    </nav>
</template>

<script setup>
import { ref, watch } from 'vue';
import NavigationItem from './NavigationItem.vue';
import { useAccountStore } from '@/stores/accounts';
import { useRoute, useRouter } from 'vue-router';

const accountStore = useAccountStore();
const currentAccount = ref(0);
const route = useRoute();
const router = useRouter();

watch(
    () => currentAccount.value,
    (newValue, oldValue) => {
        if (newValue !== 0) {
            router.push({ name: 'accounts', params: { id: newValue } });
        }
    }
);

watch(
    () => route.path,
    (newValue, oldValue) => {
        if (newValue == '/') {
            currentAccount.value = 0;
        }
    }
);
</script>

<style scoped lang="scss">
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

.account-select {
    background-color: rgb(30, 30, 30);
    color: rgb(200, 200, 200);
    border: 1px solid rgb(30, 30, 30);
    padding: 0.5em;
    margin-top: 0.5em;
    margin-bottom: 1em;
    font-size: 1.15em;
    font-family: 'crock';
    font-weight: 400;
    scrollbar-color: rgb(30, 30, 30) rgb(30, 30, 30);
}

select:focus {
    outline: none;
}

select::-webkit-scrollbar {
    width: 0.5em;
}
</style>
