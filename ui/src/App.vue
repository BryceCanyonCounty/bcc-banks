<script setup>
import api from './api';

import { ref, onMounted, onUnmounted } from 'vue';
import { storeToRefs } from 'pinia';
import { RouterView, useRouter } from 'vue-router';
import '@/assets/styles/main.css';

import NavigationBar from '@/components/NavigationBar.vue';
import NewAccountModal from '@/components/modals/NewAccountModal.vue';

import { useSessionStore } from '@/stores/session';
import { useAccountStore } from '@/stores/accounts';

const devmode = ref(false);
const visible = ref(false);
const showCreateAccountModal = ref(false);
const router = useRouter();

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
            sessionStore.setBankId(event.data.bank['id']);
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
    router.push({ name: 'home' });
    visible.value = false;
    api.post('Feather:Banks:UpdateState', {
        state: visible.value,
    }).catch((e) => {
        console.log(e.message);
    });
};

const createAccount = (event) => {
    if (event !== null) {
        showCreateAccountModal.value = false;

        api.post('Feather:Banks:CreateAccount', {
            name: event,
            bank: getBankId.value,
        })
            .then((event) => {
                accountStore.storeAccounts(event.data);
            })
            .catch((e) => {
                console.log(e.message);
            });
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

        <NewAccountModal
            :visible="showCreateAccountModal"
            @CloseNewAccountModal="showCreateAccountModal = false"
            @CreateAccount="createAccount($event, accountName)"
        ></NewAccountModal>
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

.font-crock {
    font-family: 'crock';
}
</style>
