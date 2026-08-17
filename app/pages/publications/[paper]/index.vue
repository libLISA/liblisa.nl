<script setup>
const route = useRoute();

definePageMeta({
  layout: 'paper',
})

const { data: currentPage } = await useAsyncData(`papers-${route.params.paper}`, () => 
  queryCollection('papers').path(`/publications/${route.params.paper}`).first()
)

const { data: children } = await useAsyncData(`papers-${route.params.paper}-children`, () => 
  queryCollection('papers')
    .where('path', 'LIKE', `/publications/${route.params.paper}/%`)
    .all()
)

useHead({
  title: currentPage.value.title
});
</script>

<template>
  <h1>
    {{ currentPage.title }}
  </h1>

  <div v-html="currentPage.html" />
  <ul>
    <li v-for="item in children">
      <NuxtLink :to="item.path">
        {{ item.title }}
      </NuxtLink>
    </li>
  </ul>

  <PublicationNavbar :is-index="true" :data="children[0]" />
</template>

<style scoped>
@import './nav.css';
</style>

<style>
.footnote {
  font-size: 75%;
}

.footnote::before {
  display: block;
  content: " ";
  border-top: 1px solid;
  padding-bottom: 10px;
  width: 20%;
  transform: translateX(-6px);
}
</style>