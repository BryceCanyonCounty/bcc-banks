import { defineStore } from "pinia";

export const useAccountStore = defineStore("accounts", {
  state: () => ({
    accounts: null,
  }),
  getters: {
    getAccountById: (state) => {
      return (id) => state.accounts.find((account) => account.ID === id);
    },
    getAccounts: (state) => {
      return state.accounts;
    },
  },
  actions: {
    storeAccounts(accounts) {
      this.accounts = accounts;
    },
    addAccount(account) {
      this.accounts.push(account[0]);
    },
    closeAccount(id) {
      this.accounts = this.accounts.filter((account) => account.ID !== id);
    },
  },
});
