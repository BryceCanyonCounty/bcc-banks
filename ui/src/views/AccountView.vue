<script setup>
import { ref, watch, computed, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useAccountStore } from '@/stores/accounts';
import api from '@/api';
import { useSessionStore } from '@/stores/session';
import NavigationBar from '@/components/accounts/NavigationBar.vue';

const route = useRoute();
const router = useRouter();
const accountStore = useAccountStore();
const sessionStore = useSessionStore();

const { getAccountById } = storeToRefs(accountStore);
const { getBankId } = storeToRefs(sessionStore);

const activePage = ref('account-details');

const getAccountDetails = (accountId, prevAccountId = null) => {
    api.post('Feather:Banks:GetAccount', {
        account: accountId,
        lockAccount: true,
    })
        .then((e) => {
            accountDetails.value = e.data;
        })
        .catch((e) => {
            console.error(e.message);
        });

    if (prevAccountId !== null) {
        api.post('Feather:Banks:UnlockAccount', {
            account: prevAccountId,
        }).catch((e) => {
            console.error(e.message);
        });
    }

    activePage.value = 'account-details';
};

onUnmounted(() => {
    api.post('Feather:Banks:UnlockAccount', {
        account: accountDetails.value.id,
    }).catch((e) => {
        console.error(e.message);
    });
});

let account = getAccountById.value(Number(route.params.id));
const accountDetails = ref(null);
getAccountDetails(route.params.id);
watch(
    () => route.params,
    (current, previous) => {
        account = getAccountById.value(Number(route.params.id));
        getAccountDetails(route.params.id, previous.id);
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

const cash = computed(() => {
    if (accountDetails.value !== null) {
        return accountDetails.value.cash;
    }
    return 0;
});

const gold = computed(() => {
    if (accountDetails.value !== null) {
        return accountDetails.value.gold;
    }
    return 0;
});
</script>

<template>
    <NavigationBar
        @update:active-page="activePage = $event"
        :currentPage="activePage"
    />
    <div class="text-gray-100">
        <div v-if="activePage == 'account-details'">
            <h1 class="text-3xl">Account Details</h1>

            <div class="account-details bg-gray-900">
                <ul>
                    <li>
                        <span>Account Number:</span>
                        <span class="ml-3">{{ account.id }}</span>
                    </li>
                    <li>
                        <span>Owner:</span>
                        <span class="ml-3">{{ account.owner_name }}</span>
                    </li>
                    <li>
                        <span>Balance:</span>
                        <span class="ml-3">Cash: {{ cash }}</span>
                        <span class="ml-3">Gold: {{ gold }}</span>
                    </li>
                </ul>
            </div>
        </div>

        <div v-if="activePage == 'withdraw'">
            <h1 class="text-3xl">Withdraw</h1>
            <span class="ml-3">Cash: {{ cash }}</span>
            <span class="ml-3">Gold: {{ gold }}</span>
            <form>
                <div class="flex flex-col">
                    <label for="amount">Transaction Type</label>
                    <select>
                        <option value="cash">Cash</option>
                        <option value="gold">Gold</option>
                    </select>
                </div>
                <div class="flex flex-col">
                    <label for="amount">Amount</label>
                    <input
                        type="number"
                        name="amount"
                        id="amount"
                        placeholder="Amount"
                    />
                </div>
                <button>Withdraw</button>
            </form>
        </div>

        <div v-if="activePage == 'deposit'">
            <h1 class="text-3xl">Deposit</h1>
        </div>

        <div v-if="activePage == 'transfer'">
            <h1 class="text-3xl">Transfer</h1>
        </div>

        <div v-if="activePage == 'transactions'">
            <h1 class="text-3xl">Transactions</h1>
        </div>

        <div v-if="activePage == 'account-access'">
            <h1 class="text-3xl">Account Access</h1>
        </div>

        <div class="absolute right-0 bottom-0">
            <button @click="closeAccount">Close Account</button>
        </div>
    </div>
</template>

<style scoped>
.account-details {
    width: 100%;
}
</style>
