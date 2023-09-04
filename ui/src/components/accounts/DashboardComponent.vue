<template>
    <div class="grid grid-cols-12 gap-5 mt-4">
        <div class="col-span-2"></div>
        <div class="col-span-8">
            <h1>Cash</h1>
            <div class="grid grid-cols-4 gap-5">
                <CardComponent title="Total Withdraws">
                    {{ Object.keys(cashWithdraws).length }}
                </CardComponent>

                <CardComponent title="Total Withdraw Value">
                    {{ sum(cashWithdraws, true) }}
                </CardComponent>
                <CardComponent title="Total Withdraws">
                    {{ Object.keys(cashDeposits).length }}
                </CardComponent>

                <CardComponent title="Total Withdraw Value">
                    {{ sum(cashDeposits, true) }}
                </CardComponent>
            </div>
        </div>
        <div class="col-span-2"></div>

        <div class="col-span-2"></div>
        <div class="col-span-8">
            <h1>Gold</h1>
            <div class="grid grid-cols-4 gap-5">
                <CardComponent title="Total Withdraws">
                    {{ Object.keys(goldWithdraws).length }}
                </CardComponent>

                <CardComponent title="Total Withdraw Value">
                    {{ sum(goldWithdraws) }}
                </CardComponent>

                <CardComponent title="Total Deposits">
                    {{ Object.keys(goldDeposits).length }}
                </CardComponent>

                <CardComponent title="Total Deposits Value">
                    {{ sum(goldDeposits) }}
                </CardComponent>
            </div>
        </div>
        <div class="col-span-2"></div>
    </div>
</template>

<script setup>
import CardComponent from '@/components/accounts/CardComponent.vue';
import { computed } from 'vue';

const props = defineProps({
    transactions: {
        type: Object,
        required: true,
    },
});

const cashWithdraws = computed(() => {
    return props.transactions
        .filter((transactions) => {
            return transactions.type === 'withdraw - cash';
        })
        .map((transaction) => {
            return Number(transaction.amount);
        });
});

const cashDeposits = computed(() => {
    return props.transactions
        .filter((transactions) => {
            return transactions.type === 'deposit - cash';
        })
        .map((transaction) => {
            return Number(transaction.amount);
        });
});

const goldWithdraws = computed(() => {
    return props.transactions
        .filter((transactions) => {
            return transactions.type === 'withdraw - gold';
        })
        .map((transaction) => {
            return Number(transaction.amount);
        });
});

const goldDeposits = computed(() => {
    return props.transactions
        .filter((transactions) => {
            return transactions.type === 'deposit - gold';
        })
        .map((transaction) => {
            return Number(transaction.amount);
        });
});

const sum = (object, isCash = false) => {
    let result = 0;
    Object.keys(object).forEach((key) => {
        result += object[key];
    });

    if (result === 0) {
        if (isCash) {
            return '$0.00';
        } else {
            return '0.00g';
        }
    }

    if (isCash) {
        return new Intl.NumberFormat('en-US', {
            style: 'currency',
            currency: 'USD',
        }).format(result);
    } else {
        return result.toFixed(2) + 'g';
    }
};
</script>

<style lang="scss" scoped></style>
