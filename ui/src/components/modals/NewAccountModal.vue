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
                class="block font-medium leading-6 text-gray-200 field-label"
                >Account Name</label
            >
            <div class="mt-2">
                <input
                    type="text"
                    name="accountName"
                    id="accountName"
                    v-model="accountName"
                    class="block rounded-md border-0 field-input"
                    placeholder="MooMoo Milk Sales"
                    aria-describedby="email-description"
                />
            </div>
            <div class="flex justify-end">
                <button
                    :disabled="isDisabled"
                    @click="onCreateClicked"
                    class="border border-gray-950 rounded-md"
                    :class="{
                        disabledButton: isDisabled,
                        button: !isDisabled,
                    }"
                >
                    Create
                </button>
                <button
                    @click="onClosedClicked"
                    class="border border-gray-950 rounded-md button"
                >
                    Cancel
                </button>
            </div>
        </div>
    </ModalPanel>
</template>

<style scoped>
.field-label {
    margin: 0 auto;
    width: 95%;
    font-size: 1.2em;
}
.field-input {
    font-size: 1.2em;
    padding: 0.2em 0.1em 0.2em 0.1em;
    margin: 0 auto;
    width: 95%;
    background-color: rgb(40, 40, 40);
    color: rgb(150, 150, 150);
}
.field-input::placeholder {
    color: rgb(90, 90, 90);
}
.button {
    background-color: rgb(30, 30, 30);
    color: rgb(150, 150, 150);
    font-weight: 600;
    font-size: 1.2em;
    margin-top: 0.75em;
    margin-right: 0.75em;
    padding: 0.3em 0.6em;
    text-align: center;
    align-items: middle;
}

.button:hover {
    background-color: rgb(70, 70, 70);
}
.disabledButton {
    background-color: rgb(20, 20, 20);
    color: rgb(40, 40, 40);
    font-weight: 600;
    font-size: 1.2em;
    margin-top: 0.75em;
    margin-right: 0.75em;
    padding: 0.3em 0.6em;
    text-align: center;
    align-items: middle;
}
</style>
