#import "../theme.typ": *

= Approach <encoding-analysis:sec:implementation>

We present an approach for systematically discovering and analyzing instructions on a CPU.
We provide an overview of the three main components of this approach: 1.) the CPU observer, 2.) enumeration based on encoding analysis, and 3.) synthesis.

== CPU Observer
In order to analyze instructions, we need a CPU observer.
This CPU observer needs to be _fast_, _sandboxed_ and _unrestricted_.
It needs to be fast, because we will perform tens of millions of observations for each instruction we analyze.
Instruction execution must be sandboxed, such that it does not affect our analysis tool or the operating system in unintended ways.
There must be as few restrictions on the input CPU state as possible, so that we can freely observe as much of the behavior of the instruction as possible.


#html-compatible-figure([
  #set align(center)
  #image("../imgs/cpu-observer.pdf")
], caption: [
     The CPU observer uses QEMU with KVM hardware-acceleration to run an observation kernel, and execute observations in userspace inside the virtualized environment.
], supplement: "Figure") <encoding-analysis:fig:cpu-observer>


There are two common ways to observe instruction execution: _in-process observation_~@sandsifter @iscanu @uisfuzz @strata and _out-of-process observation_~@iscanu.
Neither of these methods fulfill all requirements.
Therefore, we have developed a new instruction observation method.

Both in-process observation and out-of-process observation ultimately execute an instruction in a userspace process.
After execution, control over program flow is regained using the _trap flag_, _guard pages_ or _interrupt instructions_.
A guard page is an unmapped page that is placed in memory right after the instruction. When the CPU has executed the instruction and attempts to load the next instruction, a page fault is triggered. This page fault is intercepted by the program, and used to regain control.
The trap flag is a debugging flag available on many modern CPU architectures, including x86-64. It triggers a CPU interrupt after executing a single instruction. This interrupt is intercepted by the program, and used to regain control.
Interrupt instructions are special debugging instructions that trigger a debugging interrupt.
On x86-64, the #tt[INT3] instruction is commonly used for this purpose.
After execution, the result is saved and normal program execution is resumed by loading the original program state from memory.

_In-process observation_ consists of storing the program state in memory, placing the instruction at a known memory address, and then jumping to that address.
This approach is fast, but not sandboxed, and the input CPU states cannot use the address space used by the program itself or reserved by the kernel (Linux reserves half of the address space).

_Out-of-process observation_ consists of spawning a separate observation process.
This observation process is then instrumented using a debugging interface like #tt[ptrace].
CPU state can be modified through this interface, and memory can be mapped and unmapped by placing assembly for the correct system calls in the memory of the observation process and executing it via the debugging interface.
While this approach provides some sandboxing, it shares many of the same restrictions on input CPU states as in-process observation, and is very slow because the debugging interface has a lot of overhead.


We have developed a new observation approach based on hardware-accelerated virtualization and fast communication via shared memory.
The approach is depicted in Figure~@encoding-analysis:fig:cpu-observer.
It consists of two components: a process running on the host machine, and a small bare-metal observer binary running in a virtual machine.
Using a ring buffer~@ringbuffer, these components can communicate without the overhead of syscalls.
The observer running in the virtual machine performs context switches to userspace to observe instructions.
This provides hardware-enforced protection to the observer from the effects of the instruction execution.

The observer repeatedly reads an observation request from the ring buffer, executes the request, and then writes the result back to the ring buffer.
Observation requests are executed similar to how an operating system performs context switches between processes.
Whereas an operating system typically restores CPU state from a _process control block_, the observer restores CPU state from the observation request in the ring buffer.
It then switches to userspace, allows the CPU to execute an instruction, and then regains control.
Finally, the observer saves the CPU state directly to the observation result in the ring buffer.

To regain control, the observer uses #tt[INT3] interrupt instruction by default.
If we detect that the instruction does not increment the program counter by the length of the instruction (e.g., the instruction is a branching instruction), we are unable to predict the address where we need to place the #tt[INT3] interrupt instruction.
In that case, we fall back to using the trap flag.
We use the #tt[INT3] interrupt instruction by default, because it does not require writing a flag in the debugging registers and is therefore faster.

== Enumeration

#html-compatible-figure([
    #set align(center)
    
    #image("../imgs/enumeration.pdf")
], caption: [
     A feedback loop from Encoding Analysis to enumeration makes it possible to fully enumerate large instruction spaces.
], supplement: "Figure") <encoding-analysis:fig:enumeration>


The goal of enumeration is discovering all in-scope instructions on a CPU.
We do this by repeatedly selecting an uncovered instruction, and analyzing it.

