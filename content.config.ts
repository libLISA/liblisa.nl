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
    })
  }
})