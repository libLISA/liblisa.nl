<script setup lang="ts">
const route = useRoute();

const { data } = await useAsyncData(`papers-${route.params.paper}-${route.params.section}`, () => 
  queryCollection('papers').path(`/publications/${route.params.paper}/${route.params.section}`)
    .first()
)

definePageMeta({
  layout: 'paper',
})

useHead({
  title: data.value!.title,
});

if (!data.value) {
  throw createError({
    status: 404
  })
}

const router = useRouter()

// This enables faster client-side navigation for the links in the content
function handleContentClick(event: MouseEvent) {
  const target = (event.target as HTMLElement).closest('a')
  if (!target) return

  const href = target.getAttribute('href')
  if (!href || !href.startsWith('/')) return

  event.preventDefault()
  router.push(href)
}

</script>

<template>
  <PublicationNavbar :data="data!" />

  <div class="page-content" v-html="data!.html" @click="handleContentClick" />

  <PublicationNavbar :data="data!" />
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
  overflow: auto;
}

figure > * {
  max-width: 100%;
  box-sizing: border-box;
}

figure pre {
  align-self: start;
}

figure img {
  width: 100% !important;
  height: auto !important;
  max-height: 400px;
}

h3, h4, h5 {
  width: 100%;
  display: inline-block;
  margin: 0;
}

li:target, li.is-target, figure:target, figure.is-target, h3:target, h3.is-target, h4:target, h4.is-target, h5:target, h5.is-target {
  animation: highlight-normal 1s ease-in-out;
  background-color: rgb(255, 255, 235);
  border: 1px solid #ccc;
  padding: 0.25em;
  box-sizing: border-box;
}

@keyframes highlight-normal {
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