For large instruction sets like x86-64, it is impossible to enumerate every individual bitstring.
For example, the #tt[MOVABS RAX, 0x152], instruction contains a 64-bit immediate value.
It is impossible to exhaustively enumerate all $2^64$ values of this immediate.
We instead _skip over parts of the instruction space_ using 1.) bitpatterns from encodings, 2.) randomized search and 3.) tunneling.

As described in Section~@sec:liblisa:overview, every encoding represents a group of instructions described by its bitpattern.
During enumeration, we run encoding analysis on each valid instruction.
We then use the bitpattern from the resulting encoding to skip all instructions it matches.
This is depicted in Figure~@encoding-analysis:fig:enumeration.
For example, for #tt[MOVABS RAX, 0x152] encoding analysis will yield an encoding with a bitpattern containing two parts: a 64-bit part for the immediate value and a 4-bit part for the destination register.
This allows us to skip the $2^68-1$ other instructions covered by this encoding.

#algorithm(title: "Enumeration.", [
    #set align(left)
    #algorithmic(
        indent: 0.5em, // indentation for the algorithm
        vstroke: 0pt + luma(200), // vertical stroke for indentation guide
        line-numbers: true, // show line numbers
        line-numbers-format: x => [#x:], // change the line numbers format
        {
            import "@preview/algorithmic:1.0.7": *

            Comment([ *Result*: a set of enumerated encodings $E$ ])
            Procedure("Enumerate", (), {
                Assign[$E$][$emptyset$]
                Assign[$S$][$emptyset$]
                Assign[$I$][$"NextUncoveredInstruction"(S)$]
                While($I eq.not "None"$, {
                    IfElseChain(
                        $"IsValidInstruction"(I)$,
                        {
                            Assign[$e$]["AnalyzeEncoding"(I)]
                            IfElseChain(
                                $e eq.not "Err"$,
                                {
                                    Assign[$E$][$E union { e }$]
                                    Assign[$S$][$S union { i | i "matches bitpattern of" e }$]
                                },
                                {
                                    Assign[S][S union "Tunnel"(I)]
                                }
                            )
                        },
                        {
                            Assign[$S$][$S union "RandomizedSearch"(I)$]
                        }
                    )

                    Assign[$I$]["NextUncoveredInstruction"(S)]
                })

                Return($[E]$)
            })
        }
    )
]) <encoding-analysis:alg:enumeration>

The enumeration algorithm is depicted in @encoding-analysis:alg:enumeration.
It takes no inputs, and produces a set of encodings $E$, covering all valid instructions in the instruction space.
It makes use of five functions: #tt[NextUncoveredInstruction], #tt[IsValidInstruction], #tt[RandomizedSearch], #tt[Tunnel] and #tt[AnalyzeEncoding].

The function #tt[NextUncoveredInstruction] takes as input a set of covered instructions $S$.
It returns an instruction $I$ which is not in the set of covered instruction $S$.
In our implementation, we start at the byte sequence #tt[00] and then sequentially return all other byte sequences in lexicographical order.
We picked a lexicographical ordering because it is simple to implement.
The actual order is not relevant for the algorithm.

The function #tt[IsValidInstruction] takes as input an instruction $I$ and checks if it is _valid_, i.e., if executing it does not cause the CPU to throw the undefined instruction exception.

