<script setup>
import api from "./api";
import { ref, onMounted, onUnmounted } from "vue";
import "@/assets/styles/main.css";

const devmode = ref(false);
const visible = ref(false);

onMounted(() => {
  window.addEventListener("message", onMessage);
});

onUnmounted(() => {
  window.removeEventListener("message", onMessage);
});

const onMessage = (event) => {
  switch (event.data.type) {
    case "toggle":
      visible.value = event.data.visible;
      api
        .post("updatestate", {
          state: visible.value,
        })
        .catch((e) => {
          console.log(e.message);
        });
      break;
    default:
      break;
  }
};

const closeApp = () => {
  visible.value = false;
  api
    .post("updatestate", {
      state: visible.value,
    })
    .catch((e) => {
      console.log(e.message);
    });
};
</script>

<template>
  <div
    id="content"
    class="relative bg-gray-900 left-0 right-0 mx-auto px-10"
    v-if="visible || devmode"
  >
    <div class="absolute right-2 top-0 text-2xl text-white" @click="closeApp">
      &times;
    </div>
    <nav class="w-full text-center text-white">
      <router-link to="/">Home</router-link> |
      <router-link to="/about">About</router-link>
    </nav>
    <router-view />
  </div>
</template>

<style>
#content {
  width: 60vw;
  height: 70vh;
}
</style>
