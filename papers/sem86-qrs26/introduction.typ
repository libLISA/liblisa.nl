#import "../theme.typ": *

= Introduction
Malware often attempts to frustrate analysis by disabling itself when it detects that it is running inside an emulator~@sahin2018proteus @raffetseder2007detecting @choi2022emuid @chen2008towards @imulvmdetection.
Some emulator detection techniques make use of _undefined_ instruction behavior.
These outputs are unspecified in CPU reference manuals, and are often implemented differently on different CPU architectures and emulators.

Existing emulators~@qemu @bochs @gem5 do not accurately implement undefined behavior~@ma2009design @martignoni2009emufuzzer.
Most existing formal semantics~@x86isa @sail @strata @dasgupta simply mark such outputs as "undefined",
and do not provide specific implementations.
This leads to differences in behavior, which malware exploits to detect whether it is running inside an emulator.
Such differences are actively used by real-world malware.
For example, malware was encountered that uses the output of undefined flags from the #tt[IMUL] instruction to detect emulation~@imulvmdetection.

Since implementations of undefined behavior can differ between CPUs,
there exists no single "correct" semantics.
Ideally, an emulator would be able to easily switch between different semantics,
such that different CPU-specific semantics can be used.
In other words, we argue the need for an emulator that can accurately -- thus including undefined behavior -- emulate many different real-world CPUs.
Such an emulator should, e.g., run the Intel Celeron differently from the AMD Athlon even though they are both x86 architectures, as they implement undefined behavior differently.

Emulators usually hardcode semantics, which means that the emulator needs to be reprogrammed and then recompiled from source to change the semantics.
This is unfeasible if one wants to switch between many different semantics.

We present #sem86, an x86 emulator without hard-coded semantics.
Instead, semantics are provided to the emulator as data in an input file, which makes switching between different semantics trivial.
Instruction semantics are encoded in a simple format, that allows for conversion from and to other formats, such as SMT-LIB~@smtlib2.
All source code will be published under an open-source license upon acceptance of this paper.

Despite not having hard-coded semantics, #sem86 is $1.91 times$ as fast as Bochs and achieves 42.4% of QEMU's performance.
It implements all necessary hardware to boot real x86 operating systems that support Pentium 5-era hardware, such as Windows 98, Windows XP and Windows 7.
It also implements several optional hardware components for audio, high-resolution display output and internet access.

We construct a toy example that uses the IMUL instruction to detect emulation, and show that #sem86 emulates this program differently when provided with different semantics.
Additionally, #sem86 is able to _bisect_ execution of the program to identify at exactly which instruction this emulator detection takes place.

A key question then is where we can obtain CPU-specific semantics that include semantics even for undefined behavior.
To the best of our knowledge, the only source for such semantics is libLISA @liblisa.
That tool uses program synthesis to derive instruction semantics from a CPU, by running millions of observations per instruction.
They actually synthesize different undefined behavior for different x86-64 architectures.
The ideal setup then is to use libLISA to synthesize instruction semantics for a set of CPUs, and use #sem86 to obtain a trustworthy CPU-specific emulator for each of these.
Currently, we provide a handwritten set of semantics inspired by libLISA semantics, but in the near future we aim to replace these handwritten semantics with synthesized ones taken ad verbatim from libLISA.

As part of this work we discovered an emulation bug in Bochs.
This bug caused wrong instructions to be executed under specific conditions, due to insufficient cache invalidation.
We have reported this bug, which has since been fixed by the developers of Bochs.