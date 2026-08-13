<script setup>
const route = useRoute();

const { data } = await useAsyncData(`papers-${route.params.paper}-${route.params.section}`, () => 
  queryCollection('papers').path(`/papers/${route.params.paper}/${route.params.section}`)
    .first()
)

definePageMeta({
  layout: 'paper',
})

useHead({
  title: data.value.title,
});

if (!data.value) {
  throw createError({
    status: 404
  })
}
</script>

<template>
  <nav>
    <NuxtLink v-if="data.previous" :to="`/papers/${route.params.paper}/${data.previous.url}`" class="navbutton prev">Previous Section: {{ data.previous.title }}</NuxtLink>
    <NuxtLink v-if="data.next" :to="`/papers/${route.params.paper}/${data.next.url}`" class="navbutton next">Next Section: {{ data.next.title }}</NuxtLink>
  </nav>

  <div v-html="data.html" />

  <nav>
    <NuxtLink v-if="data.previous" :to="`/papers/${route.params.paper}/${data.previous.url}`" class="navbutton prev">Previous Section: {{ data.previous.title }}</NuxtLink>
    <NuxtLink v-if="data.next" :to="`/papers/${route.params.paper}/${data.next.url}`" class="navbutton next">Next Section: {{ data.next.title }}</NuxtLink>
  </nav>
</template>

<style>
svg {
  margin: auto;
}

nav {
  display: flex;
  width: 100%;
}

.navbutton {
  cursor: pointer;
  background: var(--main-col);
  color: #fff !important;
  font-weight: bold;
  padding: 8px;
  text-justify: none;
}

.navbutton:active {
  transform: translateY(3px);
}

.navbutton:hover {
  background: var(--main-col-highlight);
}

.prev {
  padding-left: 20px;
  margin-right: 2em;
  clip-path: polygon(
    20px 0,
    100% 0,
    100% 100%,
    20px 100%,
    0 50%
  );
}

.next {
  padding-right: 20px;
  margin-left: 2em;
  clip-path: polygon(
    calc(100% - 20px) 0,
    0 0,
    0 100%,
    calc(100% - 20px) 100%,
    100% 50%
  );
}

.next {
  margin-left: auto;
}

li:target, figure:target, h1:target, h2:target, h3:target {
  animation: highlight 1s ease-in-out;
  background-color: rgb(255, 255, 235);
  border: 1px solid #ccc;
}

@keyframes highlight {
  from {
    background-color: transparent;
  }
  50% {
    background-color: rgb(255, 255, 147);
  }
  to {
    background-color: rgb(255, 255, 235);
  }
}
</style>