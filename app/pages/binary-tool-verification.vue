<script setup>
import { faGithub } from '@fortawesome/free-brands-svg-icons';
import { faBug, faCheck, faInfoCircle } from '@fortawesome/free-solid-svg-icons';
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome';

useHead({
  title: 'Verifying Binary Analysis Tools with libLISA'
});

useSeoMeta({
  title: 'Verifying Binary Analysis Tools with libLISA',
  ogTitle: 'Verifying Binary Analysis Tools with libLISA',
  description: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. We can use these semantics to verify that binary analysis tools are implemented correctly.',
  ogDescription: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. We can use these semantics to verify that binary analysis tools are implemented correctly.',
  ogImage: 'https://liblisa.nl/logo.png',
  twitterCard: 'summary',
});

const { data } = await useAsyncData('pages', () =>
  queryCollection('binaryToolBugs').all()
)

console.log(data.value);
</script>

<template>
  <p>
    libLISA's automatically-inferred semantics can be used to verify the correctness of other implementations.
    In <NuxtLink to="/publications">our 2024 paper</NuxtLink>, we verified the correctness of Dasgupta et al.'s semantics implemented in the K framework.
    In the table below, you will find an overview of all bugs that we have found.
  </p>
  <table>
    <thead>
      <tr>
        <td></td>
        <td>Tool</td>
        <td>Bug description</td>
        <td></td>
      </tr>
    </thead>
    <tbody>
      <tr v-for="bug in data" :class="['status-' + bug.status]">
        <td>
          <FontAwesomeIcon :icon="faCheck" v-if="bug.status == 'fixed'" />
        </td>
        <td class="nowrap">
          {{ bug.tool }}
        </td>
        <td>
          {{ bug.title }}
          <button class="nobutton" :popovertarget="'popover-' + bug.stem">
            <FontAwesomeIcon :icon="faInfoCircle" />
          </button>

          <div :id="'popover-' + bug.stem" popover>
            <ContentRenderer :value="bug" />

            <div class="buttonrow">
              <button class="button small" :popovertarget="'popover-' + bug.stem" popovertargetaction="hide">
                Close
              </button>
            </div>
          </div>
        </td>
        <td>
          <a :href="bug.tracker" v-if="bug.tracker" rel="noopener" target="_blank">
            <FontAwesomeIcon :icon="faGithub" v-if="bug.tracker?.startsWith('https://github.com/')" />
            <FontAwesomeIcon :icon="faBug" v-else />
          </a>
        </td>
      </tr>
    </tbody>
  </table>
</template>

<style scoped>
* {
  --col-reported: #e9f0ff;
  --col-fixed: #eeffe9;
}

[popover] {
    padding: 1rem;
    border: none;
    margin: auto;
    max-width: 1000px;
}

::backdrop {
  background: rgb(0 0 0 / 50%);
}

.authors {
  font-size: 80%;
  margin-top: 0;
}

.nobutton {
  border: none;
  background: none;
  cursor: pointer;
  font: inherit;
  text-align: left;
  color: var(--main-col);
}

.status-reported {
  background: var(--col-reported);
}

.status-fixed {
  background: var(--col-fixed);
}
</style>