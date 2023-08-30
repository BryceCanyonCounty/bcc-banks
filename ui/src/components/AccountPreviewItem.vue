<script setup>
defineProps({
    accountName: String,
    ownerName: String,
    accountId: Number,
});
</script>

<template>
    <div class="text-gray-900 px-3 text-center item">
        <div class="text-lg font-semibold underline">{{ accountName }}</div>
        <div>
            <span class="font-semibold">Owner Name:</span> {{ ownerName }}
        </div>
        <!-- <div><span class="font-semibold">Gold:</span> {{ gold }}</div> -->
        <div></div>
    </div>
</template>

<style scoped>
.item {
    background-image: url('../assets/images/bg.jpg');
    background-position: center;
    background-repeat: no-repeat;
    background-position: 0;
    background-size: 100%;
}
</style>
