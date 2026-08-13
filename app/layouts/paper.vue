<script setup>
const route = useRoute();
const { data: publication } = await useAsyncData(`publications-${route.params.paper}`, () => 
  queryCollection('publications').path(`/publications/${route.params.paper}`).first()
)

useHead({
  titleTemplate: (title) => {
    return `${title} - ${publication.value.title} - published at ${publication.value.authors}`
  }
})
</script>

<template>
  <div class="header">
    <p>
      <strong>
        This is a web version of the paper <NuxtLink :to="`/publications#${route.params.paper}`">'{{ publication.title }}' by {{ publication.authors }}, first published at {{ publication.venue }}</NuxtLink>.
      </strong>
    </p>
    <div class="buttonrow">
      <a class="button small purple" :href="publication.pdf">
        <Icon name="fa7-regular:file-pdf" class="glyph" />
        Download PDF
      </a>
      <NuxtLink class="button small green" to="/">
        <Icon name="fa7-regular:file-pdf" class="glyph" />
        Visit liblisa.nl
      </NuxtLink>
    </div>
  </div>
  <article class="page">
    <slot />
  </article>
</template>

<style scoped>
a {
  color: #fff !important;
}

.header {
  background: var(--main-col);
  color: #ffffff;
  display: flex;
  align-items: center;
  flex-direction: column;
  text-align: center;
}

.logo {
  padding: 8px;
  height: 96.6px;
}

.subtext {
  font-size: 80%;
  font-weight: 600;
}

.page {
  max-width: 900px;
  margin: auto;
  padding: 1em;
  line-height: 1.4;
  text-align: justify;
}

@media (max-width: 600px) {
  .menu {
    flex-direction: column;
    width: 100%;
  }

  .page {
    padding: 0.5em;
    text-align: left;
  }
}
</style>