The function #tt[RandomizedSearch] takes as input an instruction $I$ and performs a randomized search for the first valid instruction after $I$.
We use $I$ as lower bound and the highest possible instruction ($#tt[FFFFFFFF]dots$) as upper bound for the search.
We then repeatedly pick random byte sequences within the search range.
If the random byte sequence is a valid instruction, we reduce the upper bound.
When the upper bound has not changed for #num(250000) iterations, it returns the set of instructions between $I$ and the upper bound.

The function #tt[Tunnel] takes as input an instruction $I$ and performs _tunneling_~@sandsifter @uisfuzz @iscanu to find the first valid and analyzable instruction.
Tunneling initially steps through byte sequences one-by-one.
Every $2^8$ steps the step size is multiplied by $2^8$.
Whenever the instruction length changes, the step size is reset to zero.
This makes the number of steps needed to skip over an instruction with an invalid 64-bit immediate value $2^8 * 8$ instead of $(2^8)^8$.
Once a valid and analyzable instruction is found, it returns the set of instructions between $I$ and the valid and analyzable instruction.

The function #tt[AnalyzeEncoding] takes as input an instruction $I$ and runs encoding analysis on the instruction.
Encoding Analysis is described in Section~@encoding-analysis:subsec:encoding-analysis.
Encoding analysis returns an encoding $e$.
This encoding has a bitpattern, which represents the set of instructions covered by the encoding.

The algorithm repeatedly selects the next instruction not yet covered, and analyzes it.
If the next instruction is not a valid instruction, randomized search is used to skip it and all consecutive invalid instructions.
If it is a valid instruction, encoding analysis is run.
Normally, encoding analysis produces an encoding.
If this is the case, the bitpattern is used to skip over all other instructions covered by the encoding.
Finally, in some cases encoding analysis might be unable to analyze the instruction.
This can happen for example when the instruction violates some of the assumptions we have listed in Section~@encoding-analysis:subsec:scope.
In such a case, we do not have a bitpattern, and we also cannot use randomized search.
Instead, we resort to tunneling~@sandsifter @uisfuzz @iscanu.

Skipping using bitpatterns guarantees that we do not skip over valid instructions.
Randomized search and tunneling may cause us to skip over valid instructions.
We therefore use bitpattern based skipping whenever possible.

As the instruction's length is often determined by a few bits in a single byte of the instruction, tunneling generally works correctly.
However, there are edge-cases where this does not work.
For example, consider the case where byte sequences #tt[1b00]-#tt[1cff] are invalid, except for #tt[1c05].
In this case, tunneling will step through #tt[1b00]-#tt[1bff] in steps of 1, but after checking #tt[1c00] the step size is increased to 256, which means the next instruction checked is #tt[1d00].
This skips over the valid instruction #tt[1c05].
Because of these limitations, we skip instructions using bitpatterns or randomized search whenever possible.

Randomized search is more reliable than tunneling, but only applicable for invalid instructions.
It might still skip over valid instructions.
This can be the case when the chance of finding the valid instruction in #num(250000) tries is low.
We picked the threshold through testing against tunneling.
Randomized search with a threshold of #num(250000) iterations performs better or equivalent to tunneling for all in-scope areas of the x86-64 instruction space.
In particular, it correctly handles the tunneling edge-case described above.

== Encoding Analysis<encoding-analysis:subsec:encoding-analysis>
The goal of encoding analysis is to generate an encoding, i.e., parts and dataflows, from a concrete instruction bitstring.
We propose a novel infer-generalize-specialize approach.
This approach consists of three steps: _inferring_ dataflows, _generalizing_ the dataflows into an encoding, and _specializing_ the resulting encoding.
The infer step produces dataflows which are consistent with all concrete observations.
The generalization step uses these dataflows as a basis to form a generalized encoding.

The generalization step is purely speculative, and might produce an encoding with incorrect generalizations.
Generalizations are incorrect when the dataflows in the resulting encoding are not consistent with actual CPU behavior.
To counter this, the specialization step removes these by specializing the encoding for cases where a generalization is proven incorrect via an observation.

Each of these three steps require the generation of random CPU states.
In the rest of this subsection, we first describe how this is done, and then provide details on each of the three steps of the infer-generalize-specialize approach.

#html-compatible-figure([
    #set align(center)
    
    #image("../imgs/approach.pdf")
], caption: [
     The infer-generalize-specialize approach. The green circles are correct dataflows, the red squares are incorrect dataflows, and the dashed boxes represent encodings. The infer step produces some (in this case, two) correct, concrete dataflows. The generalize step combines these concrete dataflows into an encoding, but might make incorrect generalizations. The specialize step removes these incorrect generalizations.
], supplement: "Figure") <encoding-analysis:fig:approach-overview>


=== Random CPU State Generation
For small CPU architectures, it is sometimes possible to exhaustively verify all possible input states.
For modern architectures such as x86-64, exhaustive verification is impossible without access to hardware designs.
We therefore can only verify the semantics that we generate on a subset of all possible input states.

