<script setup>
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';
import { faFilePdf } from '@fortawesome/free-regular-svg-icons';
import { faQuoteLeft } from '@fortawesome/free-solid-svg-icons';

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

      <ContentRenderer :value="publication" />

      <div class="buttonrow">
        <a class="button small green" :href="publication.pdf">
          <FontAwesomeIcon :icon="faFilePdf" class="glyph" />
          Read the paper
        </a>
        <button class="button small yellow" :popovertarget="'cite-popover-' + publication.slug">
          <FontAwesomeIcon :icon="faQuoteLeft" class="glyph" />
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
</style>