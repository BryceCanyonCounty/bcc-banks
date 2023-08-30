import { defineStore } from 'pinia';

export const useAccountStore = defineStore('accounts', {
    state: () => ({
        accounts: null,
    }),
    getters: {
        getAccountById: (state) => {
            return (id) => state.accounts.find((account) => account.id === id);
        },
        getAccounts: (state) => {
            return state.accounts;
        },
    },
    actions: {
        storeAccounts(accounts) {
            this.accounts = accounts;
        },
    },
});
