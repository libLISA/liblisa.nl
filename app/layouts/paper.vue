<script setup>
const route = useRoute();
const { data: publication } = await useAsyncData(`publications-${route.params.paper}`, () => 
  queryCollection('publications').path(`/publications/${route.params.paper}`).first()
)

useHead({
  titleTemplate: (title) => {
    return `${title} - ${publication.value.title} - ${publication.value.authors}`
  }
})
</script>

<template>
  <div class="header">
    <p role="contentinfo">
      <strong>
        This is a web version of the paper
        <br />
        <NuxtLink :to="`/publications#${route.params.paper}`">'{{ publication.title }}'
        <br />
        by {{ publication.authors }}, first published at {{ publication.venue }}</NuxtLink>.
      </strong>
    </p>
    <nav role="navigation" class="buttonrow">
      <a class="button small purple" :href="publication.pdf">
        <Icon name="fa7-regular:file-pdf" class="glyph" />
        Download PDF
      </a>
      <NuxtLink class="button small green" to="/">
        <Icon name="fa7-regular:file-pdf" class="glyph" />
        Visit liblisa.nl
      </NuxtLink>
    </nav>
  </div>
  <main role="main" class="page">
    <article>
      <slot />
    </article>
  </main>
</template>

<style scoped>
a {
  color: #fff !important;
}

strong {
  padding: 0 1.5em 0 1.5em;
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

article {
  margin: 0;
  padding: 0;
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