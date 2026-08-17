---
slug: "liblisa-oopsla24"
title: "libLISA: Instruction Discovery and Analysis on x86-64"
venue: "OOPSLA'24"
link: "https://2024.splashcon.org/track/splash-2024-oopsla#event-overview"
authors: "Jos Craaijo, Freek Verbeek, Binoy Ravindran"
pdf: "/files/liblisa2024.pdf"
date: 2024-10-20
bibtex: |
  @article{craaijo2024liblisa,
    author = {Craaijo, Jos and Verbeek, Freek and Ravindran, Binoy},
    title = {libLISA: Instruction Discovery and Analysis on x86-64},
    year = {2024},
    issue_date = {October 2024},
    publisher = {Association for Computing Machinery},
    address = {New York, NY, USA},
    volume = {8},
    number = {OOPSLA2},
    url = {https://doi.org/10.1145/3689723},
    doi = {10.1145/3689723},
    journal = {Proc. ACM Program. Lang.},
    month = oct,
    articleno = {283},
    numpages = {29},
    keywords = {instruction semantics, instruction enumeration, synthesis}
  }
---

Even though heavily researched, a full formal model of the x86-64 instruction set is still not available. We present libLISA, a tool for automated discovery and analysis of the ISA of a CPU. This produces the most extensive formal x86-64 model to date, with over 118000 different instruction groups. The process requires as little human specification as possible: specifically, we do not rely on a human-written (dis)assembler to dictate which instructions are executable on a given CPU, or what their in- and outputs are. The generated model is CPU-specific: behavior that is “undefined” is synthesized for the current machine. Producing models for five different x86-64 machines, we mutually compare them, discover undocumented instructions, and generate instruction sequences that are CPU-specific. Experimental evaluation shows that we enumerate virtually all instructions within scope, that the instructions’ semantics are correct w.r.t. existing work, and that we improve existing work by exposing bugs in their handwritten models.
