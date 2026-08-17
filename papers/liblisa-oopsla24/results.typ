#import "../theme.typ": *

#let data = json("data.json")
= Results <encoding-analysis:sec:results>

We analyzed the x86-64 CPUs listed in Table @encoding-analysis:cpulist.
The AMD 3900X and AMD 7700X use the Zen 2 and Zen 4 microarchitecture respectively.
The Intel i9-13900 has two different kinds of cores.
Performance cores ($A_2$) use Raptor Cove, while efficiency cores ($A_3$) use the Gracemont microarchitecture.
The Intel Xeon 4110 Silver uses the Skylake microarchitecture, a predecessor of Raptor Lake.

#html-compatible-figure([
    #set align(center)
    #table(
        columns: (auto, auto, auto),
        align: left,
        [], [Name], [Microarchitecture],
        [$A_0$], [Ryzen R9 3900X], [AMD - Zen 2],
        [$A_1$], [Ryzen R7 7700X], [AMD - Zen 4],
        [$A_2$], [Core i9-13900 (p)], [Intel - Raptor Cove],
        [$A_3$], [Core i9-13900 (e)], [Intel - Gracemont],
        [$A_4$], [Xeon Silver 4110], [Intel - Skylake],
    )
], caption: [
    Overview of the CPUs we analyzed.
], kind: "table", supplement: "Table") <encoding-analysis:cpulist>

@encoding-analysis:raw-counts provides an overview of the results.
Per architecture, it provides the number of generated encodings and the total time it took to run #libLISA.

#html-compatible-figure([
    #set align(center)
    
    //  A1:  928 + 249 = 1177h = 7w
    //  A2: 1640 + 356 = 2352h = 14w
    //  I1: 2761 + 385 = 3531h = 21w
    //  I2: 2198 + 312 = 2510h = 13w
    //  I3: 2367 + 280 = 2647h = 14w
    
    #let encodings = data.encodings.processors
    #let coverage = data.coverage.processors

    #let encoding(cpu) = encodings.at(cpu)
    #let cov(cpu) = coverage.at(cpu)

    #let dataFor(name) = (
      [#num(encoding(name).at("num_encodings"))],
      [#num(encoding(name).at("num_encodings_synthesized"))],
      [#num(encoding(name).at("num_encodings_undocumented"))],
      [#encoding(name).at("runtime_weeks") weeks],
      [#cov(name).at("binaries").at("in")],
      [#cov(name).at("binaries").at("out")],
      [#cov(name).at("random").at("in")]
    )

    #table(
        columns: (auto, auto, auto, auto, auto, auto, auto, auto),
        align: (x, y) => left,
        [],
        [Encodings],
        [Synthesized],
        [Undocumented],
        [Runtime],
        [$C_"in"$ (%)],
        [$C_"out"$ (%)],
        [$C_("random","in")$ (%)],

        [$A_0$], ..dataFor("amd-3900x"),
        [$A_1$], ..dataFor("amd-7700x"),
        [$A_2$], ..dataFor("i9-13900-e"),
        [$A_3$], ..dataFor("i9-13900-p"),
        [$A_4$], ..dataFor("intel-xeon-silver-4110"),
    )
], caption: [
    Overview of the results.
], kind: "table", supplement: "Table") <encoding-analysis:raw-counts>


== Validation
To validate our approach, we aim to answer two questions:

1. Do #libLISA's encodings cover all instructions on the CPU?
2. Is #libLISA able to synthesize semantics for undefined behavior?

Each of these questions is impossible to answer definitively, without access to an oracle that provides the ground truth (e.g., a trustworthy hardware design).
Such oracles do not exist for x86-64 CPUs, e.g., there is no trustworthy complete overview of the set of all valid instructions for each of the CPUs.
We therefore in this section devise _best-effort oracles_ and answer these questions relative to those oracles.
In that section, we provide an evaluative comparison to related work instead of relative to a best-effort oracle.


=== Instruction Coverage

As best-effort oracle, we generate lists of instructions.
The first list consists of instructions extracted from the Linux binaries #tt[ls], #tt[libxul.so], #tt[grep], #tt[gcc], #tt[ls], #tt[perl] and #tt[ssh].
This generally produces documented instructions, although these instructions are not always valid instructions on the CPU that is being analyzed.

From the Linux binaries we extracted
#num(data.coverage.processors.at("amd-3900x").at("binaries").at("num_instructions"))
instructions.
On average, these instructions covered
#num(
  (data.coverage.processors.at("amd-3900x").at("binaries").at("encodings_covered")
    + data.coverage.processors.at("amd-7700x").at("binaries").at("encodings_covered")
    + data.coverage.processors.at("i9-13900-e").at("binaries").at("encodings_covered")
    + data.coverage.processors.at("i9-13900-p").at("binaries").at("encodings_covered")
    + data.coverage.processors.at("intel-xeon-silver-4110").at("binaries").at("encodings_covered")
  ) / 5
) distinct encodings.

Per architecture, we compute the _in-scope coverage_
$C_"in"$ as the percentage of instructions in enumeration scope
from the oracle that are covered by an encoding.

The out-of-scope coverage $C_"out"$ is computed as the percentage
of all oracle-instructions that are covered.

@encoding-analysis:raw-counts presents results.
On average, #libLISA achieves 99.99% in-scope coverage.
Uncovered instructions consist of instructions with the EVEX prefix, which are not supported by any of the architectures we tested, and the SHA instructions, which are not supported by $A_4$.
These instructions are conditionally executed only when CPU support is detected.

The second approach is to randomly generate byte sequences.
This discovers instructions that can be undocumented or not commonly used in real-world programs, but it is biased to simpler instructions.
We randomly generated an average of
#num(
  (
    data.coverage.processors.at("amd-3900x").at("random").at("num_instructions")
    + data.coverage.processors.at("amd-7700x").at("random").at("num_instructions")
    + data.coverage.processors.at("i9-13900-e").at("random").at("num_instructions")
    + data.coverage.processors.at("i9-13900-p").at("random").at("num_instructions")
    + data.coverage.processors.at("intel-xeon-silver-4110").at("random").at("num_instructions")
  ) / 5
)
instructions per architecture, covering
#num(
  (
    data.coverage.processors.at("amd-3900x").at("random").at("encodings_covered")
    + data.coverage.processors.at("amd-7700x").at("random").at("encodings_covered")
    + data.coverage.processors.at("i9-13900-e").at("random").at("encodings_covered")
    + data.coverage.processors.at("i9-13900-p").at("random").at("encodings_covered")
    + data.coverage.processors.at("intel-xeon-silver-4110").at("random").at("encodings_covered")
  ) / 5
)
encodings on average.

