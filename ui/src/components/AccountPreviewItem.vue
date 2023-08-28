<script setup>
const props = defineProps({
  accountName: String,
  cash: Number,
  gold: Number,
  owner: {
    type: String,
    default: ''
  },
  authorizedUsers: {
    type: Array,
    default: null
  },
});
</script>

<template>
  <div class="text-gray-900 px-3 text-center item">
    <div class="text-lg font-semibold underline">{{ accountName }}</div>
    <div>
      <span class="font-semibold">Cash:</span> {{ cash }}</div>
    <div>
      <span class="font-semibold">Gold:</span> {{ gold }}</div>
    <div>
      <p>
        <span class="font-semibold">Owner:</span> {{ owner }}
    </p>
      <p>
      <span class="font-semibold" v-if="authorizedUsers">Authorized Users:</span>
      <ul>
        <li v-for="user in authorizedUsers" :key="user.id">{{ user.name }} - {{ user.level }}</li>
      </ul>
    </p>
    </div>
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
