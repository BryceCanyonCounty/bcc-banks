<script setup>
// To access props within the setup tag add const props = defineProps
defineProps({
  msg: String,
});
// You can then access the props values like so
// console.log(props.msg)
</script>

<template>
  <div class="text-gray-200">
    <h1 class="text-xl font-bold mb-1">{{ msg }}</h1>
    <p class="text-justify">
      This is a full-fledge Vue 3 + NUI boilerplate to get you developing
      beautiful and responsive UI's in no time!
    </p>

    <h3 class="text-lg font-semibold mt-5 mb-1">Features</h3>
    
    <p>
      <ol class="list-decimal">
        <li>
          TRUE Hot Middle Reload (No need to restart scripts to see your changes)
        </li>
        <li>
          Page Routing via
          <a href="https://router.vuejs.org" target="_blank" rel="noopener"
            >vue-router</a
          >
        </li>
        <li>
          State Management via
          <a href="https://pinia.vuejs.org" target="_blank" rel="noopener"
            >Pinia</a
          >
        </li>
        <li>
          Web Bundled<a
            href="https://webpack.js.org/"
            target="_blank"
            rel="noopener"
            >webpack</a
          >
        </li>
        <li>
          ES6 Ready via<a
            href="https://babeljs.io/"
            target="_blank"
            rel="noopener"
            >babel</a
          >
        </li>
        <li>
          Expansive, modern http requests via
          <a
            href="https://axios-http.com/docs/intro"
            target="_blank"
            rel="noopener"
            >axios</a
          >
        </li>
        <li>
          Modern CSS Framework via
          <a href="https://tailwindcss.com/">Tailwind CSS</a>
        </li>
        <li>Auto build releases via GitHub Actions (See Readme)</li>
      </ol>
    </p>
  </div>
</template>

<style scoped></style>
