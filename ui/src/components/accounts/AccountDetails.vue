<template>
    <div>
        <div class="account-details">
            <div class="grid grid-cols-12 gap-5">
                <div class="col-span-2">&nbsp;</div>
                <CardComponent
                    class="col-span-2"
                    title="Account"
                    icon="account"
                >
                    <span>{{ accountDetails.name }}</span>
                </CardComponent>

                <CardComponent class="col-span-2" title="Owner" icon="user">
                    <span>{{ owner }}</span>
                </CardComponent>

                <CardComponent class="col-span-2" title="Cash" icon="cash">
                    <span>${{ accountDetails.cash }}</span>
                </CardComponent>

                <CardComponent class="col-span-2" title="Gold" icon="gold">
                    <span>{{ accountDetails.gold }}</span>
                </CardComponent>
                <div class="col-span-2">&nbsp;</div>
            </div>
        </div>
    </div>
</template>

<script setup>
import CardComponent from '@/components/accounts/CardComponent.vue';

defineProps({
    accountDetails: Object,
    owner: String,
});
</script>

<style scoped>
.account-details {
    margin: 2em 0 0 0;
}
</style>
