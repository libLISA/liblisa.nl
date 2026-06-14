// https://nuxt.com/docs/api/configuration/nuxt-config
export default defineNuxtConfig({
  compatibilityDate: '2025-07-15',
  devtools: { enabled: true },
  css: ['~/assets/css/global.css'],
  modules: ['@nuxt/content', '@nuxt/icon'],
  app: {
    head: {
      htmlAttrs: {
        lang: 'en'
      }
    }
  },
  icon: {
    clientBundle: {
      scan: true,
    }
  }
})
