<template>
    <div>
        <div v-if="transactions">
            <table class="table">
                <thead>
                    <tr>
                        <th>Transaction ID</th>
                        <th>Type</th>
                        <th>User</th>
                        <th>Amount</th>
                        <th>Action</th>
                        <th>Description</th>
                        <th>Timestamp</th>
                    </tr>
                </thead>
                <tbody>
                    <tr
                        v-for="transaction in sortedTransactions"
                        :key="transaction.id"
                    >
                        <td>{{ transaction.id }}</td>
                        <td>{{ transaction.loan_id ? 'Loan' : 'Account' }}</td>
                        <td>{{ transaction.character_name }}</td>
                        <td>{{ transaction.amount }}</td>
                        <td>{{ transaction.type }}</td>
                        <td>{{ transaction.description }}</td>
                        <td>{{ formatDate(transaction.created_at) }}</td>
                    </tr>
                </tbody>
            </table>
        </div>

        <div v-else>
            <LoadSpinner />
        </div>
    </div>
</template>

<script setup>
import { computed } from 'vue';
import { DateTime } from 'luxon';
import LoadSpinner from '../LoadSpinner.vue';

const props = defineProps({
    transactions: {
        type: Object,
        required: true,
    },
});

const formatDate = (date) => {
    return DateTime.fromMillis(date).toFormat('yyyy-MM-dd HH:mm:ss');
};

const sortedTransactions = computed(() => {
    return props.transactions
        .slice()
        .sort((a, b) => a.created_at - b.created_at);
});
</script>

<style lang="scss" scoped>
.table {
    width: 95%;
    margin: 0 auto;
}
</style>
