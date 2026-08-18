#import "../theme.typ": *

= Introduction <introduction>
A proper understanding of the microarchitectural behavior of the instructions that can be executed on a CPU is crucial for any effort related to binaries.
Binary verification, binary security analysis, binary patching, decompilation, and compiler construction/verification each require -- first and foremost -- a semantic model of each instruction that is executed by the binary.
Semantics are needed that are _trustworthy_, _executable_ and _complete_.

Even with all the research efforts that have been put into this topic~@dasgupta2019 @strata @compcert @goel2014simulation @hasabnis2016 @godefroid2012 @tsl, to this day there is no complete and trustworthy model of the x86-64 architecture.
This is caused by the sheer complexity of the x86-64 architecture: the informal specification found in Intel manuals is roughly #num(4700) pages, and even these are known to be not trustworthy~@strata.
Specifications of CPU architectures often rely heavily on manual work, which is error-prone and labor-intensive.
This situation becomes even more dire when taking into account that different x86-64 machines will behave differently: not only can they have different instruction sets, but behavior is also allowed to be undefined, in which case the same instruction has different behavior on different machines.

Accurate semantics must inherently be CPU-specific.
Consider for example the assembly program in @encoding-analysis:fig:ub-assembly.
Nowhere in the literature of the current state-of-the-art can semantics be found that accurately describe the behavior of this function.
This is because the value of the overflow flag after #tt[RCL] is undefined.
For example, on an AMD 3900X the code will execute the #tt[SYSCALL] when #tt[RAX] is #tt[0x80], while on an Intel Xeon Silver 4110 the #tt[SYSCALL] is never executed.
Existing semantics will either be undefined, or incorrect~(see @encoding-analysis:dasgupta-comparison-results).

#html-compatible-figure([
  ```asm
  f0:
      48 89 f8    mov    %rdi,%rax
      48 31 ff    xor    %rdi,%rdi
      c0 d0 09    rcl    $0x9,%al
      71 04       jno    40115f <skip>
      b0 3c       mov    $0x3c,%al
      0f 05       syscall
  skip:               
      c3          ret
  ```
], caption: [
  An example of a function in an x86-64 binary. For convenience, the output of the #tt("objdump") disassembler is listed next to the bytes. The function moves its first argument #tt("RDI") into #tt("RAX"), clears #tt("RDI") with an XOR, then performs a rotate-with-carry (#tt("rcl")) of 9 on #tt("RAX"), and finally conditionally jumps (#tt("jno")) to the end of the function if the overflow flag is unset, or executes a #tt("syscall") before returning otherwise.
], label: <encoding-analysis:fig:ub-assembly>)

In this paper we introduce #libLISA: a tool that can fully automatically scan a large part of the instruction space of an x86-64 CPU, discover instructions, and synthesize their semantics.
The result is _CPU-specific_ semantics, i.e., semantics that define what the current CPU actually does even in the case of instructions whose behavior is considered "undefined" by manually written specifications.
Both discovery and synthesis are completely automated.
We rely on as little human specification as possible.
Notably, we do not rely on a handwritten disassembler to dictate which bitstrings are valid instructions.

For each CPU, the entire space of possible executable bitstrings is grouped into _encodings_: bitstrings where certain bits are found to be indicating a certain _operand_.
A hypothetical example could be the encoding #tt[00#underline[a]1010#underline[aa]0] where the three #tt[#underline[a]] bits of the bitstring are found to be indicating an input register.
The intuition is that each encoding models a group of actual instructions (i.e., bitstrings) that each perform the same operation but on different operands.
Note that there is no relation between the concept of encodings (which are _derived_ bottom-up) and existing concepts such as mnemonics or instruction variants (which are _manually created_ top-down).
Subsequently, we try to synthesize semantics for each encoding.
The result is a partial _mapping from encodings to semantics_: partial, as synthesis may fail. 


We have run #libLISA on five different x86-64 CPU architectures.
This enumerates roughly #num(118000) encodings per architecture; this number differs based on which x86-64 extensions the CPU supports.
For roughly 88\% of all encodings we can synthesize semantics.
One run takes roughly three to four months.
We have exposed executable instructions that were _undocumented_ and synthesized their semantics: these are executable bitstrings that are not in the AMD and Intel manuals and that are unknown to both assemblers and disassemblers.
We mutually compare the five x86-64 machines by partitioning the set of encodings based on whether their semantics are equivalent.
This allows one to construct instruction sequences that behave differently on different architectures, e.g., that behave benign on an AMD Ryzen R9 3900X but behave maliciously on an Intel Core i9-13900.


Natural questions to ask are: "Did we find all executable instructions?" and "Are the generated semantics correct?"
We provide extensive evaluation of #libLISA's output in @encoding-analysis:sec:results, but it is important to note that there is no ground truth.
Instruction semantics are notoriously subtle, so even if we could manually check the semantics for over #num(100000) encodings, that kind of verification effort would in itself be highly error-prone and untrustworthy.
We therefore evaluate these questions relative to best-effort oracles (e.g., by enumerating all instructions in binaries such as #tt[ssh] and #tt[gcc]) and relative to the most extensive x86-64 specification currently available in related work~\cite{dasgupta2019}.
This shows that we find virtually all instructions in scope.


To the best of our knowledge, the work of Dasgupta et al. is the most extensive specification of x86-64 userspace instructions currently available~\cite{dasgupta2019}.
Their work is based on the earlier work of Heule et al.~@strata on Strata which provides a way to synthesize the semantics for #num(1795) instruction variants.
Dasgupta et al.\ manually extend this work to #num(3155) instruction variants, which required a manual effort of eight man-months~@dasgupta2019.
That set of instruction variants is not complete: #libLISA enumerates #num(11152) encodings that cannot be mapped to instruction variants from this set.
A mutual comparison between the semantics generated by #libLISA and their semantics exposed bugs: cases where their semantics did not represent what actually happens when instructions are executed on a CPU.
Moreover, there are notable differences:
1.) #libLISA is fully automated, 2.) #libLISA _discovers_ the instructions instead of leveraging a pre-existing set of instruction variants taken from a handwritten assembler, and 3.) #libLISA generates CPU-specific semantics.
A more thorough comparison to the state-of-the-art can be found in @encoding-analysis:sec:related-work.

We restrict the enumeration scope of our work to x86-64 userspace instructions.
We choose x86-64, as it is a complex and widely-used instruction set architecture with variable length instructions between 1 and 15 bytes.
Other modern architectures such as ARM or RISC-V have significantly simpler fixed-length or mostly fixed-length instructions.
Additionally, there is no complete and trustworthy model of the x86-64 architecture.

We restrict instruction prefixes to a limited set of allowed prefixes.
We do not analyze concurrency, memory ordering or timing behavior.
We also consider instructions using segment selectors and segment descriptors out-of-scope,
as well as instructions that produce an undefined instruction exception (e.g., #tt[UD]).
Note that an "undefined instruction exception" is not in any way related to an "instruction with undefined behavior".
In @encoding-analysis:subsec:scope we define a clear and unambiguous scope in more detail.

To summarize, this paper contributes:

  + a method for automated discovery and analysis of the ISA of a CPU;
  + an implementation of this method, called #libLISA, for CPUs implementing the x86-64 architecture; and
  + an extensive evaluation concerning completeness, correctness and the relation between the output of #libLISA and the state-of-the-art.