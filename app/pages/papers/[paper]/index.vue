<script setup>
const route = useRoute();

definePageMeta({
  layout: 'paper',
})

const { data: currentPage } = await useAsyncData(`papers-${route.params.paper}`, () => 
  queryCollection('papers').path(`/papers/${route.params.paper}`).first()
)

const { data: children } = await useAsyncData(`papers-${route.params.paper}-children`, () => 
  queryCollection('papers')
    .where('path', 'LIKE', `/papers/${route.params.paper}/%`)
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
</template>