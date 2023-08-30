<script setup>
import { ref, computed } from 'vue';
import ModalPanel from '@/components/ModalPanel';

const emit = defineEmits(['CreateAccount', 'CloseNewAccountModal']);

const isDisabled = computed(() => {
    return accountName.value === null || accountName.value.length < 3;
});

const accountName = ref(null);
const onCreateClicked = () => {
    emit('CreateAccount', accountName.value);
    accountName.value = null;
};
const onClosedClicked = () => {
    emit('CloseNewAccountModal');
    accountName.value = null;
};
</script>

<template>
    <ModalPanel title="New Account">
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
                    :disabled="isDisabled"
                    @click="onCreateClicked"
                    class="border border-gray-950 text-gray-400 rounded-md mt-3 p-1 button"
                    :class="{
                        disabledButton: isDisabled,
                    }"
                >
                    Create
                </button>
                <button
                    @click="onClosedClicked"
                    class="border border-gray-950 text-gray-400 rounded-md mt-3 ml-3 p-1 button"
                >
                    Cancel
                </button>
            </div>
        </div>
    </ModalPanel>
</template>

<style scoped>
.button {
    background-color: rgb(30, 30, 30);
}
.disabledButton {
    background-color: red;
}
</style>
