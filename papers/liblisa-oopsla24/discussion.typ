#import "../theme.typ": *

= Discussion

We presented #libLISA, a tool for automated discovery of instructions executable on a given CPU, as well as synthesis of their semantics.
At its core, #libLISA is based on fuzzing, which means that synthesis may produce incorrect semantics for an instruction.
We evaluate that this happens for about three to seven instruction variants per run.
This could be reduced by increasing the amount of random inputs that are generated, or by changing the distribution of the random numbers that are generated such that the rare cases are more observable.
However, it is difficult to do this in a way that generalizes to any instruction.
We argue that this is inherent to bottom-up derivation of instruction sets and their semantics.
Without access to an oracle that provides a trustworthy and formal semantics of the entire instruction set of a CPU, #libLISA provides the most extensive and trustworthy formalization of the x86-64 ISAs to date.


Trustworthy semantics are the base of any binary-level effort.
For example, BAP~@bap (Binary Analysis Platform) has -- for the x86 architecture -- a manually written translation from instructions into an intermediate language.
They test their semantics against a CPU.
It would be interesting to combine #libLISA's semantics with BAP, reducing the trusted code base.



We believe #libLISA's approach would work on other modern general-purpose CPU architectures.
Only the CPU observer is architecture-specific, and would have to be implemented from scratch for a new architecture.
Architectures such as ARM or RISC-V would be suitable candidates.
With these architectures, a bit in an instruction often also serves a single purpose.


We ran our analysis on an Intel i9-13900 CPU, which was affected by the Reptar bug.#footnote[#link("https://lock.cmpxchg8b.com/reptar.html")]
Unfortunately, the #tt[REP] prefix is part of the instruction prefixes we consider out of scope (see Section~@encoding-analysis:subsec:scope).
We argue that #libLISA would have discovered this bug if the #tt[REP] prefix was considered in-scope.
The main characteristic of this bug is that it causes non-deterministic output.
This would be picked up upon during dataflow analysis, where the entire CPU state would be considered input.
Such instructions (e.g., #tt[RDTSC] or #tt[RDRAND]) are flagged automatically because synthesis is known to fail.


In @encoding-analysis:tab:relative_compare, there are around ten fewer disagreements with Dasgupta et al. on Intel CPUs than on AMD CPUs.
This is because of the incorrect specification of undefined behavior in the #tt[RCLB]/#tt[RCRB] variants.
The behavior specified by Dasgupta et al. matches Intel's implementation of this undefined behavior, not AMD's.
This highlights the importance of verifying specifications on multiple CPUs.



We only discover and analyze userspace instructions.
The primary reason for this is that the CPU observer needs to execute instructions in ring 3 (userspace) for sandboxing.
It would be possible to analyze privileged instructions by implementing a CPU observer as hypervisor.
Whether automatic analysis would be effective for privileged instructions is unclear.
In userspace, we can reasonably assume that an instruction, for example, does not change CPU configuration, modify the page table base register #tt[PTBR] or unmap memory.
Our analysis depends on these assumptions.
Significant, non-trivial modifications are needed to analyze privileged instructions.
