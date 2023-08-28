import { defineStore } from 'pinia';

export const useAccountStore = defineStore('accounts', {
    state: () => ({
        accounts: null,
    }),
    getters: {
        // Simple Example of getting data ( Returns all accounts )
        getAccounts: (state) => state.accounts,
        // Sending data to a getter
        // The param after return is the data you're sending in
        // accessing a JS array you can use Array#find to return the object
        getAccountById: (state) => {
            return (id) => state.accounts.find((account) => account.ID === id);
        }
    },
    actions: {
        storeAccounts(accounts) {
            this.accounts = accounts
        }
    },
})