Uniformly distributed random input states are often not useful for fuzzing.
For example, when incrementing a 32-bit value we only have a 1 in $2^32$ chance of seeing a carry in the highest bit if we pick uniformly distributed random numbers (the only case where this happens is 0xFFFFFFFF).
Interesting inputs often contain many consecutive zeros or ones.
Therefore, our random generation is based on the computation $(R_#text([64]) #h(1mm) << #h(1mm) R_z) #h(1mm) >> #h(1mm) R_k$ where $<<$ and $>>$ are bit shifts, $R_64$ is a uniformly distributed random 64-bit number and $R_z, R_k$ are random uniformly distributed valid bit shift counts.
The resulting number is then randomly negated or kept as-is.
This computation produces numbers where the number of leading and trailing zeros and ones are approximately uniformly distributed.
This random generation needs to run billions of times for each encoding we analyze.
Improving quality of the random numbers reduces the speed at which we are able to generate new random numbers.
We have therefore opted to use this simple expression consisting of only two bit shifts.

=== Inferring Dataflows
For a given an instruction $I$ consisting of $N$ bits, we analyze the instruction $I$ as well as the bit-flipped variants $"flip"(I, n)$ for each $0 #sym.lt.eq n < N$, where $"flip"(I, n)$ bit-flips the $n$th bit in $I$.
This produces dataflows for $N + 1$ instructions that we will generalize into an encoding.
The analysis is run separately for each of the $N + 1$ instructions.

Inferring dataflows consists of analyzing memory accesses and dataflows.
Analyzing memory accesses consists of finding a set of accesses $M$ as defined in Section~@sec:liblisa:overview that encompass all memory accessed by an instruction.
This makes it possible to reduce the CPU state to include just the parts of memory that are read or written by the instruction.
Analyzing dataflows consists of finding a set of source and destination tuples $(S, D)$ that accurately describes all data-dependencies between the input and output CPU state of the instruction.

The algorithm for identifying memory accesses is shown in @encoding-analysis:alg:memory-access-analysis.
It takes as input an instruction $I$ and produces the set of memory accesses $M$ performed by $I$. It makes use of three functions: #tt[FindPageFaults], #tt[FindAddressComputations] and #tt[AccessGeneratesPageFaultOnNextPage].

The function #tt[FindPageFaults] takes as inputs the instruction $I$ and the current set of memory accesess $M$.
It generates the set of page faults $P$ that happens when instruction $I$ is executed on a set of randomly generated CPU states where all accesses in $M$ are mapped.

The function #tt[FindAddressComputation] takes as input instruction $I$, the current set of memory accesses $M$ and a set of page faults $P$.
It aims to find an address computation $a$ that is consistent with all page faults $P$.
A computation is consistent with a page fault it the computation either returns the same address as the page fault, or if there is a computation in $M$ that already maps to the same page.

The function #tt[AccessGeneratesPageFaultOnNextPage] takes as input instruction $I$, the current set of memory accesses $M$, the new address computation $a$ and a size $n$.
It generates a CPU state which places the new access $a$ exactly $n$ bytes away from the end of a page, and executes instruction $I$ on this state.
It returns whether the execution of instruction $I$ caused a page fault at the first address of the next page.

#algorithm(title: "Memory access identification.", [
    #set align(left)
    #algorithmic(
        indent: 0.5em, // indentation for the algorithm
        vstroke: 0pt + luma(200), // vertical stroke for indentation guide
        line-numbers: true, // show line numbers
        line-numbers-format: x => [#x:], // change the line numbers format
        {
            import "@preview/algorithmic:1.0.7": *

            Comment([ *Input*: an instruction $I$ ])
            Comment([ *Result*: a set of memory accesses $M$ ])
            Procedure("IdentifyMemoryAccesses", ("I",), {
                Assign[$M$][$emptyset$]
                Assign[$P$][$"FindPageFaults"(I, M)$]
                While($P eq.not emptyset$, {
                    Assign[$a$][$"FindAddressComputation"(I, M, P)$]
                    Assign[$n$][$1$]

                    While($"AccessGeneratesPageFaultOnNextPage"(I, M, a, n)$, {
                        Assign[$n$][$n + 1$]
                    })

                    Assign[$M$][$M union { (a, n) }$]
                    Assign[$P$][$"FindPageFaults"(I, M)$]
                })

                Return($[M]$)
            })
        }
    )
]) <encoding-analysis:alg:memory-access-analysis>

@encoding-analysis:alg:memory-access-analysis infers memory accesses iteratively.
Each iteration, we generate a set of page faults $P$ that occur with the current set of memory accesses $M$.
If $P$ is not empty, this means that the instruction $I$ performs memory accesses that we have not covered in $M$.
We find a computation that is consistent with all page faults $P$, and then determine the size of the access by generating input states that place the access near the end of a page.
If we place the access too close to the end of the page, such that it does not entirely fit on the page, we will get a page fault.
By iteratively increasing the distance to the end of the page until the access fits on the page, we can determine the size of the access.
We then extend the set of memory accesses $M$ with the new computation $a$ and size $n$, and repeat this process.

After inferring all memory accesses, we can infer the dataflows.

