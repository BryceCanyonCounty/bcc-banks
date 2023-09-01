<script setup>
import { ref, watch } from 'vue';
const emit = defineEmits(['update:activePage']);
const props = defineProps({
    currentPage: {
        type: String,
        required: true,
    },
});

const activePage = ref('account-details');

watch(
    () => activePage.value,
    (current, previous) => {
        emit('update:activePage', current);
    }
);

watch(
    () => props.currentPage,
    (current, previous) => {
        activePage.value = current;
    }
);
</script>

<template>
    <div class="account-navigation text-gray-100">
        <ul class="navmenu">
            <li>
                <button
                    @click="activePage = 'account-details'"
                    :class="{
                        underline: activePage === 'account-details',
                    }"
                >
                    Account Details
                </button>
            </li>
            <li>
                <button
                    @click="activePage = 'withdraw'"
                    :class="{
                        underline: activePage === 'withdraw',
                    }"
                >
                    Withdraw
                </button>
            </li>
            <li>
                <button
                    @click="activePage = 'deposit'"
                    :class="{
                        underline: activePage === 'deposit',
                    }"
                >
                    Deposit
                </button>
            </li>
            <li>
                <button
                    @click="activePage = 'transfer'"
                    :class="{
                        underline: activePage === 'transfer',
                    }"
                >
                    Transfer
                </button>
            </li>
            <li>
                <button
                    @click="activePage = 'transactions'"
                    :class="{
                        underline: activePage === 'transactions',
                    }"
                >
                    Transactions
                </button>
            </li>
            <li>
                <button
                    @click="activePage = 'account-access'"
                    :class="{
                        underline: activePage === 'account-access',
                    }"
                >
                    Account Access
                </button>
            </li>
        </ul>
    </div>
</template>

<style scoped>
.account-navigation {
    background-color: rgb(25, 25, 25);
    font-size: 1.2em;
    width: 100%;
}

.navmenu {
    display: flex;
    justify-content: space-between;
    max-width: 50em;
    padding: 0.75em 0;
    margin: 0.85em auto;
    font-size: 1.2em;
}
</style>
