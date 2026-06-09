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

async function copyBibtex(bibtex) {
  const pre = event.currentTarget
  .closest('[popover]')
  ?.querySelector('pre')

  if (!pre) return

  const range = document.createRange()
  range.selectNodeContents(pre)

  const selection = window.getSelection()
  selection.removeAllRanges()
  selection.addRange(range)

  await navigator.clipboard.writeText(pre.textContent)
}
</script>

<template>
  <p>
      
  </p>
  <h3><i>"libLISA: Instruction Discovery and Analysis on x86-64"</i> at <a href="https://2024.splashcon.org/track/splash-2024-oopsla#event-overview" target="_blank">OOPSLA'24</a></h3>
  <p class="authors">
    Jos Craaijo, Freek Verbeek, Binoy Ravindran
  </p>

  <p>
Even though heavily researched, a full formal model of the x86-64 instruction set is still not available. We present libLISA, a tool for automated discovery and analysis of the ISA of a CPU. This produces the most extensive formal x86-64 model to date, with over 118000 different instruction groups. The process requires as little human specification as possible: specifically, we do not rely on a human-written (dis)assembler to dictate which instructions are executable on a given CPU, or what their in- and outputs are. The generated model is CPU-specific: behavior that is “undefined” is synthesized for the current machine. Producing models for five different x86-64 machines, we mutually compare them, discover undocumented instructions, and generate instruction sequences that are CPU-specific. Experimental evaluation shows that we enumerate virtually all instructions within scope, that the instructions’ semantics are correct w.r.t. existing work, and that we improve existing work by exposing bugs in their handwritten models.
  </p>

  <div class="buttonrow">
    <a class="button small green" href="files/liblisa2024.pdf">
      <FontAwesomeIcon :icon="faFilePdf" class="glyph" />
      Read the paper
    </a>
    <button class="button small yellow" popovertarget="cite-liblisa2024-popover">
      <FontAwesomeIcon :icon="faQuoteLeft" class="glyph" />
      Cite
    </button>
  </div>

  <div id="cite-liblisa2024-popover" popover>
      <pre>
@article{craaijo2024liblisa,
  title={liblisa: Instruction discovery and analysis on x86-64},
  author={Craaijo, Jos and Verbeek, Freek and Ravindran, Binoy},
  journal={Proceedings of the ACM on Programming Languages},
  volume={8},
  number={OOPSLA2},
  pages={333--361},
  year={2024},
  publisher={ACM New York, NY, USA}
}</pre>

    <div class="buttonrow">
      <button class="button small" @click="copyBibtex">
        Copy BibTeX
      </button>
      <button class="button small gray" popovertarget="cite-liblisa2024-popover" popovertargetaction="hide">
        Close
      </button>
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
</style>