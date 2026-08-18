#import "../theme.typ": *

= Related Work <encoding-analysis:sec:related-work>

There is existing work on _CPU fuzzing_ (finding instructions inconsistent with the CPU specification) and on _instruction variant synthesis_ (producing semantics from instruction variants).
Combining these efforts would require producing instruction variants from bitstrings.
That is not possible, as instruction variants are manually created top-down and cannot be reconstructed bottom-up from a CPU.
This is exactly the gap that this paper aims to fill: to recover _encodings_ from bitstrings, making them amenable to synthesis.


#paragraph[CPU fuzzing]
Sandsifter~@sandsifter introduced _tunneling_, a technique for efficiently scanning an instruction space.
By comparing the found instructions with a disassembler library, undocumented instructions can be identified.
This approach was later improved by UISFuzz~@uisfuzz and extended to RISC-V and ARM in iScanU~@iscanu.
These tools produce lists of instructions that disassemblers are unable to disassemble.
In order to determine what these instructions do, manual analysis is needed.

SiliFuzz~@serebryany2021silifuzz generates test cases by fuzzing CPU simulators or disassemblers, and then executes these test cases on large amounts of CPUs.
This allows it to leverage the semantic information encoded in CPU simulators or disassemblers to verify whether real CPUs are behaving correctly.
Martignoni et al.~@martignoni2009testing use a similar approach, but in the opposite direction. A real CPU is used as the ground truth, and compared against the behavior of emulators using fuzzing.
The Cascade~@solt2024cascade fuzzer relies on a similar idea.
It is a RISC-V fuzzer that generates valid, long, complex programs and uses these to verify the correctness of CPUs.

All the tools mentioned above, assume a correct (partial) specification of the CPU exists, and aim to verify whether a CPU conforms to this specification.
#libLISA, on the other hand, assumes no such specification exists, and attempts to infer the specification from the CPU behavior.

#paragraph[Instruction semantics]
There have been many attempts to obtain formal semantics for x86-64.
In this section we summarize related work and compare it to #libLISA (see @encoding-analysis:tbl:related-work-comparison).

#html-compatible-figure([
  #set align(center)
  #table(
      columns: (auto, auto, auto, auto, auto, auto),
      align: (x, y) => if x == 0 { left } else { center },
      table.header(
        [], [Goel], [CompCert], [Strata], [Dasgupta], [#libLISA], 
      ),
      [Automatic], [#n], [#n], [#y], [#n], [#y], 
      [Source of\ instructions], [Human], [Human], [Disassembler], [Disassembler],
      [Enumeration], [Source of\ semantics], [Human], [Human], [Synthesis], [Human#super[#sym.dagger]],
      [Synthesis], [CPU-specific], [#n], [#n], [#n#super[#sym.dagger.double]], [#n], [#y], 
      [SMTLib export], [#n], [#n], [#y], [#n], [#y],
      [Executable], [#y], [#y], [#y], [#y], [#y],
  )
], caption: [
    Comparison of related work. ($#sym.dagger$): Dasgupta et al. augment Strata's synthesized semantics with manually written semantics. ($#sym.dagger$): Strata overlays a manual specification of undefined behavior on the synthesized semantics to make them non-CPU-specific.
], label: <encoding-analysis:tbl:related-work-comparison>)

Goel et al. provide an x86-64 ACL2 model~@goel2014simulation which covers mainly one-byte and two-byte x86-64 instructions, consisting of roughly a third of all non-privileged instruction variants.
Morrisett et al.~@morrisett2012rocksalt developed a Coq model for a subset of 32-bit x86, which was used to implement a static analysis tool for Google's Native Client (NaCl).

The CompCert compiler~@compcert has a Coq model for x86-32 and x86-64, which is used to prove equivalence between C source code and the generated assembly.
It only defines semantics for the instruction variants and behavior used by the compiler.
For example, only the 32-bit and 64-bit variants of the #tt[CMP] mnemonic are specified, because the 8-bit and 16-bit variants are not used.
Similarly, the semantics of the flags for the #tt[SHL] instruction variants are not specified.


Godefroid and Taly~@godefroid2012 were the first to introduce automatic synthesis for CPU instruction semantics.
Using templates, they synthesized instruction semantics for 534 x86 (32-bit) ALU instruction outputs (a typical instruction might have 6 outputs: 1 main output and 5 flag updates).

Heule et al.~@strata used a more advanced program synthesis technique, STOKE~@stoke.
From the semantics of 58 base instructions, STOKE automatically synthesizes semantics for #num(1764) instruction variants.
It uses the #tt[x64asm] library as a source of instruction variants.
The semantics can be exported to standard SMTLib syntax~@smtlib2 using a tool provided by the authors.
#libLISA also provides tools to export semantics to SMTLib syntax.

STOKE supports both bitwise, integer and floating point instructions.
It excludes x87, MMX, cryptographic, system-level and string instructions.
#libLISA does not support synthesizing floating point operations, but does analyze all instructions with in-scope prefixes.

Dasgupta et al. manually extended the work of Strata, producing the semantics to all #num(3155) "non-deprecated" x86-64 instruction variants supported on the Haswell microarchitecture~@dasgupta2019.
This process took 8 man-months.
The semantics are specified in the K framework.
While it is possible to import SMTLib assertions for program verification, Dasgupta et al. do not provide a tool that can export the semantics to SMTLib format.
We discuss this in more detail in Section~@encoding-analysis:sec:dasgupta-comparison-approach.

For both Strata and Dasgupta et al., we present a comparative overview of the types of instructions for which they provide semantics in @encoding-analysis:tbl:related-work-scope-comparison.

#html-compatible-figure([
  #table(
    columns: (auto, auto, auto, auto),
    stroke: none,
    align: (x, y) => if x == 0 { left } else { center },
    table.header(
      [], [STRATA], [Dasgupta], [#libLISA],
    ),
    [Integer, bitwise, control flow], [#y], [#y], [#y],
    [Privileged instructions], [#n], [#n], [#n],
    [x87], [#n], [#n], [#n],
    [MMX], [#n], [#n], [#y],
    [String instructions], [#n], [#y], [#y#super[#sym.dagger]],
    [SSE/AVX (floating point)], [#y], [#y], [#n],
    [SSE/AVX (integer)], [#y], [#y], [#y],
  )
], caption: [
  Comparison of types of instructions with semantics covered by STRATA, Dasgupta et al. and #libLISA. ($#sym.dagger$): The #tt[REP] prefix is out-of-scope, but non-repeating string instructions are synthesized.
], label: <encoding-analysis:tbl:related-work-scope-comparison>)


For other architectures, such as ARM and RISC-V, complete formal models do exist.
SAIL~@sail contains formal semantics for ARM, RISC-V and CHERI-MIPS.
The ARM semantics have been derived from the ARM Specification Language~@asl, while the RISC-V and CHERI-MIPS semantics have been handwritten.
It would be interesting to implement #libLISA for these architectures and compare #libLISA's results against the formal models.

Formal models such as x86-TSO focus on defining concurrent memory accesses @sewell2010x86 @vsevvcik2013compcerttso.
While these models also include instruction semantics, their main contribution is the memory model itself.
The models are largely orthogonal to our work: x86-TSO relies on instruction semantics to determine what kinds of memory accesses an instruction performs.
The x86-TSO model only describes _observable_ memory ordering behavior of a CPU.
This suggests that libLISA could be expanded to generate semantics that define memory accesses in terms of x86-TSO's model.
