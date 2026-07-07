<script setup>
useHead({
  title: 'Sem86 - A full-system emulator without hardcoded semantics'
});

useSeoMeta({
  title: 'Sem86 - A full-system emulator without hardcoded semantics',
  ogTitle: 'Sem86 - A full-system emulator without hardcoded semantics',
  description: 'Sem86 is an x86 full-system emulator without hardcoded semantics. Instead, it loads instruction semantics at runtime from an input file.',
  ogDescription: 'Sem86 is an x86 full-system emulator without hardcoded semantics. Instead, it loads instruction semantics at runtime from an input file.',
  ogImage: 'https://liblisa.nl/logo.png',
  twitterCard: 'summary',
});
</script>

<template>
  <div class="imagelist">
    <img src="~/assets/images/sem86/w98-small.png" />
    <img src="~/assets/images/sem86/wxp-small.png" />
    <img src="~/assets/images/sem86/w7-small.png" />
  </div>

  <p>
    Sem86 is an x86 full-system emulator without hardcoded semantics. 
    Instead, it loads instruction semantics at runtime from an input file.
    This makes it very easy to switch between different semantics, in order to accurately emulate undefined behavior and undocumented instructions.
  </p>

  <p>
    Despite not having hardcoded semantics that a compiler can optimize at compile-time, and using LLVM instead of a bespoke performance-optimized JIT, Sem86 is not slow: it is 1.9&times; as fast as Bochs, and achieves ~42% of QEMU's performance.
  </p>

  <p>
    Sem86 will be presented at <a href="https://qrs26.techconf.org/">QRS'26</a>.
  </p>

  <div class="buttonrow">
    <!-- <a class="button green" href="files/sem86.pdf">
      <Icon name="fa7-regular:file-pdf" class="glyph" />
      Read the paper
    </a> -->
    <a class="button purple" target="_blank" href="https://github.com/liblisa/sem86">
      <Icon name="fa7-brands:github" class="glyph" />
      View source code
    </a>
  </div>

  <h2>Integration with libLISA</h2>
  <p>
    Our long-term goal for Sem86 is to use automatically inferred semantics from libLISA.
    This would enable "CPU cloning": analyzing a CPU, extracting its semantics, and then starting an emulator that emulates that exact CPU accurately. 
  </p>
  <p>
    Currently, Sem86 uses handwritten instruction semantics.
    This is because libLISA currently does not have CPU observers for 16-bit and 32-bit x86, and therefore does not have inferred semantics available.
    However, the semantics format that we use is very similar to libLISA's, and switching to automatically inferred semantics would not require big changes.
  </p>

  <h2>Malware Analysis</h2>
  <p>
    Emulation can be used to analyze malware in a sandboxed environment.
    There is, however, not a single instruction semantics to be followed, as x86 allows undefined behavior.
    Malware can abuse differences in implementations of undefined behavior to detect whether it is running in a sandboxed environment.
    Sem86 makes it easy to emulate specific undefined behavior and switch between different behavior.
  </p>
  <p>
    Sem86 can switch semantics mid-execution.
    This makes it possible to <i>bisect</i> instruction execution to determine at which point different semantics would diverge.
    We demonstrated this ability by constructing a toy malware example that exploits undefined instruction behavior to detect whether it is running in an emulator.
    Sem86 can bisect the execution of this malware, and identify the exact instruction that is used.
  </p>

  <h2>Hardware Support &amp; Operating Systems</h2>
  <p>
    Sem86 implements all hardware necessary to boot Windows and Linux operating systems that support Pentium 5 era hardware.
    It runs Windows 3.1, Windows 98, Windows XP, Windows 7 and Debian 8.
    Additionally, several optional hardware components are implemented: an ES1370 card for audio, high-resolution video output via VBE and an NE2k network card for internet access. 
  </p>
  
  <div class="twocolumn">
    <img src="~/assets/images/sem86/w7-small.png" />
    <p>
      Windows 7 runs, but the NE2k networking card has no Windows 7 driver. A newer networking card would need to be implemented to make this work.
      Additionally, as no GPU is implemented, Aero effects and transparency is not supported.
    </p>
  </div>

  <div class="twocolumn">
    <p>
      Sem86 also runs on Android phones.
      Here, Windows 7 is shown.
      However, the LLVM JIT backend may use a lot of memory during compilation.
      This can cause the emulator to crash on phones with only 8&nbsp;GiB RAM.
      Older operating systems, such as Windows 98 and XP,  tend to run better.
    </p>
    <img src="~/assets/images/sem86/w7-phone.png" />
  </div>
  
  <div class="twocolumn">
    <img src="~/assets/images/sem86/w98-small.png" />
    <p>
      Windows 98 runs well on Sem86, as Sem86 is able to match the performance of early-2000s CPUs.
      Games that run on Windows 98 and do not require a dedicated GPU, such as Rollercoaster Tycoon, also tend to run well.
      Additionally, Internet Explorer can be used to browse the internet.
      Unfortunately, many modern websites do not work as they require unsupported HTTPS encryption methods.
    </p>
  </div>
  
  <div class="twocolumn">
    <p>
      On Windows XP, the last supported version of Firefox runs and can open websites, including HTTPS websites.
      Unfortunately, in practice many modern sites tend to be too heavy for early-2000s CPUs.
    </p>
    <img src="~/assets/images/sem86/wxp-small.png" />
  </div>
</template>

<style scoped>
.twocolumn img {
  width: 300px;
  flex-shrink: 0;
  align-self: center;
}

.twocolumn {
  display: flex;
  margin: 2em 0;
  gap: 2em;
}

.twocolumn p {
  align-self: center;
  flex-shrink: 1;
}

.imagelist {
  box-sizing: border-box;
  display: flex;
  gap: 1em;
  width: 100%;
  margin-top: 1.5em;
}

.imagelist img {
  align-self: center;
  width: 100%;
  height: auto;
}
</style>