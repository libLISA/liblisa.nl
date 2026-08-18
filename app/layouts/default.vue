<script setup>
import Logo from "~/assets/liblisa-logo-white.svg";

useHead({
  titleTemplate: (title) => {
    return title ?? 'libLISA'
  }
})
</script>

<template>
  <header role="banner" class="header">
    <Logo class="logo" />
    <span class="subtext">
      Automated CPU Instruction Discovery and Analysis
    </span>
    <nav role="navigation" class="menu">
      <div class="tab"><NuxtLink active-class="active" to="/">libLISA</NuxtLink></div>
      <div class="tab"><NuxtLink active-class="active" to="/binary-tool-verification">Verification</NuxtLink></div>
      <div class="tab"><NuxtLink active-class="active" to="/sem86">Sem86</NuxtLink></div>
      <div class="tab"><NuxtLink active-class="active" to="/publications">Publications</NuxtLink></div>
    </nav>
  </header>
  <main role="main" class="page">
    <slot />
  </main>
</template>

<style scoped>
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

.menu {
  display: flex;
  flex-direction: row;
  margin: 0;
  padding: 0;
  margin-top: 1em;
}

.tab {
  color: #fff;
  margin: 0;
  padding: 0;
  flex-basis: 0;
}

.tab a {
  display: block;
  color: #fff;
  text-decoration: none;
  padding: 12px 32px 8px 32px;
  font-weight: 600;
  position: relative;
  min-width: 100px;
}

.tab a.active {
  clip-path: polygon(
    0 10px,
    10px 0,
    100% 0,
    100% 100%,
    0 100%
  )
}

.tab a.active {
  background-color: #fff;
  color: #226;
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
    flex-direction: row;
    flex-wrap: wrap;
    width: 100%;
    margin-top: 0.5em;
  }

  .tab {
    flex: 1 1 50%;
  }

  .subtext {
    display: none;
  }

  .logo {
    padding: 8px;
    height: 60px;
  }

  .page {
    padding: 0.5em;
    text-align: left;
  }
}
</style>