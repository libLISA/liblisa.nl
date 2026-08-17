---
slug: "sem86-qrs26"
title: "Sem86: A Full-System Emulator Without Hard-Coded Semantics"
venue: "QRS'26"
link: "https://qrs26.techconf.org/"
authors: "Jos Craaijo, Freek Verbeek, Binoy Ravindran"
pdf: "/files/sem86.pdf"
date: 2026-07-22
bibtex: ""
awards:
  - name: Best Presentation Award
    url: "https://qrs26.techconf.org/track/award_presentation"
---

Emulation can be used to run legacy software, analyze malware in a sandboxed environment, or run software compiled for different architectures.
An emulator is based on instruction semantics.
There is, however, not a single instruction semantics to be followed, as x86 allows undefined behavior.
In order to make accurate CPU-specific emulators,
we argue the need for an emulator that can easily switch between different semantics.
However, all existing emulators contain hard-coded semantics.
We present Sem86, an x86 emulator that loads semantics at runtime from data in an input file.
We implement all necessary hardware needed to emulate typical x86 operating systems such as Windows 98, Windows XP and Windows 7.
Additionally, we implement a sound card, network card and support for high-resolution display output.
Sem86 can automatically *bisect* instruction execution to determine at which point different semantics would diverge.
We demonstrate this by constructing a toy malware example that exploits undefined instruction behavior to detect whether it is running in an emulator,
and show that Sem86 can pinpoint the exact instruction that is used.