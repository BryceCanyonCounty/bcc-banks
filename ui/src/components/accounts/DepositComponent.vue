<template>
    <form @submit.prevent="submitForm">
        <div class="text-gray-900">
            <input v-model="amount" type="number" />
        </div>
        <div class="text-gray-900 mt-5">
            <select v-model="type">
                <option value="cash">Cash</option>
                <option value="gold">Gold</option>
            </select>
        </div>
        <div class="text-gray-900 mt-5">
            <input v-model="description" placeholder="Memo" />
        </div>
        <div>
            <button class="bg-gray-700 rounded py-1 px-3 mt-5" type="submit">
                Deposit Funds
            </button>
        </div>
    </form>
</template>

<script setup>
import { ref } from 'vue';

const emit = defineEmits(['deposit']);

const amount = ref(null);
const description = ref(null);
const type = ref('cash');

const submitForm = () => {
    if (
        amount.value <= 0 ||
        (description.value && description.value.length < 5)
    ) {
        api.post('Feather:Banks:Notify', {
            message: 'Invalid amount or description.',
        }).catch((e) => {
            console.error(e.message);
        });
        return;
    }

    emit('deposit', {
        amount: amount.value,
        type: type.value,
        description: description.value,
    });

    amount.value = null;
    description.value = null;
    type.value = 'cash';
};
</script>

<style lang="scss" scoped></style>