#algorithm(title: "Dataflow analysis.", [
    #set align(left)
    #algorithmic(
        indent: 0.5em, // indentation for the algorithm
        vstroke: 0pt + luma(200), // vertical stroke for indentation guide
        line-numbers: true, // show line numbers
        line-numbers-format: x => [#x:], // change the line numbers format
        {
            import "@preview/algorithmic:1.0.7": *

            Comment([ *Input*: an instruction $I$ and a set of memory accesses $M$ for $I$ ])
            Comment([ *Result*: a set of dataflows $D$ ])
            Procedure("DataflowAnalysis", ("I", "M"), {
                Assign[$D_b$][$emptyset$]
                Assign[$"[df]"$][$"FuzzForDataflow"(I, M, D_b)$]
                While($"df" eq.not "None"$, {
                    Assign[$D_b$][$D_b union { "[df]" }$]
                    Assign[$"[df]"$][$"FuzzForDataflow"(I, M, D_b)$]
                })
                LineBreak
                Return([$"Reduce"(D_b)$])
            })
        }
    )
]) <encoding-analysis:alg:dataflow-analysis>

The algorithm for inferring dataflows is shown in @encoding-analysis:alg:dataflow-analysis.
It takes as input an instruction $I$ and the set of memory accesses $M$ for this instruction, produced by @encoding-analysis:alg:memory-access-analysis.
It makes use of two functions: #tt[FuzzForDataflow] and #tt[Reduce].

The function #tt[FuzzForDataflow] takes as input the instruction $I$, the set of memory accesses $M$, and the set of found byte-wise dataflows $D_b$.
It returns a dataflow $(b_s, b_d)$, which represents a dataflow between byte $b_s$ in the input state and byte $b_d$ in the output state.
We say that there is a dataflow $(b_s, b_d)$ if there is some input CPU state for which a change to the value of $b_s$ causes the value of $b_d$ in the output CPU state to change.
The function only returns dataflows that are not already present in the set of found byte-wise dataflows $D_b$.
It uses fuzzing to try and find a pair of CPU states which demonstrates the existence of a dataflow.
If no dataflow is found, it returns #tt[None].

The fuzzing strategy consists of generating a random CPU state, and then generating another state by randomly changing some part of the state.
This can be a single byte, a subset of all bytes not present in the sources in the hypothesis, or all bytes except some subset of the sources in the hypothesis.
We exclude some sources of the hypothesis to ensure that we can find sources for destinations that are already present in the hypothesis.
That is, if we already know that a modification in $b_s$ causes a change in $b_d$, we must generate pairs of states where $b_s$ is identical to be able to discover that a modification in $b_s'$ also causes a change in $b_d$.

The function #tt[Reduce] reduces the dataflows between individual bytes in the CPU state to dataflows between storage locations, by merging byte dataflows of consecutive bytes, and translating byte indices to storage location names.
It takes as input the set of found byte-wise dataflows $D_b$, and returns a set of dataflows $D$ as described in Section~@encoding-analysis:overview:encodings.
This makes the dataflows usable in encodings and reduces noise.
Because we rely on fuzzing, sometimes not all dataflows are found.
By merging dataflows, the chances of this showing up in the resulting dataflows are reduced.

=== Generalizing Dataflows into Encodings
We generalize an encoding from the set of inferred dataflows from the previous Section.
For each bit-flipped instruction $"flip"(I, n)$, we compare the dataflows and memory accesses against those of the original instruction $I$.

Bit-flipping has been shown to be effective for guiding disassembler fuzzing~@disasmfuzzing.
Rather than guiding a fuzzer, we use bit-flipping to determine which bits are likely to belong to parts of the encoding.
This requires more extensive analysis of the changes that occur when flipping a bit.

In modern general-purpose instruction sets like x86-64, bits in an instruction often serve a single purpose.
For example, there can be a bit in an instruction that is used in the selection of the source register.
That bit typically is not _also_ used for other things such as a memory computation or a destination register.
When changing those bits, only the source register changes.
This reduces the complexity of the instruction decoder in the CPU, as those bits can be wired directly to the register bank without further processing.
We check for changes that are common uses of bits that serve a single purpose:
 
+ If a register in the dataflows changes, the bit is a register-bit candidate
+ If the output of some dataflows changes, the bit is an immediate-bit candidate
+ If the offset of a memory access changes, the bit is an immediate-bit candidate
+ If a memory computation changes, the bit is a memory-computation-bit candidate
+ If more than one of the above apply, the bit is unknown

We form parts from using the candidates found from comparing the bit-flipped instruction variants.
Each candidate affects certain storage locations in the dataflows or memory accesses.
We consider candidates to be similar if they affect the same storage locations in the dataflows and memory accesses.
Each set of similar register-bit candidates forms a register part.
Consecutive and similar immediate-bit candidates from immediate value parts.
Each set of similar memory-computation-bit candidates form memory computation parts.
Two parts conflict if they both share one or more affected storage locations.
We repeatedly remove the smallest part until there are no conflicting parts.

For register parts, we additionally enumerate every value to determine the exact register.
We do this separately for each register part.
For example, if we have three register parts, each 4 bits in size, we will run per-instruction dataflow analysis on 33 more instructions, 11 for each register part.
The other five possible values for each register part have already been analyzed during the bit-flipping phase.

