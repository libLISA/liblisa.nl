import { defineContentConfig, defineCollection } from '@nuxt/content'
import { z } from 'zod'

export default defineContentConfig({
  collections: {
    binaryToolBugs: defineCollection({
      type: 'page',
      source: 'binary-tool-bugs/**/*.md',
      schema: z.object({
        tool: z.string(),
        tracker: z.string(),
        status: z.string()
      })
    }),
    publications: defineCollection({
      type: 'page',
      source: 'publications/**/*.md',
      schema: z.object({
        authors: z.string(),
        link: z.string(),
        pdf: z.string(),
        venue: z.string(),
        bibtex: z.string(),
        date: z.date(),
        slug: z.string()
      })
    })
  }
})