<script setup>
useHead({
  title: 'Publications - libLISA'
});

useSeoMeta({
  title: 'Publications - libLISA',
  ogTitle: 'Publications - libLISA',
  description: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. The semantics are machine-readable and CPU-specific.',
  ogDescription: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. The semantics are machine-readable and CPU-specific.',
  ogImage: 'https://liblisa.nl/logo.png',
  twitterCard: 'summary',
});

const { data } = await useAsyncData('publications', () => 
  queryCollection('publications')
    .order('date', 'DESC')
    .all()
)

async function copyBibtex(bibtex) {
  await navigator.clipboard.writeText(bibtex)
}

// When Nuxt opens a different page, it doesn't necessarily trigger a page load.
// If no page load is triggered, the :target doesn't get applied.
// To fix this, we use some JS.
// Everything should still work without JS, because in that case a full page load is always used.
const route = useRoute()
const isActive = (id) => route.hash === `#${id}`
</script>

<template>
  <div class="publications">
    <div class="publication" v-for="publication in data">
      <a :id="publication.slug" :class="{ ['target']: isActive(publication.slug) }" />
      <h3>
        <i>"{{ publication.title }}"</i> 
        at 
        <a :href="publication.link" target="_blank">{{ publication.venue }}</a>
      </h3>
      <p class="authors">
        {{ publication.authors }}
      </p>

      <div class="awards" v-if="publication.awards">
        <a class="award" :href="award.url" target="_blank" v-for="award in publication.awards">
          <Icon name="fa7-solid:trophy" style="vertical-align: center;" /> {{ award.name }}
        </a>
      </div>

      <ContentRenderer :value="publication" />

      <div class="buttonrow">
        <NuxtLink v-if="publication.pdf" class="button small green" :to="`/publications/${publication.slug}/`">
          <Icon name="fa7-solid:file-lines" class="glyph" />
          Read the paper
        </NuxtLink>
        <button v-if="publication.bibtex"  class="button small yellow" :popovertarget="'cite-popover-' + publication.slug">
          <Icon name="fa7-solid:quote-left" class="glyph" />
          Cite
        </button>
      </div>

      <div :id="'cite-popover-' + publication.slug" popover>
        <pre>{{ publication.bibtex }}</pre>

        <div class="buttonrow">
          <button class="button small" @click="copyBibtex(publication.bibtex)">
            Copy BibTeX
          </button>
          <button class="button small gray" :popovertarget="'cite-popover-' + publication.slug" popovertargetaction="hide">
            Close
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
[popover] {
    padding: 1rem;
    border: none;
}

::backdrop {
  background: rgb(0 0 0 / 50%);
}

h3 {
  font-size: 17pt;
}

.authors {
  font-size: 80%;
  margin-top: 0;
}

.publications {
  display: grid;
  margin-top: 1em;
  gap: 4em;
}

.publication {
  padding: 20px;
  margin: -20px;
}

.publication:has(a:target), .publication:has(a.target) {
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

.awards {
  display: flex;
}

.award {
  padding: 6px 20px;
  background: var(--main-col);
  font-weight: 600;
  border-radius: 1em;
  color: #fff;
  text-decoration: none;
}

.award:visited {
  background: var(--main-col);
  color: #fff;
}

.award:hover {
  background: var(--main-col-highlight);
  color: #fff;
}
</style>