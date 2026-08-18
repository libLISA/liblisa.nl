<script setup lang="ts">
const route = useRoute()
const router = useRouter();
let previousEl: Element | null = null

// When Nuxt opens a different page, it doesn't necessarily trigger a page load.
// If no page load is triggered, the :target doesn't get applied.
// To fix this, we use some JS to apply an 'is-target' class to the target.
// Everything should still work without JS, because in that case a full page load is always used.
const updateTarget = async () => {
  document
    .querySelectorAll('.is-target')
    .forEach(el => el.classList.remove('is-target'))

  previousEl?.classList.remove('is-target')
  previousEl = null

  if (!route.hash) return

  await nextTick()

  const id = route.hash.slice(1)
  const el = document.getElementById(id)

  el?.classList.add('is-target');
  previousEl = el;
}

router.afterEach(() => {
  updateTarget()
});

onMounted(() => {
  updateTarget()
});

watch(() => route.hash, updateTarget);
</script>

<template>
  <div>
      <NuxtLayout>
        <NuxtPage />
      </NuxtLayout>
  </div>
</template>

<style>
:root {
  --main-col: #1c5dcf;
  --main-col-highlight: #2e79fb;
  --main-col-dark: #0c259d;

  --green: #16bb00;
  --green-highlight: #4dd60e;

  --yellow: #f3c200;
  --yellow-highlight: #f8cd23;

  --purple: #991ef7;
  --purple-highlight: #be38ee;

  --gray: #8a8a8a;
  --gray-highlight: #afafaf;
}

html,
body {
  height: 100%;
  margin: 0;
  padding: 0;
  background: #ffffff;
  color: #2c3e50;
  font-family: sans-serif;
  font-size: 14pt;

  box-sizing: border-box;
}

table {
  border: 1px solid #999;
  text-align: left;
  gap: none;
  border-spacing: none;
  border-collapse: collapse;
  margin: auto;
  background: #FFF;
}

thead {
  background: var(--main-col);
  color: #FFF;
}

td, th {
  padding: 6px 8px;
}

code {
  background: #eee;
  border: 1px solid #ccc;
  padding: 1px 4px;
}

thead code {
  background: none;
  border: none;
  padding: 0;
}

a[href]:hover code {
  background: #999;
  color: #fff;
}

h1.styled, h2.styled, h3.styled, h4.styled, h5.styled {
  display: block;
  background: var(--main-col);
  color: white;
  padding: 4px 20px;
  margin-top: 1em;
  text-align: left;
}

h1.styled {
  font-size: 1.5em;
}

h1.styled, h2.styled, h3.styled, h4.styled, h5.styled, .button {
  clip-path: polygon(
    0 10px,
    10px 0,
    100% 0,
    100% 100%,
    0 100%
  )
}

.buttonrow {
  display: flex;
  padding: 8px 0px;
}

.button, .button:visited, .button:hover {
  position: relative;

  flex-grow: 1;
  flex-basis: 0;
  display: block;
  background: var(--main-col);
  padding: 1em 10px;
  color: white !important;
  text-decoration: none;
  font-weight: 700;
  font-size: 18pt;
  margin: 4px;
  border: none;

  display: flex;
  text-align: center;
  align-items: center;
  align-content: center;
  justify-items: center;
  justify-content: center;

  text-wrap: nowrap;
  text-shadow: 0px 0px 4px rgba(0 0 0 / 30%);
}

.button:active {
  transform: translateY(2px);
}

.button.small {
  padding: .3em 10px;
  font-size: 14pt;
}

.button:hover {
  background: var(--main-col-highlight);
  cursor: pointer;
}

.button.green { background: var(--green); }
.button.green:hover { background: var(--green-highlight); }

.button.yellow { background: var(--yellow); }
.button.yellow:hover { background: var(--yellow-highlight); }

.button.purple { background: var(--purple); }
.button.purple:hover { background: var(--purple-highlight); }

.button.gray { background: var(--gray); }
.button.gray:hover { background: var(--gray-highlight); }

@media only screen and (max-width: 840px) {
  .buttonrow {
    flex-direction: column;
  }

  .button {
    padding: .5em 10px;
  }
}

pre {
  background: #eee;
  border: 1px solid #bbb;
  padding: 0.5em;
}

code {
  background: #eee;
  padding: 0 6px;
  border: 1px solid #ccc;
}

pre code {
  border: none;
  padding: 0;
}

.nowrap {
  white-space: nowrap;
}

a[href] {
  color: var(--main-col-dark);
  text-decoration-style: dotted;
}

a[href]:hover {
  color: var(--main-col-highlight);
  text-decoration-style: solid;
}

a[href]:visited {
  color: var(--main-col);
}

.glyph {
  width: 1.25em;
  height: 1.25em;
  display: inline;
  margin: 0 8px;
}
</style>