@encoding-analysis:raw-counts shows the coverage
$C_("random","in")$, the percentage of in-scope oracle-instructions
discovered by #libLISA, which is 99.9% on average.


=== Undefined Behavior
We aim to determine how well our approach is able to synthesize semantics for undefined behavior.
By determining the encodings which have undefined behavior using a best-effort oracle, we can compute the percentage for which #libLISA has successfully synthesized semantics.

The best-effort oracle is a manual translation of the undefined behavior specified in the Intel Reference Manual to a machine-readable specification.
This specification relies on the Intel XED disassembler library to map bitstrings to instruction variants listed in the Intel Reference Manual.

There is no one-to-one mapping from instruction variants produced by the Intel XED disassembler library to encodings.
This makes it unfeasible to delineate exactly which parts of the instruction space covered by an encoding exhibit undefined behavior.
We therefore define the term "undefined behavior" conservatively: if even one instruction covered by the encoding has at least one input for which at least one output is undefined, we consider the encoding to have "undefined behavior".


We determine if an encoding has "undefined behavior" by randomly sampling instructions covered by the encoding.
Then, we query the oracle separately for each sampled instruction.
If the oracle determines that at least one of the sampled instructions exhibits undefined behavior, we consider the encoding to have undefined behavior.


The results are shown in @encoding-analysis:tbl:undefined.
On average, 90% of the encodings marked as having undefined behavior by the oracle were synthesized.


