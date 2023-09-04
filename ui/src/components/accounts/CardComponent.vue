<template>
    <div class="card">
        <div class="icon w-12 mx-auto" v-if="icon">
            <IconComponent :name="icon" />
        </div>
        <div class="header text-center">{{ title }}</div>
        <div class="body text-center">
            <slot></slot>
        </div>
        <div class="footer">
            <slot name="footer"></slot>
        </div>
    </div>
</template>

<script setup>
import IconComponent from '@/components/IconComponent.vue';
defineProps({
    title: {
        type: String,
        required: true,
    },
    icon: {
        type: String,
        required: false,
    },
});
</script>

<style scoped>
.card {
    border: 1px solid rgb(50, 50, 50);
    background-color: rgb(25, 25, 25);
    border-radius: 8px;
    padding: 1em 0.5em;
}
.icon {
    text-align: center;
    stroke: rgb(216, 154, 46);
    color: rgb(216, 154, 46);
}

.header {
    font-weight: 700;
    font-size: 1.3em;
    text-align: center;
    color: rgb(200, 200, 200);
}

.body {
    font-weight: 400;
    font-size: 1.2em;
    text-align: center;
    color: rgb(250, 250, 250);
}
</style>
