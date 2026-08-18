<script setup>
const route = useRoute();

const { data } = await useAsyncData(`papers-${route.params.paper}-${route.params.section}`, () => 
  queryCollection('papers').path(`/publications/${route.params.paper}/${route.params.section}`)
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
  <PublicationNavbar :data="data" />

  <div class="page-content" v-html="data.html" />

  <PublicationNavbar :data="data" />
</template>

<style scoped>
.page-content {
  margin-bottom: 2em;
}
</style>

<style>
svg {
  margin: auto;
}

figure {
  display: flex;
  flex-direction: column;
  align-items: center;
  margin: 1em 0;
  padding: 0.5em;
  padding-top: 1.5em;
}

figure img {
  width: 100% !important;
  height: auto !important;
  max-height: 400px;
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