We do not aim to recover the exact encoding such as described in, for example, the Intel Reference Manual.
This would be impossible, as we infer encodings bottom-up, rather than top-down.
We also do not aim to identify every part in an encoding.
The primary goal is to produce encodings that make enumeration feasible.
This only requires identifying some subset of parts that is large enough to allow efficient skipping of instructions.


#example([
    Consider instruction $I = #tt[0100]$.
    Let us assume that we have inferred that it performs no memory accesses, and has the following dataflows:

    #grid(
        columns: (auto, auto, auto),
        inset: 2pt,
        tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
        tt[BX], $colon.eq$, $ballot_2(#tt[AX])$,
    )

    In order to generalize this dataflow into an encoding, we inspect the dataflows of the four flipped variants, determine the change compared to the original dataflow, and determine if the bit is a candidate for a part. This comparison is summarized as follows:
    
    #table(
        columns: (auto, auto, auto, auto, auto),
        align: (x, y) => if x == 1 { center } else { left },
        [Variant], [#tt[1100]], [#tt[0000]], [#tt[0110]], [#tt[0101]], 
        [Dataflows],
        [(Invalid)], 
        grid(
            columns: (auto, auto, auto),
            inset: 2pt,
            tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
            tt[AX], $colon.eq$, $ballot_2(#tt[AX])$,
        ), grid(
            columns: (auto, auto, auto),
            inset: 2pt,
            tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
            tt[BX], $colon.eq$, $ballot_2(#tt[CX])$,
        ), grid(
            columns: (auto, auto, auto),
            inset: 2pt,
            tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
            tt[BX], $colon.eq$, $ballot_2(#tt[BX])$,
        ),
        [Change], [N/A], [$#tt[BX] mapsto #tt[AX]$], [$#tt[AX] mapsto #tt[CX]$], [$#tt[AX] mapsto #tt[BX]$],
        [Location], [N/A], [Destination #tt[BX]], [Source #tt[AX]], [Source #tt[AX]], 
        [Candidate], [N/A], [Register-bit], [Register-bit], [Register-bit],
    )

    There are candidate bits for two parts: a 1-bit register part that determines the destination register, and a 2-bit part that determines the source register.
    These parts do not conflict.
    We therefore do not need to remove any of the parts.

    Finally, we also inspect the dataflows for #tt[0111] to fully cover the possible register mappings for the 2-bit part that determines the source register.
    From this information, we can build the encoding:

    #v(1em)
    
    #align(center, [
        // TODO: Alignment
        #grid(
            columns: (auto, auto),
            inset: 3pt,
            align: left,
            grid.cell(rowspan: 3, [ *Bitpattern:* ]),
            [#tt[0#underline[b]#underline[aa]]],
            [#tt[#underline[aa]]: $[
                #tt([00]) mapsto #tt[AX],
                #tt([01]) mapsto #tt[BX],
                #tt([10]) mapsto #tt[CX],
                #tt([11]) mapsto #tt[DX]
            ]$],
            [#tt[#underline[b]]: $[
                #tt([0]) mapsto #tt[AX],
                #tt([1]) mapsto #tt[BX]
            ]$],
            [ *Dataflows:* ],
            grid(
                columns: (auto, auto, auto),
                inset: 2pt,
                tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
                underline[#tt[b]], $colon.eq$, $ballot_2(#underline[#tt[aa]])$,
            )
        )
    ])
]) <encoding-analysis:ex:generalization>


=== Specializing Encodings
Specialization aims to fix any incorrect generalizations that might have occurred.
Dataflows are generalized into an encoding based on heuristics.
This happens without any verification: generalization is based on heuristics, it does not use observations.
Since generalization only looks at single bit-flips, more complex interactions between multiple bits are not accounted for.

The original instruction $I$ is used as the ground truth for specialization.
We try to find another instruction $I'$ also covered by the encoding, where the sources (i.e., registers or memory) can be assigned values such that at least one destination has a different output after executing $I$ compared to $I'$.
If we find such an instruction $I'$, the encoding is not describing the instruction correctly.
We fix this by removing bits from parts to ensure that the encoding no longer covers $I'$.

To determine which bit to remove, we first find many instructions using the method above.
We then find the index of the bit that most often differs from the original instruction $I$, and remove this bit.
To remove a bit, we simply replace it with the concrete value from $I$.
For example, consider the case where $I = #tt[00000000 11000001]$ which we have generalized into an encoding with bitpattern #tt[00000000 110#underline[bb]0#underline[aa]].
To remove the last bit, we replace it with the last bit of $I$, which is a 1: #tt[00000000 110#underline[bb]0#underline[a]1].
Additionally, the part mapping of the bitpatterns and the dataflows have to be updated accordingly to account for the change of #tt[#underline[aa]] into #tt[#underline[a]].

