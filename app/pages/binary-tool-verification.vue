<script setup>
import ProseH1ToH2 from '~/components/content/ProseH1ToH2.vue';

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

const { data } = await useAsyncData('binaryTools', () => 
  queryCollection('binaryToolBugs').all()
)

const sortedData = computed(() => {
  if (!data) {
    return data
  }
  
  const key = (bug) => {
    return {
      'fixed-by-us': 0,
      'fixed': 1,
      'patch-provided': 2,
      'working-on-patch': 3,
      'reported': 4,
    }[bug.status] ?? 99
  }

  return data.value.sort((a, b) => key(a) - key(b))
});
</script>

<template>
  <h1>Binary Tool Verification</h1>
  <p>
    The table below shows an overview of all {{ sortedData.length }} bugs we have found in other tools and semantics, during our work on libLISA.
    It includes 6 distinct bugs first listed in <NuxtLink to="/publications#liblisa-oopsla24">our 2024 paper</NuxtLink>, where we verified the correctness of Dasgupta et al.'s semantics implemented in the K framework.
    It also includes one bug in Bochs we found during development of <NuxtLink to="/sem86">Sem86</NuxtLink>,
    and several others found during the development of libLISA.
  </p>
  <div class="buglist">
    <div class="head">
      <div></div>
      <div>Tool</div>
      <div>Bug description</div>
      <div></div>
    </div>
    <div v-for="bug in sortedData" :class="['bug', 'status-' + bug.status]">
      <div class="status-icon">
        <Icon name="fa7-solid:check" v-if="bug.status == 'fixed' || bug.status == 'fixed-by-us'" />
        <Icon name="fa7-solid:hourglass-half" v-else-if="bug.status == 'patch-provided'" />
        <Icon name="fa7-solid:person-digging" v-else-if="bug.status == 'working-on-patch'" />
      </div>
      <div class="info">
        <div class="nowrap tool">
          {{ bug.tool }}
        </div>
        <div class="title">
          {{ bug.title }}
          <button class="nobutton" :popovertarget="'popover-' + bug.stem">
            <Icon name="fa7-solid:info-circle" />
          </button>

          <div :id="'popover-' + bug.stem" popover>
            <ContentRenderer :value="bug" :components="{ h1: ProseH1ToH2 }" />

            <div class="buttonrow">
              <button class="button small" :popovertarget="'popover-' + bug.stem" popovertargetaction="hide">
                Close
              </button>
            </div>
          </div>
        </div>
      </div>
      <a class="bugtracker-link" :href="bug.tracker" v-if="bug.tracker" rel="noopener" target="_blank">
        <Icon name="fa7-brands:github" v-if="bug.tracker?.startsWith('https://github.com/')" />
        <Icon name="fa7-solid:bug" v-else />
      </a>
    </div>
  </div>
  <div class="legend">
    <div class="item">
      <div class="box status-reported"></div>
      <div>Bug reported, awaiting reply</div>
    </div>
    <div class="item">
      <div class="box status-working-on-patch">
        <Icon name="fa7-solid:person-digging" />
      </div>
      <div>We intend to submit a patch for this bug</div>
    </div>
    <div class="item">
      <div class="box status-patch-provided">
        <Icon name="fa7-solid:hourglass-half" />
      </div>
      <div>Patch awaiting review</div>
    </div>
    <div class="item">
      <div class="box status-fixed">
        <Icon name="fa7-solid:check" />
      </div>
      <div>Fixed</div>
    </div>
  </div>
</template>

<style scoped>
.buglist {
  border: 1px solid #999;
  width: 100%;
  text-align: left;
  margin: 2em 0;
  display: grid;
  grid-template-columns: auto auto 1fr auto;
}

.buglist .head {
  background: var(--main-col);
  color: #FFF;
  font-weight: 600;
  display: grid;
  grid-column: 1 / span 4;
  grid-template-columns: subgrid;
}

.buglist .bug {
  display: grid;
  grid-column: 1 / span 4;
  grid-template-columns: subgrid;
}

.buglist .bug .info {
  display: grid;
  grid-column: span 2;
  grid-template-columns: subgrid;
  padding-left: 0;
  padding-right: 0;
}

.status-icon, .bugtracker-link {
  align-self: center;
  justify-self: center;
  display: flex;
}

.buglist .head > *, .buglist .bug > * {
  padding: 8px;
}

.buglist .bug .info > * {
  margin-left: 8px;
  margin-right: 8px;
}

@media only screen and (max-width: 840px) {
  .buglist {
    row-gap: 16px;
  }
  
  .buglist .head {
    display: none;
  }

  .buglist .bug .info {
    grid-template-rows: subgrid;
    grid-row: span 2;
  }

  .buglist .bug .info > * {
    margin-left: 0;
    margin-right: 0;
  }

  .tool {
    font-size: 10pt;
    font-weight: 600;
  }

  .title {
    overflow-wrap: anywhere;
  }

  .status-icon, .bugtracker-link {
    grid-row: span 2;
  }

  .buglist .bug .info > * {
    grid-column: span 2;
  }
}

* {
  --col-reported: #eff4ff;
  --col-working-on-patch: #e1eaff;
  --col-fixed: #bbe9a9;
  --col-patch-provided: #eeffe7;
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
  display: inline-flex;
  vertical-align: center;
}

.status-reported {
  background: var(--col-reported);
}

.status-fixed, .status-fixed-by-us {
  background: var(--col-fixed);
}

.status-working-on-patch {
  background: var(--col-working-on-patch);
}

.status-working-on-patch .status-icon svg, .status-patch-provided .status-icon svg {
  opacity: 0.6;
}

.status-patch-provided {
  background: var(--col-patch-provided);
}

.legend {
  display: flex;
  flex-wrap: wrap;
  gap: 1em;
  font-size: 60%;
}

.legend .item {
  margin: 8px;
  display: flex;
  align-items: center;
  justify-items: center;
  gap: 0.5em;
  white-space: nowrap;
}

.box {
  border: 1px solid #333;
  aspect-ratio: 1;
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
}

.iconify {
  width: 1.25em;
  height: 1.25em;
}
</style>