#html-compatible-figure([
    #set align(center)
    #table(
      columns: (auto, auto, auto, auto),
      align: left,
      [], [Synthesized], [Encodings], [Percentage],
      [$A_0$], [#num(18548)], [#num(20316)], [$91.2%$],
      [$A_1$], [#num(18087)], [#num(20204)], [$89.5%$], 
      [$A_2$], [#num(17805)], [#num(19578)], [$90.9%$], 
      [$A_3$], [#num(18123)], [#num(20105)], [$90.1%$], 
      [$A_4$], [#num(17699)], [#num(19767)], [$89.5%$],
  )


], caption: [
    The number of encodings with undefined behavior that #libLISA was able to synthesize.
], kind: "table", supplement: "Table") <encoding-analysis:tbl:undefined>



== Comparisons with Existing Work<encoding-analysis:results-existing-work-comparisons>
In this section we aim to answer two questions:

  + Do our semantics cover the same instructions semantics provided by related work?
  + Are our semantics correct relative to semantics provided by related work?

As related work, we consider the work of Dasgupta et al.~@dasgupta2019 (see Section~@encoding-analysis:sec:related-work for a more in-depth discussion on related work).
The work provides a mapping of _instruction variants_ to semantics.
Examples of instruction variants are #tt[ADD R8, IMM8] and #tt[XCHL R32, EAX].

Instruction variants do not easily translate to encodings, or the other way around.
An instruction variant is not a subset of an encoding, nor is an encoding a subset of an instruction variant.
It is also not possible to query all bitstrings that are described by a certain instruction variant.
This makes it impossible to compare instruction variants and encodings directly.

=== Approach<encoding-analysis:sec:dasgupta-comparison-approach>
To map encodings to variants, we randomly pick instantiations (i.e., concrete bitstrings).
For each encoding, we generate #num(10000) instantiations and filter them such that there are at most three instantiations with the same mnemonic, operand types and operand equality, according to #tt[objdump] (also used by Dasgupta et al.).
Then, we find the right instruction variant in the related work (if it exists) and instantiate it.
We export both semantics to the SMTLib format~@smtlib2, and check for equivalence using Z3~@z3.

It is difficult to export Dasgupta et al.'s semantics, which are specified in the K framework~@kframework, to SMTLib format.
Dasgupta et al. have implemented a conversion to the SMTLib format by constructing a program containing a single instruction followed by #tt[RETQ], then recompiling the semantics, executing the K prover on the program, extracting the last K state from the output log, converting this K state to Z3 by parsing the state, generating a Python program that uses the Z3 library to reconstruct the expressions, and then running the Python program.
This process is too slow for #num(118000) encodings.

#let dasguptaComparison = json("comparison.json")

To be able to extract semantics quickly, we have written a minimal parser and rewrite engine that can process the original K semantics.
There are #dasguptaComparison.amd-3900x.VSkipped variants which we were unable to process.
Four variants contain incorrect rules (#tt[LOOPNE], \[#tt[V]\]#tt[PCMPISTR]\[#tt[I]/#tt[M]\]).
We exclude the #tt[CLD], #tt[STD] variants because these variants use the direction flag, which #libLISA does not synthesize.
The rest of the #dasguptaComparison.amd-3900x.VSkipped variants require functionality that we did not implement, e.g., late-evaluation of RSP in memory addresses.

It is not always clear which variant should be picked.
Dasgupta et al.'s semantics do not specify immediate value sizes.
They attempt to fix this during compilation by always deleting the #tt[imm8] variants of instructions that also have #tt[imm32] variants, forcing the #tt[imm32] variant to be used.
However, their list of instructions is incomplete (for example, #tt[sbb\_r32\_imm8] is missing)
We instead inspect variable names to determine the intended size of immediate values.
The semantics also contain overlapping variants (e.g., #tt[shl\_r32\_one] and #tt[shl\_r32\_imm8]), we use a heuristic to score variants and select the most applicable variant.

Some of Dasgupta et al.'s instruction variants are aliases of other variants.
We copy the comparison results from the variant returned by the disassembler to other aliases.

=== Comparison Results<encoding-analysis:dasgupta-comparison-results>

#html-compatible-figure([
  #set align(center)
  #table(
      columns: (75mm, auto, auto, auto, auto, auto),
      align: (x, y) => left,
      [], [$A_0$], [$A_1$], [$A_2$], [$A_3$], [$A_4$],
      table.cell(colspan: 6, box[Variants from Dasgupta et al. that#sym.dots]),
      [#h(1em) #sym.dots agree with #libLISA],
          num(dasguptaComparison.amd-3900x.VAgree),
          num(dasguptaComparison.amd-7700x.VAgree),
          num(dasguptaComparison.i9-13900-p.VAgree),
          num(dasguptaComparison.i9-13900-e.VAgree),
          num(dasguptaComparison.intel-xeon-silver-4110.VAgree),

      box[#h(1em) #sym.dots disagree with #libLISA],
          num(dasguptaComparison.amd-3900x.VDisagree),
          num(dasguptaComparison.amd-7700x.VDisagree),
          num(dasguptaComparison.i9-13900-p.VDisagree),
          num(dasguptaComparison.i9-13900-e.VDisagree),
          num(dasguptaComparison.intel-xeon-silver-4110.VDisagree),

      box[#h(3em) Dasgupta et al. incorrect],
          num(dasguptaComparison.amd-3900x.VDisagreeDasguptaError),
          num(dasguptaComparison.amd-7700x.VDisagreeDasguptaError),
          num(dasguptaComparison.i9-13900-p.VDisagreeDasguptaError),
          num(dasguptaComparison.i9-13900-e.VDisagreeDasguptaError),
          num(dasguptaComparison.intel-xeon-silver-4110.VDisagreeDasguptaError),

      box[#h(3em) #libLISA incorrect],
          num(dasguptaComparison.amd-3900x.VDisagreeLibLisaError),
          num(dasguptaComparison.amd-7700x.VDisagreeLibLisaError),
          num(dasguptaComparison.i9-13900-p.VDisagreeLibLisaError),
          num(dasguptaComparison.i9-13900-e.VDisagreeLibLisaError),
          num(dasguptaComparison.intel-xeon-silver-4110.VDisagreeLibLisaError),

      box[#h(1em) #sym.dots are incorrectly specified],
          num(dasguptaComparison.amd-3900x.VMissingDasguptaError),
          num(dasguptaComparison.amd-7700x.VMissingDasguptaError),
          num(dasguptaComparison.i9-13900-p.VMissingDasguptaError),
          num(dasguptaComparison.i9-13900-e.VMissingDasguptaError),
          num(dasguptaComparison.intel-xeon-silver-4110.VMissingDasguptaError),

      box[#h(1em) #sym.dots are out of enumeration scope for #libLISA],
          num(dasguptaComparison.amd-3900x.VMissingOutOfScope),
          num(dasguptaComparison.amd-7700x.VMissingOutOfScope),
          num(dasguptaComparison.i9-13900-p.VMissingOutOfScope),
          num(dasguptaComparison.i9-13900-e.VMissingOutOfScope),
          num(dasguptaComparison.intel-xeon-silver-4110.VMissingOutOfScope),

      box[#h(1em) #sym.dots are enumerated but not synthesized by #libLISA],
          num(dasguptaComparison.amd-3900x.VMissingSynthesis),
          num(dasguptaComparison.amd-7700x.VMissingSynthesis),
          num(dasguptaComparison.i9-13900-p.VMissingSynthesis),
          num(dasguptaComparison.i9-13900-e.VMissingSynthesis),
          num(dasguptaComparison.intel-xeon-silver-4110.VMissingSynthesis),

      box[#h(1em) #sym.dots are not discovered by #libLISA's enumeration],
          num(dasguptaComparison.amd-3900x.VMissingEnumeration),
          num(dasguptaComparison.amd-7700x.VMissingEnumeration),
          num(dasguptaComparison.i9-13900-p.VMissingEnumeration),
          // '0' here because of bug that has since been fixed
          [#num(0)],
          num(dasguptaComparison.intel-xeon-silver-4110.VMissingEnumeration),

      table.cell(colspan: 6, box[Encodings found by #libLISA that$#sym.dots$]),
          box[#h(1em)#sym.dots are not covered by Dasgupta et al.],
          num(dasguptaComparison.amd-3900x.EMissing),
          num(dasguptaComparison.amd-7700x.EMissing),
          num(dasguptaComparison.i9-13900-p.EMissing),
          num(dasguptaComparison.i9-13900-e.EMissing),
          num(dasguptaComparison.intel-xeon-silver-4110.EMissing),
  )
], caption: [
  Comparative results. We were unable to compare semantics from #num(dasguptaComparison.amd-3900x.VSkipped) variants of Dasgupta et al.'s semantics.
], kind: "table", supplement: "Table") <encoding-analysis:tab:relative_compare>


@encoding-analysis:tab:relative_compare provides the results.
A variant _agrees with_ #libLISA when for all concrete bitstrings generated from the encodings, Z3 is able to prove equivalence between #libLISA and Dasgupta et al.'s semantics.
A variant _disagrees with_ #libLISA when this is not the case.
We discuss the differences between #libLISA and Dasgupta et al. in more detail in the rest of this section.

#paragraph[Disagreements (Dasgupta et al. incorrect)] 
We identify errors in 28 variants of the semantics of Dasgupta et al.:

  + The overflow flag (OF) of #tt[RCLB]/#tt[RCRB] is undefined when the masked rotate count is not 0 or 1. However, Dasgupta et al. specifies the OF as undefined when the masked rotate count _modulo the operand size + 1_ is not 0 or 1. (10 variants)
  + In #tt[vmpsadbw\_xmm\_xmm\_m128\_imm8], the result is written to the source operand (R3) instead of the destination operand (R4). (1 variant)
  + In all bit test variants (#tt[BT]/#tt[BTS]/#tt[BTR]/#tt[BTC]) on memory with a register bit offset, the bit offset is computed incorrectly. The bit offset is converted to a byte offset by shifting right by 3, then zero-extending the result to 64 bits. It should be sign-extended, to preserve the sign bits of negative offsets. (8 variants)
  + The #tt[CMPS] variants perform a comparison by setting flags according to $m_2 - m_1$, but they should be set according to $m_1 - m_2$. (6 variants)
  //  This happens on the versions of objdump used by Dasgupta et al.. It still exists on Ubuntu 20.04, but is fixed in the latest versions.
  //  This was fixed in 2f399d995b59a522c2739c0ab163c501c082cafb in binutils-gdb.
  + The instruction #tt[XCHGL EAX, EAX] can be encoded as both #tt[87C0] and #tt[90]. The second encoding has the semantics of #tt[NOP] (do nothing), while the first has the semantics of #tt[XCHGL] (set the upper 32 bits of #tt[RAX] to zero). The disassembler used by Dasgupta et al. incorrectly disassembles #tt[90] with a #tt[REX] prefix as #tt[XCHGL] instead of #tt[NOP]. (1 variant)
  + The #tt[MULX] instructions write a result to two destination operands. The destination operands can be equal. Dasgupta et al.'s semantics have not taken this possibility into account, causing the K prover to crash when #tt[MULX] with equal destination operands is executed. (2 variants)

#paragraph[Disagreements (#libLISA incorrect)]
Three to seven disagreements are errors in the semantics generated by #libLISA.
Our synthesis accepts semantics as correct when a hypothesis is correct w.r.t. two million consecutive random observations.
In rare cases, these observations do not encompass all behavior of the instruction, which can lead to incorrect semantics.
We see that the same kind of instruction is more often synthesized incorrectly across different architectures, but the exact variant differs.
For example, $A_0$ synthesized #tt[adc\_rax\_imm32] incorrectly, while $A_1$ synthesized that variant correctly and synthesized #tt[adcq\_r64\_imm32] incorrectly instead.
This indicates that these errors could be prevented by increasing the amount of random observations, or by improving the quality of the random observations.
Some examples of errors are:

  + The zero flag of the #tt[SHLDQ M64, R64, 0x9] instruction is synthesized incorrectly for $A_0$.
    The semantics correctly check that the part of the result from #tt[M64] is zero, but incorrectly check only the lower 8 instead of 9 bits shifted in from #tt[R64]. This happened because the synthesizer did not encounter any cases where the lower 8 bits were 0, but the 9th bit was 1.
  + The overflow flag of the #tt[ADC] instruction is synthesized incorrectly.
    The overflow flag being $1$ is relatively rare, and the synthesizer has not seen enough cases to form a good hypothesis.
  + The zero flag of the #tt[VPTEST] instruction with identical operands is synthesized as always zero.
    The synthesizer did not encounter any cases where all 256 bits of the register were zero, and has therefore not seen any evidence that the zero flag can be non-zero.

#paragraph[Incorrect specifications] There are #tt[rel32] variants of the #tt[JRCXZ] and #tt[JECXZ] instructions, but these should only have #tt[rel8] variants.
One variant of #tt[VCVTDQ2PD] accepts two #tt[YMM] operands, while it should accept one #tt[XMM] and one #tt[YMM] operand instead.
Two variants, #tt[vcvtpd2ps\_xmm\_m256] and #tt[vcvttpd2dq\_xmm\_m256], have #tt[m128] variants that always match the same instructions.
Instructions from both the #tt[m128] and #tt[m256] variants will incorrectly use the semantics of only one of the two variants.
Finally, the #tt[vpinsrq\_xmm\_xmm\_m64\_imm8] variant is a copy of #tt[vpinsrq\_xmm\_m64\_imm8].
This is incorrect, as this variant should accept one more #tt[XMM] register.

#paragraph[Out-of-scope] #num(dasguptaComparison.amd-3900x.VMissingOutOfScope) variants are out of enumeration scope for #libLISA, as described in @encoding-analysis:subsec:scope.
Most variants in this category are non-#tt[VEX] versions of SSE/AVX instructions, which re-use the data size override prefix #tt[66].
For around #avg((dasguptaComparison.amd-3900x.VExtraAgreeWithScopeExtension, dasguptaComparison.amd-7700x.VExtraAgreeWithScopeExtension, dasguptaComparison.i9-13900-p.VExtraAgreeWithScopeExtension, dasguptaComparison.i9-13900-e.VExtraAgreeWithScopeExtension, dasguptaComparison.intel-xeon-silver-4110.VExtraAgreeWithScopeExtension)) out-of-scope variants, similar variants without the data size override prefix agree with #libLISA's semantics.
This means that by extending scope and doubling runtime, #libLISA would be able to generate semantics where around 1900 variants would agree.

#paragraph[Synthesis failure]
For #dasguptaComparison.i9-13900-p.VMissingSynthesis to #dasguptaComparison.intel-xeon-silver-4110.VMissingSynthesis variants synthesis failed.
This concerns mostly floating point operations, for which we did not implement support in our synthesis.

#paragraph[Not covered by Dasgupta et al]
These encodings include both instructions that Dasgupta et al. considered out-of-scope, and instructions that Dasgupta et al. considered in-scope.
Examples of variants outside Dasgupta et al.'s scope are: undocumented instructions, instructions operating on the MMX registers, instructions using segment registers, and recent ISA extensions like the SHA1 and SHA256 instructions. Missing variants within Dasgupta et al.'s scope include: YMM variants for the #tt[VPSIGNB]/#tt[VPSIGNW]/#tt[VPSIGND]/#tt[VPMINSW] instructions, #tt[vcvtdq2pd\_xmm\_ymm] and #tt[retq\_imm].

== Use Cases
We demonstrate the feasibility of three use cases:
 
  - comparing CPU-implementations
  - discovering and analyzing undocumented instructions
  - emulating userspace binaries

=== Comparing CPU Implementations
By comparing the semantics of different CPU microarchitectures, we can find interesting differences.
We describe the differences between the semantics we found in @encoding-analysis:semantic-differences.


#html-compatible-figure([
    #set align(center)

    #let ImplA = rect(width: 2mm, height: 2mm, fill: liblisa-blue)
    #let ImplB = circle(radius: 1mm, stroke: 1mm + red, fill: red)
    #let ImplC = polygon(fill: green, (1mm, 0mm), (2mm, 2mm), (0em, 2mm))
    #let ImplD = polygon(fill: orange, (1mm, 2mm), (2mm, 0mm), (0mm, 0mm))
    #let ImplE = circle(radius: 1mm, stroke: 0.7mm + purple)
    #let ImplX = []
    #set align(center)
    #table(
      columns: (auto, auto, 6mm, 6mm, 6mm, 6mm, 6mm),
      inset: (bottom: 1mm, top: 1mm),
      table.cell(align: left, inset: (top: 2mm, bottom: 2mm), [ *Group* ]),
      table.cell([ *\# Encodings* ], align: left), [ $A_0$ ], [ $A_1$ ], [ $A_2$ ], [ $A_3$ ], [ $A_4$ ],
      
      align(left, [Group 0    ]), align(right, [ 95170 ]), [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 1    ]), align(right, [  4777 ]), [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplC ], [ #ImplB ],
      align(left, [Group 2    ]), align(right, [  2571 ]), [ #ImplA ], [ #ImplA ], [ #ImplX ], [ #ImplX ], [ #ImplX ],
      align(left, [Group 3    ]), align(right, [  1602 ]), [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplA ], [ #ImplB ],
      align(left, [Group 4    ]), align(right, [   604 ]), [ #ImplA ], [ #ImplB ], [ #ImplC ], [ #ImplD ], [ #ImplE ],
      align(left, [Group 5    ]), align(right, [   581 ]), [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplB ], [ #ImplB ],
      align(left, [Group 6    ]), align(right, [   101 ]), [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplX ],
      align(left, [Group 7    ]), align(right, [    40 ]), [ #ImplX ], [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplX ],
      align(left, [Group 8    ]), align(right, [    29 ]), [ #ImplX ], [ #ImplX ], [ #ImplA ], [ #ImplA ], [ #ImplX ],
      align(left, [Group 9    ]), align(right, [    24 ]), [ #ImplX ], [ #ImplX ], [ #ImplX ], [ #ImplX ], [ #ImplA ],
      align(left, [Group 10   ]), align(right, [    16 ]), [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplB ],
      align(left, [Group 11   ]), align(right, [    16 ]), [ #ImplA ], [ #ImplB ], [ #ImplB ], [ #ImplB ], [ #ImplB ],
      align(left, [Group 12   ]), align(right, [    12 ]), [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 13   ]), align(right, [     9 ]), [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplA ],
      align(left, [Group 14   ]), align(right, [     7 ]), [ #ImplA ], [ #ImplB ], [ #ImplA ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 15   ]), align(right, [     5 ]), [ #ImplA ], [ #ImplB ], [ #ImplA ], [ #ImplB ], [ #ImplA ],
      align(left, [Group 16   ]), align(right, [     5 ]), [ #ImplA ], [ #ImplB ], [ #ImplB ], [ #ImplA ], [ #ImplC ],
      align(left, [Group 17   ]), align(right, [     4 ]), [ #ImplA ], [ #ImplB ], [ #ImplB ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 18   ]), align(right, [     3 ]), [ #ImplA ], [ #ImplA ], [ #ImplX ], [ #ImplX ], [ #ImplA ],
      align(left, [Group 19   ]), align(right, [     2 ]), [ #ImplX ], [ #ImplX ], [ #ImplA ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 20   ]), align(right, [     2 ]), [ #ImplA ], [ #ImplB ], [ #ImplC ], [ #ImplD ], [ #ImplC ],
      align(left, [Group 21   ]), align(right, [     1 ]), [ #ImplX ], [ #ImplA ], [ #ImplX ], [ #ImplX ], [ #ImplX ],
      align(left, [Group 22   ]), align(right, [     1 ]), [ #ImplX ], [ #ImplA ], [ #ImplA ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 23   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplX ], [ #ImplX ], [ #ImplX ], [ #ImplA ],
      align(left, [Group 24   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplX ], [ #ImplA ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 25   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplA ], [ #ImplX ], [ #ImplA ], [ #ImplA ],
      align(left, [Group 26   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplA ], [ #ImplB ], [ #ImplB ], [ #ImplA ],
      align(left, [Group 27   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplB ], [ #ImplA ], [ #ImplC ], [ #ImplC ],
      align(left, [Group 28   ]), align(right, [     1 ]), [ #ImplA ], [ #ImplB ], [ #ImplC ], [ #ImplC ], [ #ImplC ],
      align(left, [Synthesis failed]), align(right, [ 14036 ]),
    )
], caption: [
    Architecture comparison. Each row describes a group of instructions that differ in a certain way between architectures. Each symbol represents a different implementation for that specific group of instructions. For example, there are two implementations for the instructions in group 5: $A_0$ and $A_1$ share the same implementation, and $A_2$, $A_3$ and $A_4$ share another implementation. We re-use the same symbols for each row. When a cell is left blank, this indicates a missing implementation. For example, the instructions in group 2 are only supported by $A_0$ and $A_1$.
], kind: "table", supplement: "Table") <encoding-analysis:semantic-differences>


Most encodings are part of group~0, which have identical semantics across all 5 architectures.
All other groups show differences between architectures.
Architecture~0 and~1 often share the same semantics.
This is likely because architecture~1 is a successor of architecture~0.
Similarly, architecture~2 and~4 also often share semantics, and architecture~2 is also a successor of architecture~4.

Group~1, 3, 5, 20 and 28 consist primarily of differences between microarchitectural implementations.
When manually inspecting these groups we find bit shifts, rotates, multiplication, division and bit manipulation instructions.
These are common instructions that can exhibit undefined behavior.

Groups~2, 6-9 and 19 show differences in instruction support.
Upon manual inspection, we found that group~2 contains the undocumented AMD-only instructions.
Group~6 contains the SHA1 and SHA256 instructions, which were introduced after architecture~4 was released.
Group~7, 8 and 9 contain various other instructions introduced in x86-64 ISA extensions.
Group~19 contains the #tt[VMCALL] virtualization instructions, which are Intel-only.

We can also use this table to construct fingerprinting programs.
Such a program can identify the architecture it is running on, among all the analyzed architectures.
For example, to distinguish between the five architectures we analyzed, we could use group 1 and group 7.
By observing an instruction from group 1, we can distinguish between $A_0$, $A_1$ or $A_2$, $A_4$ or $A_3$.
Then, by also observing group 7, we can distinguish between $A_0$ and $A_1$ or $A_2$ and $A_4$.
This would require executing at most 3 instructions and some logic to decode the result.

=== Discovery and Analysis of Undocumented Instructions
Undocumented instructions are valid instructions which have not been specified by the manufacturer in their documentation.
For example, on Intel CPUs there used to be an undocumented instruction #tt[D6], which was only added to the Intel reference manual as the #tt[SALC] instruction in 2017.

We use the Intel XED disassembler library as an oracle to determine whether instructions are documented.
To eliminate false positives, we manually verified the undocumented instructions we found against the Intel and AMD reference manual and #tt[objdump].

The results are listed in @encoding-analysis:raw-counts.
We identified one group of undocumented instructions on AMD CPUs.
We did not identify any undocumented instructions on Intel CPUs.
It is possible that our results are favoring Intel CPUs because we are using a disassembler library created by Intel.
While we were able to manually confirm that all undocumented instructions are indeed undocumented, there might be undocumented instructions on Intel CPUs that XED incorrectly decodes successfully.


The semantics of the group of undocumented instructions on the AMD CPUs match the semantics of the #tt[VPERMQ] instruction.
The #tt[VPERMQ] expects #tt[VEX.W] to be 1.
These undocumented instructions are bit-for-bit identical with #tt[VPERMQ] variants except for #tt[VEX.W], which is 0.
We suspect that the decoding logic for the VEX prefix does not check the value of #tt[VEX.W], and causes the instructions to be treated as if they were valid #tt[VPERMQ] instructions.


== Emulating Userspace Binaries<encoding-analysis:sec:emulation>
We implement a proof-of-concept emulator that uses #libLISA's semantics as-is to emulate x86-64 ELF binaries.
The emulator uses the semantics from the #num(118000) encodings, and runs encoding analysis and synthesis on-the-fly for instructions that are out-of-prefix-scope.
This makes it possible to fully emulate some Linux binaries that do not use floating-point instructions.
@encoding-analysis:tbl:emulation presents the binaries we have successfully emulated on an AMD 3900X.

The emulator stores the emulated CPU state in a data structure.
During execution, it repeatedly modifies the emulated CPU state.
To execute an instruction, it reads memory at the address stored in the emulated #tt[RIP].
The semantics for the instruction are found by searching through #libLISA's semantics.
If no suitable semantics are found, on-the-fly encoding analysis and synthesis is invoked.

The semantics are executed by fetching inputs, computing results, and then storing results.
First, the values of all sources in the dataflows are fetched by reading the value from the data structure storing the emulated CPU state or memory.
Then, the new values for all destinations are computed using the synthesized computations in the semantics.
Finally, the new values are written to the destinations.

The emulator provides handwritten implementations for the #tt[SYSCALL], #tt[XGETBV] and #tt[CPUID] instructions.
Additionally, we treat four additional instructions as #tt[NOP]s: #tt[ICEBP], #tt[RDTSC], #tt[XSAVEC], and #tt[XRSTOR].
For all other instructions we use semantics generated by #libLISA.

We verify the emulated instructions against the real CPU behavior using the CPU observer.
For each instruction we emulate, we compute the next CPU state, and then observe the real next CPU state.
If these differ, we abort execution.
In total, we have verified #num(1244385) instruction executions against the real CPU behavior.


#html-compatible-figure([
  #set align(center)
  #table(
    columns: (auto, auto),
    align: (x, y) => left,
    [Binary], [Number of instructions],
    [Hello world], [#num(98813)],
    [#tt[/bin/true]], [#num(120969)],
    [#tt[/bin/ls /dev/null]], [#num(321084)],
    [#tt[/bin/ls -hla /dev/null]], [#num(401037)],
    [#tt[/bin/date]], [#num(172827)],
    [#tt[/bin/echo 'abc']], [#num(129655)],
  )
], caption: [
  Binaries that we are able to emulate successfully on an AMD 3900X CPU.
], kind: "table", supplement: "Table") <encoding-analysis:tbl:emulation>


We emulate the binary itself, the dynamic linker (#tt[/lib64/ld-linux-x86-64.so.2]), and all dynamically loaded binaries (e.g., #tt[libc.so]).
This reduces the manual implementation effort, as we can rely on the dynamic linker to link dependencies automatically, instead of having to implement these manually.
It also significantly increases the amount of instructions that are executed for simple binaries.
The hello world binary consists of one call to #tt[printf], consisting of around 100 instructions, with the rest of the executed instructions being in the dynamic linker and the C standard library.
