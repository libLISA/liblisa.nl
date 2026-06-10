<script setup>
const route = useRoute();

useHead({
  titleTemplate: (title) => {
    return title ?? 'libLISA'
  }
})
</script>

<template>
    <div class="header">
        <h1>libLISA - Automated CPU Instruction Discovery and Analysis</h1>
        <ul class="menu">
            <li><NuxtLink active-class="active" to="/">libLISA</NuxtLink></li>
            <li><NuxtLink active-class="active" to="/binary-tool-verification">Verification</NuxtLink></li>
            <li><NuxtLink active-class="active" to="/publications">Publications</NuxtLink></li>
            <!-- <li><NuxtLink active-class="active" to="/sem86">Sem86</NuxtLink></li> -->
        </ul>
    </div>
    <article class="page">
        <slot />
    </article>
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

.header h1 {
    margin: 0;
    padding: 0.4em 0.4em 0 0.4em;
}

.authors {
    margin: 8px;
}

.menu {
    display: flex;
    flex-direction: row;
    margin: 0;
    padding: 0;
    margin-top: 1em;
}

.menu li {
    list-style: none;
    color: #fff;
    margin: 0;
    padding: 0;
}

.menu li a {
    display: block;
    color: #fff;
    text-decoration: none;
    padding: 12px 32px 8px 32px;
    font-weight: 600;
    position: relative;
    min-width: 100px;
}

.menu li a.active::before {
    display: block;
    content: " ";
    position: absolute;
    left: 0;
    top: 0;

    width: 0;
    height: 0;
    border-bottom: 10px solid transparent;
    border-left: 10px solid var(--main-col); 
}

.menu li a.active {
    background-color: #fff;
    color: #226;
}

.page {
    max-width: 900px;
    margin: auto;
    padding: 0 1em;
    padding-bottom: 1em;
    line-height: 1.4;
    text-align: justify;
}

@media (max-width: 600px) {
  .menu {
    flex-direction: column;
    width: 100%;
  }

  .page {
    padding: 0 0.5em;
    text-align: left;
  }
}
</style>