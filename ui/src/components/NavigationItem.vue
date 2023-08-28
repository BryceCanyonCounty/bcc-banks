<script setup>
const props = defineProps({
  label: String,
  route: String,
  active: {
    type: Boolean,
    default: false,
  },
  id: {
    type: Number,
    required: false,
  },
});
</script>

<template>
  <div>
    <RouterLink :to="{ name: route, params: { id: id } }">
      <div
        class="text-gray-100 py-2 w-full text-center border-y border-1 border-gray-800 nav-item"
        :class="{
          navItemActive: props.active,
        }"
      >
        {{ label }}
      </div>
    </RouterLink>
  </div>
</template>

<style scoped>
.nav-item {
  background-color: rgb(30, 30, 30);
}

.navItemActive {
  background-color: rgb(70, 70, 70);
}

.nav-item:hover {
  background-color: rgb(70, 70, 70);
}
</style>
