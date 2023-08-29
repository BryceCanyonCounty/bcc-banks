<script setup>
import api from './api';
import { ref, onMounted, onUnmounted } from 'vue';
import { storeToRefs } from 'pinia';
import { RouterView } from 'vue-router';
import '@/assets/styles/main.css';

import NavigationBar from '@/components/NavigationBar.vue';
import ModalPanel from '@/components/ModalPanel.vue';

import { useSessionStore } from '@/stores/session';
import { useAccountStore } from '@/stores/accounts';

const devmode = ref(true);
const visible = ref(false);
const showCreateAccountModal = ref(false);

// Store Vars
const sessionStore = useSessionStore();
const accountStore = useAccountStore();
const { getBankName, getBankId } = storeToRefs(sessionStore);

onMounted(() => {
    window.addEventListener('message', onMessage);
});

onUnmounted(() => {
    window.removeEventListener('message', onMessage);
});

const onMessage = (event) => {
    switch (event.data.type) {
        case 'toggle':
            visible.value = event.data.visible;
            console.log(event.data.accounts);
            sessionStore.setBankId(event.data.bank.id);
            sessionStore.setBankName(event.data.bank.name);
            accountStore.storeAccounts(event.data.accounts);

            api.post('Feather:Banks:UpdateState', {
                state: visible.value,
            }).catch((e) => {
                console.log(e.message);
            });
            break;
        case 'createAccount':
            accountStore.addAccount(event.data.accountData);
            break;
        default:
            break;
    }
};

const closeApp = () => {
    visible.value = false;
    api.post('Feather:Banks:UpdateState', {
        state: visible.value,
    }).catch((e) => {
        console.log(e.message);
    });
};

// Create Account Form
const accountName = ref('');
const closeCreateAccountModal = () => {
    accountName.value = '';
    showCreateAccountModal.value = false;
};

const createAccount = () => {
    if (accountName.value !== null) {
        showCreateAccountModal.value = false;
        api.post('createAccount', {
            accountName: accountName.value,
            bankId: getBankId.value,
        }).catch((e) => {
            console.log(e);
        });
        accountName.value = '';
    }
};
</script>

<template>
    <div class="container" v-if="visible || devmode">
        <div class="absolute inset-y-0 flex flex-col w-64 h-full sidebar">
            <NavigationBar @create-account="showCreateAccountModal = true" />
        </div>
        <div class="pl-64 h-full content">
            <div
                @click="closeApp"
                class="absolute text-gray-400 text-2xl right-3 hover:text-red-800"
            >
                &times;
            </div>
            <div class="text-center">
                <h1
                    class="text-gray-50 title text-center text-3xl pt-5 font-crock"
                >
                    {{ `${getBankName} Bank` }}
                </h1>
            </div>
            <RouterView />
        </div>

        <ModalPanel :visible="showCreateAccountModal" title="New Account">
            <div>
                <label
                    for="accountName"
                    class="block text-sm font-medium leading-6 text-gray-200"
                    >Account Name</label
                >
                <div class="mt-2">
                    <input
                        type="text"
                        name="accountName"
                        id="accountName"
                        v-model="accountName"
                        class="block w-full rounded-md border-0 py-1.5 text-gray-900 placeholder:text-gray-400 text-sm p-1"
                        placeholder="MooMoo Milk Sales"
                        aria-describedby="email-description"
                    />
                </div>
                <div class="flex justify-end">
                    <button
                        @click="createAccount"
                        class="border border-gray-950 text-gray-400 rounded-md mt-3 p-1 button"
                        :class="{
                            disabledButton:
                                accountName === null || accountName.length < 5,
                        }"
                    >
                        Create
                    </button>
                    <button
                        @click="closeCreateAccountModal"
                        class="border border-gray-950 text-gray-400 rounded-md mt-3 ml-3 p-1 button"
                    >
                        Cancel
                    </button>
                </div>
            </div>
        </ModalPanel>
    </div>
</template>

<style scoped>
.container {
    background-color: rgb(32, 32, 32);

    /* background-image: url('./assets/images/bg.jpg');
  background-position: center;
  background-repeat: no-repeat;
  background-position: 0;
  background-size: 100%; */

    border-radius: 6px;
    height: 75vh;
    width: 75vw;

    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;

    margin: auto;
    overflow: hidden;
}

.content {
    background-color: rgb(18, 18, 18);
}

.sidebar {
    background-color: rgb(17, 17, 17);
}

#close {
    position: absolute;
    right: 0;
    top: 0;
    margin-right: 0.75rem;
    margin-top: 0.3rem;
    font-size: 25px;
}

.button {
    background-color: rgb(30, 30, 30);
}
.font-crock {
    font-family: 'crock';
}

.disabledButton {
    background-color: red;
}
</style>
