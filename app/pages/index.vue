<script setup>
useHead({
  title: 'libLISA - Automated CPU Instruction Discovery and Analysis'
});

useSeoMeta({
  title: 'libLISA - Automated CPU Instruction Discovery and Analysis',
  ogTitle: 'libLISA - Automated CPU Instruction Discovery and Analysis',
  description: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. The semantics are machine-readable and CPU-specific.',
  ogDescription: 'libLISA infers x86-64 instruction semantics automatically, through automated CPU analysis. The semantics are machine-readable and CPU-specific.',
  ogImage: 'https://liblisa.nl/logo.png',
  twitterCard: 'summary',
});
</script>

<template>
  <h1>CPU Instruction Discovery and Analysis</h1>
  <p>
    libLISA is a tool that can <i>fully automatically</i> scan instruction space, discover instructions and synthesize their semantics.
    It produces machine-readable, CPU-specific x86-64 instruction semantics.
    It relies on as little human specification as possible:
    specifically, it does not rely on a handwritten (dis)assembler to dictate which instructions are executable on a given CPU, or what their operands are.
  </p>

  <div class="buttonrow">
    <NuxtLink class="button green" to="/publications/liblisa-oopsla24/">
      <Icon name="fa7-solid:file-lines" class="glyph" />
      Read the paper
    </NuxtLink>
    <a class="button yellow" target="_blank" href="https://explore.liblisa.nl/">
      <Icon name="fa7-regular:map" class="glyph" />
      Explore the data
    </a>
    <a class="button purple" target="_blank" href="https://github.com/liblisa">
      <Icon name="fa7-brands:github" class="glyph" />
      View source code
    </a>
  </div>

  <h2 class="styled">Motivation</h2>
  <p>
    Even though heavily researched, a full formal model of the x86-64 instruction set is still not available.
    This is caused by the sheer complexity of the x86-64 architecture:
    the informal specification found in <a href="https://www.intel.com/content/www/us/en/developer/articles/technical/intel-sdm.html" target="_blank">Intel manuals is roughly 4700 pages</a>, and even these are known to be <a href="https://stefanheule.com/publications/pldi16-strata/" target="_blank">not</a> <a href="https://comsec.ethz.ch/research/hardware-design-security/rememberr/" target="_blank">trustworthy</a>.
  </p>
  <p>
    Specifications of CPU architectures often rely heavily on manual work, which is error-prone and labor-intensive.
    The current <a href="https://github.com/kframework/x86-64-semantics" target="_blank">state-of-the-art formal semantics</a> for x86-64 took 8 man-months to write, and even that specification still contains 34 errors (see Section 5.2 of our paper).
  </p>
  <p>
    This situation becomes even more dire when taking into account that different x86-64 machines will behave differently: not only can they have different instruction sets, but behavior is also allowed to be undefined, in which case the same instruction has different behavior on different machines.
  </p>
  <p>
    libLISA aims to solve this problem by using a CPU as the ground truth, and deriving semantics by observing instruction execution.
    It uses fuzzing and program synthesis to derive semantics automatically.
  </p>
  <p>
    One of the use-cases for libLISA's semantics is verification of other binary analysis tools.
    Errors in instruction semantics often propagate to the final output of a binary analyzer or emulator, making them behave incorrectly.
    Differences between actual CPU behavior and these tools pose a security risk: malware can abuse such differences to obfuscate its behavior, or evade analysis in controlled environments like emulators. 
  </p>
  <p>
    Our current focus is on using libLISA's automatically inferred semantics to <NuxtLink to="/binary-tool-verification">verify the correctness of disassemblers, emulators and other semantics</NuxtLink>.
  </p>

  <h2 class="styled">Generated x86-64 Instruction Semantics</h2>
  <p>
    We analyzed five different architectures: AMD 3900X, AMD 7700X, Intel i9-13900 (p), Intel i9-13900 (e) and Intel Xeon Silver 4110.
    For each architecture, we generated around 120k <i>encodings</i>.
  </p>
  <p>
    The semantics can be accessed in the following two ways:
  </p>
      
  <ul>
    <li>Use <a target="_blank" href="https://explore.liblisa.nl/">explore.liblisa.nl</a> to browse the semantics manually.</li>
    <li>Use the <a target="_blank" href="https://github.com/libLISA/liblisa/tree/main/cli/liblisa-semantics-tool"><code>liblisa-semantics-tool</code></a> or <a target="_blank" href="https://crates.io/crates/liblisa">the <code>liblisa</code> Rust crate</a> to use the semantics programmatically.</li>
  </ul>
  <p>
    The generated x86-64 semantics are CPU-specific.
    Around 90% of all encodings is identical on all 5 CPU architectures that we analyzed.
    The remaining 10% differs between architectures.
    We can broadly classify these differences into two categories: instruction set extensions and undefined behavior.
    Some x86-64 instruction set extensions, such as the <code>SHA1</code> instructions, are not implemented on all CPUs.
    There are also many differences in how undefined behavior is implemented across different x86-64 CPU architectures.
  </p>
  <p>
    An example of undefined behavior is the <a target="_blank" href="https://explore.liblisa.nl/instruction/0FAFC3"><code>IMUL</code> instruction</a>.
    The <a target="_blank" href="https://www.felixcloutier.com/x86/imul#flags-affected">reference manual</a> states: <i>"The SF, ZF, AF, and PF flags are undefined."</i>
    This means that the values of these flags can differ between CPU architectures, even if the instruction is provided with the same inputs.
    As can be seen <a target="_blank" href="https://explore.liblisa.nl/instruction/0FAFC3">in libLISA's semantics explorer</a>, The AMD 3900X and AMD 7700X do not modify these flags.
    The Intel i9-13900 (p) and Intel Xeon Silver 4110 compute the SF and PF correctly, and set the AF and ZF to 0.
    The Intel i9-13900 (e) additionally also computes the ZF flag correctly, and sets only the AF to 0.
  </p>
  <p>
    The AMD 3900X and AMD 7700X often share the same instruction semantics.
    This is likely because the AMD 7700X is a successor of the AMD 3900X.
    Similarly, the Intel i9-13900 (p) and Intel Xeon Silver 4110 often also share semantics, likely because the Intel i9-13900 (p) is also a successor of the Intel Xeon Silver 4110.
  </p>
</template>