import { defineStore } from 'pinia';

export const useSessionStore = defineStore('session', {
    state: () => ({
        bankId: null,
        bankName: null,
    }),
    getters: {
        getBankName: (state) => {
            return state.bankName;
        },
        getBankId: (state) => {
            return state.bankId;
        },
    },
    actions: {
        setBankName(bankName) {
            this.bankName = bankName;
        },
        setBankId(bankId) {
            this.bankId = bankId;
        },
    },
});
