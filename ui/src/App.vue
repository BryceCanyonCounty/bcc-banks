<template>
    <div class="container" v-if="visible || devmode">
        <div class="sidebar">
            <NavigationBar @create-account="showCreateAccountModal = true" />
        </div>

        <div class="content">
            <div
                @click="closeApp"
                class="close-button text-gray-400 text-2xl right-3 hover:text-red-800"
            >
                &times;
            </div>
            <div class="text-center">
                <h1 class="text-gray-50 title text-center pt-5 font-crock">
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

<script setup>
import api from './api';

import { ref, onMounted, onUnmounted } from 'vue';
import { storeToRefs } from 'pinia';
import { RouterView, useRouter } from 'vue-router';
import '@/assets/styles/main.scss';

import NavigationBar from '@/components/NavigationBar.vue';
import NewAccountModal from '@/components/modals/NewAccountModal.vue';

import { useSessionStore } from '@/stores/session';
import { useAccountStore } from '@/stores/accounts';

const devmode = ref(true);
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
                console.error(e.message);
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
        console.error(e.message);
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
                console.error(e.message);
            });
    }
};
</script>

<style scoped>
.container {
    background-color: rgb(32, 32, 32);

    border-radius: 6px;
    max-height: 60vh;
    max-width: 50vw;

    position: absolute;
    top: 0;
    bottom: 0;
    left: 0;
    right: 0;

    margin: auto;
    overflow: hidden;
}

.content {
    position: absolute;
    height: 100%;
    background-color: rgb(18, 18, 18);
    top: 0;
    left: 5vw;
    width: 45vw;
}

.sidebar {
    position: absolute;
    background-color: rgb(17, 17, 17);
    height: 100%;
    min-width: 5vw;
    max-width: 5vw;
}

.close-button {
    position: absolute;
    right: 0;
    top: 0;
    margin: 0.5em 0.75em 0 0;
    font-size: 2em;
}

.title {
    font-size: 2.5em;
    font-weight: 600;
}

.font-crock {
    font-family: 'crock';
}
</style>