We use fuzzing to identify incorrect generalizations.
The fuzzing strategy consists of generating pairs of CPU input states that are identical except for the instruction that is executed.

#example([
  Consider the encoding from Example~@encoding-analysis:ex:generalization. Through fuzzing, we find the following two input-output examples:

  #align(center)[
      #table(
          columns: (auto, auto, auto),
          align: left,
          [
          Instruction], [Input state], [Output state],
          [
          #tt[0110]], [$#tt[CX] = 5$], [$#tt[BX] = 10$],
          [#tt[0010]], [$#tt[CX] = 5$], [$#tt[AX] = 37$],
      )
  ]

  According to the encoding, the value of #tt[BX] after executing #tt[0110] should be equal to the value of #tt[AX] after executing #tt[0010].
  This is not the case.
  Therefore, we have found an incorrect generalization.
  To resolve this, we need to repeatedly remove bits from parts until there we can find no more incorrect generalizations.

  We determine that in the cases where we find incorrect generalizations, $100%$ of the time bit 3 (counting right-to-left, starting at 1) is $0$, which is different from its value in the original bitstring ($0$).
  The other bits are different around $25%$ of the time.
  We therefore remove bit 3 from the encoding.
  This gives the following specialized encoding:

  #v(1em)

  #align(center, [
    // TODO: Alignment
    #grid(
      columns: (auto, auto),
      inset: 3pt,
      align: left,
      grid.cell(rowspan: 2, [ *Bitpattern:* ]),
      [#tt[01#underline[aa]]],
      [#tt[#underline[aa]]: $[
          #tt([00]) mapsto #tt[AX],
          #tt([01]) mapsto #tt[BX],
          #tt([10]) mapsto #tt[CX],
          #tt([11]) mapsto #tt[DX]
      ]$],
      [ *Dataflows:* ],
      grid(
          columns: (auto, auto, auto),
          inset: 2pt,
          tt[RIP], $colon.eq$, $ballot_1(#tt[RIP])$,
          tt[BX], $colon.eq$, $ballot_2(#underline[#tt[aa]])$,
      )
    )
  ])
]) 


== From Encoding to Semantics
We implement existing program synthesis techniques to demonstrate the amenability of encodings to automated synthesis.
Program synthesis consists of generating a program from a specification.
As we assume no access to the hardware designs of the CPU, the only specification we can generate are _input/output examples_ (I/O examples).
An I/O example is a tuple consisting of the inputs provided to the program, and the corresponding correct output.
For example, an I/O example for a function $f(x_0, x_1) = y$ might be $x_0 = 4, x_1 = 2, y = 6$.

For each encoding,
synthesis has a timeout of 7.5 minutes.
This timeout has been chosen such that it allows sufficient time for synthesizing more complex semantics, while keeping the runtime acceptable.
Because synthesis uses randomly generated I/O examples, runtime varies based on the quality of the I/O examples.
If synthesis failed or timed out, this might be because the first few I/O examples were low-quality.
This might have caused synthesis to spend most of the allotted time searching in the wrong direction.
Starting with a clean slate with different random I/O examples can resolve this.
Therefore, we re-run synthesis a second time if the first attempt failed or timed out.

An encoding consists of multiple dataflows.
Each dataflow can be synthesized independently.
We represent the dataflow as a function $ballot\(x_0, x_1, dots\) = y$, where $x_0, x_1, $ etc. are the sources of the dataflow, and $y$ is the destination.
We use program synthesis to find an implementation for function~$ballot$.

We need a synthesis algorithm that can operate on I/O examples, is efficient, and is suited for synthesizing CPU semantics.
By combining existing techniques, we construct such an algorithm.

We use Counter-Example Guided Inductive Synthesis (CEGIS)~@cegis @alur2018.
CEGIS consists of two parts, a _learner_ and an _oracle_.
The learner repeatedly forms hypotheses, and the oracle provides counterexamples to these hypotheses.
This process repeats until the hypothesis is correct, i.e., the oracle cannot present a counterexample.

Our learner is an I/O example-based synthesis algorithm.
It generates hypotheses based on the I/O examples it has received from the oracle.
Our oracle is a fuzzer that will verify the hypothesis against at most 2 million randomly generated input states.
It uses the CPU as the ground truth, and tries to find counterexamples that show that the hypothesis is not equivalent to the actual CPU behavior.

