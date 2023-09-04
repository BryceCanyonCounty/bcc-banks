<template>
    <div>
        <div v-if="accountDetails">
            <NavigationBar
                @update:active-page="activePage = $event"
                :currentPage="activePage"
            />
            <div>
                <AccountDetails
                    :owner="account.owner_name"
                    :accountDetails="accountDetails"
                />
            </div>
            <div class="text-gray-100">
                <div v-if="activePage == 'dashboard'">
                    <DashboardComponent :transactions="transactions" />
                </div>
                <div v-if="activePage == 'withdraw'">
                    <WithdrawComponent @withdraw="withdraw($event)" />
                </div>

                <div v-if="activePage == 'deposit'">
                    <DepositComponent @deposit="deposit($event)" />
                </div>

                <div v-if="activePage == 'transfer'">
                    <h1 class="text-3xl">Transfer</h1>
                </div>

                <div v-if="activePage == 'transactions'">
                    <TransactionsComponent :transactions="transactions" />
                </div>

                <div v-if="activePage == 'account-access'">
                    <h1 class="text-3xl">Account Access</h1>
                </div>

                <div class="absolute right-0 bottom-0">
                    <button @click="closeAccount">Close Account</button>
                </div>
            </div>
        </div>

        <LoadSpinner v-else />
    </div>
</template>

<script setup>
import { ref, watch, computed, onUnmounted } from 'vue';
import { useRoute, useRouter } from 'vue-router';
import { storeToRefs } from 'pinia';
import { useAccountStore } from '@/stores/accounts';
import api from '@/api';
import { useSessionStore } from '@/stores/session';
import LoadSpinner from '@/components/LoadSpinner.vue';
import NavigationBar from '@/components/accounts/NavigationBar.vue';
import AccountDetails from '@/components/accounts/AccountDetails.vue';
import DashboardComponent from '@/components/accounts/DashboardComponent.vue';
import WithdrawComponent from '@/components/accounts/WithdrawComponent.vue';
import DepositComponent from '@/components/accounts/DepositComponent.vue';
import TransactionsComponent from '@/components/accounts/TransactionsComponent.vue';

const route = useRoute();
const router = useRouter();
const accountStore = useAccountStore();
const sessionStore = useSessionStore();

const { getAccountById } = storeToRefs(accountStore);
const { getBankId } = storeToRefs(sessionStore);

const activePage = ref('dashboard');
const accountDetails = ref(null);
const transactions = ref(null);

onUnmounted(() => {
    api.post('Feather:Banks:UnlockAccount', {
        account: accountDetails.value.id,
    }).catch((e) => {
        console.error(e.message);
    });
});

const getAccountDetails = (accountId, prevAccountId = null) => {
    api.post('Feather:Banks:GetAccount', {
        account: accountId,
        lockAccount: true,
    })
        .then((e) => {
            if (e.data.status !== false) {
                accountDetails.value = e.data.account;
                transactions.value = e.data.transactions;
            } else {
                console.error(e.data.message);
            }
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

    activePage.value = 'dashboard';
};

let account = getAccountById.value(Number(route.params.id));
getAccountDetails(route.params.id);
watch(
    () => route.params,
    (current, previous) => {
        account = getAccountById.value(Number(route.params.id));
        getAccountDetails(route.params.id, previous.id);
    }
);

const withdraw = (data) => {
    api.post('Feather:Banks:Withdraw', {
        account: account.id,
        amount: data.amount,
        description: data.description,
        type: data.type,
    })
        .then((e) => {
            if (e.data.status !== false) {
                accountDetails.value = e.data.account;
                transactions.value = e.data.transactions;

                api.post('Feather:Banks:Notify', {
                    message: 'Withdrawal Successful',
                }).catch((e) => {
                    console.error(e.message);
                });
            } else {
                api.post('Feather:Banks:Notify', {
                    message: e.data.message,
                }).catch((e) => {
                    console.error(e.message);
                });
            }
        })
        .catch((e) => {
            console.error(e.message);
        });
};

const deposit = (data) => {
    api.post('Feather:Banks:Deposit', {
        account: account.id,
        amount: data.amount,
        description: data.description,
        type: data.type,
    })
        .then((e) => {
            if (e.data.status !== false) {
                accountDetails.value = e.data.account;
                transactions.value = e.data.transactions;
            } else {
                api.post('Feather:Banks:Notify', {
                    message: e.data.message,
                }).catch((e) => {
                    console.error(e.message);
                });
            }
        })
        .catch((e) => {
            console.error(e.message);
        });
};

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
                api.post('Feather:Banks:Notify', {
                    message: e.data.message,
                }).catch((e) => {
                    console.error(e.message);
                });
            }
        })
        .catch((e) => {
            console.error(e.message);
        });
};
</script>

<style scoped></style>
