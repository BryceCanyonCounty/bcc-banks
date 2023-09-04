<template>
    <div class="container">
        <div class="title">
            <h2>{{ title }}</h2>
        </div>
        <div class="body" v-if="message">{{ message }}</div>
    </div>
</template>

<script setup>
defineProps({
    message: {
        type: String,
        required: false,
    },
    title: {
        type: String,
        required: true,
    },
});
</script>

<style scoped>
.container {
    align-items: center;
    width: 100%;
    background-color: rgb(5, 5, 5);
    color: rgb(250, 250, 250);
    padding: 1em;
    border-radius: 10px;
    max-width: 10vw;
    min-width: 10vw;
}

.title {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-bottom: 1rem;
    font-size: 1.5em;
    font-family: 'crock';
    background: url('../assets/images/menu_header.png');
    background-position: center;
    background-size: 100% 100%;
    background-repeat: no-repeat;
    padding: 15px 20px;
}

.title h2 {
    margin: 0;
}

.body {
    text-align: center;
    margin: 1rem 0;
    font-size: 1.2em;
}
</style>