The fuzzer uses three random generation techniques: normal generation, generation with equalities and generation from interesting inputs.
Normal generation re-uses the random generation from encoding analysis, described in Section~@encoding-analysis:subsec:encoding-analysis.
Generation with equalities also uses the random generation from encoding analysis, but chooses one storage location at random and copies its value to another storage location chosen at random.
This produces an input state where two storage locations are equal.
Finally, generation from _interesting_ inputs randomly picks an interesting input state, and randomly modifies a storage location, a single byte in a storage location, or a single bit in a storage location.
An input state is interesting if it disproved any of the previous hypotheses.

Our learner uses decision trees to scale synthesis to larger problems, and uses _enumerative_ program synthesis to synthesize individual expressions in the decision tree.
We synthesize Boolean decision trees using a divide-and-conquer technique based on work by Alur et al.~@alur2017scaling.
Decision trees have conditions (integer expressions returning only 1-bit values) on non-leaf nodes, and integer expressions on leaf nodes.

Since we need to synthesize programs from only I/O examples, our only choice of search technique is _enumerative program synthesis_.
Rather than enumerating all possible programs from a grammar, we enumerate over programs derived from a list of _templates_.
A template is an expression that contains zero or more holes.
Synthesis consists of enumerating all possible ways to fill holes, for each template.
In contrast to synthesis using grammars, a hole can only be filled with a constant or an input.
We use separate lists of templates for integer expressions and conditions.

The choice for template-based synthesis is primarily motivated by performance benefits.
By using a set of templates that is known and enumerable at compile-time, we are able to compile the templates to machine code.
This significantly reduces the overhead of template evaluation, and increases synthesis performance.

We use 143 templates for integer expressions, and 553 templates for conditions (of which 351 are derived automatically from 39 integer expressions).
These templates are handwritten.
The integer expression templates consist of (combinations of) arithmetic operations such as addition or multiplication,
and logical operations, such as AND, OR, or bitshifts.
The Boolean templates primarily consist of zero checks, sign checks and parity computations derived from the integer expressions.
They also contain more generic conditions such as $\_ + \_ < (\_ << \_)$.
We see that these conditions end up being used, for example, to saturate addition ($A + B < (1 << 8)$).

Compared to Godefroid and Taly~@godefroid2012, we define many more templates.
This is explained by counting differences, scope differences and flexibility differences.
Godefroid and Taly's templates are parameterized by operand size and operation, while we use separate templates for each combination of parameters.
For example, Godefroid and Taly's "Bit-wise group" flag output template corresponds to around 30 of our templates.
While Godefroid and Taly's scope is limited to x86-32 ALU instructions, our scope is all userspace non-floating point instructions.
Additionally, we include x86-64 extensions such as BMI that Godefroid and Taly do not support.
Godefroid and Taly's flag templates are tailored to the specific operation that is being synthesized.
For example, all flag outputs of Godefroid and Taly's "Bit-wise group" must be a combination of up to three Boolean terms over the main output.
Our templates are defined independently of a main output, which is necessary because we do not have access to a disassembler library to identify the main output.

Expressions are synthesized by filling in templates with holes.
Each template contains zero or more holes.
A hole can be filled with a constant or an input $x_i$.
Although individual expressions are constrained to predefined templates, the combination of multiple templates in decision trees makes this approach efficient.
For example, a conditional jump instruction might perform a computation similar to $*"if"* (#sym.not a #sym.and #sym.not b #sym.plus.o c) #sym.plus.o d *"then"* x + n *"else"* x + 2 *"fi"*$ to update the instruction pointer.
It would be infeasible to generate such an expression in one go.
However, because we generate a decision tree we can split this expression into six sub-expressions: $a$, $b$, $c$, $d$, $x + n$ and $x + 2$.
All of these expressions are very easy to synthesize.

An expression consists of function calls and terms.
Expressions always operate on signed 128-bit integer values.
Function calls are simple built-in operations, e.g., addition or bit shifting.
Terms are either constant values or inputs.
Constant values $C$ can be $0..16$, $8n-1$ and $8n$, where $1 #sym.lt.eq n #sym.lt.eq 8$.
An input is the value of a source, i.e., $x_i$, and an interpretation.

Dataflow sources and destinations can be integer values smaller than 128 bits (e.g., 64-bit general-purpose registers) or byte sequences (e.g., memory). 
Therefore, inputs must be converted to 128-bit integer values, and outputs must be converted back to the right size.
Inputs can be interpreted as signed or unsigned, and big-endian or little-endian values.
Outputs are converted back by taking the lower $N$ bits of the 128-bit output of the expression.
When a destination is a byte sequence, the output can either be encoded to bytes as big-endian or as little-endian.
