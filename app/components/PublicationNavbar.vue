<script setup>
defineProps({
  data: Object,
  isIndex: Boolean,
})

const route = useRoute();
</script>

<template>
  <nav role="navigation" v-if="isIndex">
    <NuxtLink :to="`/publications/`" class="navbutton home prev">
      <Icon name="fa7-solid:caret-left" />
      Back to all publications

    </NuxtLink>
    <NuxtLink :to="data.path" class="navbutton next">{{ data.title }}</NuxtLink>
  </nav>
  <nav role="navigation" v-else>
    <NuxtLink v-if="data.previous" :to="data.previous.url" class="navbutton prev">{{ data.previous.title }}</NuxtLink>
    <NuxtLink v-else :to="`/publications/${route.params.paper}/`" class="navbutton prev">Abstract &amp; Table of Contents</NuxtLink>
    <NuxtLink v-if="data.next" :to="data.next.url" class="navbutton next">{{ data.next.title }}</NuxtLink>
    <NuxtLink v-else :to="`/publications/`" class="navbutton home next">
      <Icon name="fa7-solid:home" />
      Other publications

      <Icon name="fa7-solid:caret-right" />
    </NuxtLink>
  </nav>
</template>

<style scoped>

nav {
  display: flex;
  width: 100%;
}

.navbutton {
  cursor: pointer;
  background: var(--main-col);
  color: #fff !important;
  font-weight: bold;
  padding: 8px;
  text-justify: none;
}

.navbutton > * {
  vertical-align: center;
}

.navbutton:active {
  transform: translateY(3px);
}

.navbutton:hover {
  background: var(--main-col-highlight);
}

.home {
  background: none;
  color: #000 !important;
}

.home:hover {
  background: #ccc;
}

.prev {
  padding-left: 20px;
  margin-right: 2em;
  clip-path: polygon(
    20px 0,
    100% 0,
    100% 100%,
    20px 100%,
    0 50%
  );
}

.next {
  padding-right: 20px;
  margin-left: 2em;
  clip-path: polygon(
    calc(100% - 20px) 0,
    0 0,
    0 100%,
    calc(100% - 20px) 100%,
    100% 50%
  );
}

.next {
  margin-left: auto;
}
</style>