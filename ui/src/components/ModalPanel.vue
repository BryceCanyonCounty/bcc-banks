<script setup>
defineProps({
    visible: {
        type: Boolean,
        required: true,
    },
    title: {
        type: String,
        default: 'Modal Title',
    },
});

const close = () => {
    this.$emit('update:visible', false);
};
</script>

<template>
    <div class="modal-wrapper" v-if="visible">
        <div class="modal-overlay" @click="close"></div>
        <div class="modal">
            <div class="modal-header">
                <span class="text-gray-200">{{ title }}</span>
            </div>
            <div class="modal-body">
                <slot></slot>
            </div>
        </div>
    </div>
</template>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<style scoped>
.modal-wrapper {
    position: fixed;
    z-index: 9999;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    display: flex;
    justify-content: center;
    align-items: center;
}

.modal-overlay {
    position: absolute;
    z-index: -1;
    top: 0;
    left: 0;
    right: 0;
    bottom: 0;
    background-color: rgba(0, 0, 0, 0.5);
}

.modal {
    position: relative;
    z-index: 1;
    width: 80%;
    max-width: 35em;
    min-height: 20em;
    padding: 1rem;
    background: url('../assets/images/bgPanel.png');
    background-size: 100% 100%;
    border-radius: 0.5rem;
}

.modal-header {
    display: flex;
    justify-content: center;
    align-items: center;
    margin-bottom: 1rem;
    font-family: 'crock';
    font-size: 1.5em;
    background: url('../assets/images/menu_header.png');
    background-position: center;
    background-size: 100% 100%;
    background-repeat: no-repeat;
    padding: 15px 20px;
    min-height: 5em;
}

.modal-header h2 {
    margin: 0;
}

.modal-close {
    border: none;
    background-color: transparent;
    font-size: 2rem;
}

.modal-body {
    margin: 1rem 0;
}
</style>
