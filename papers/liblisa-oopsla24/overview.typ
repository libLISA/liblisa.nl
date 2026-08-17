#import "../theme.typ": *

= Overview <sec:liblisa:overview>

The input-output relations of #libLISA are depicted in @encoding-analysis:fig:io-relations. It uses a _CPU observer_, and produces a set of _encodings_, as well as _semantics_ for each encoding.

#html-compatible-figure([
  #image("../imgs/overview.pdf")
], caption: [
  The input-output relations of #libLISA.
]) <encoding-analysis:fig:io-relations>

== CPU Observers <encoding-analysis:cpu-observers-desc>
A CPU executes _instructions_: bitstrings of $8n$ bits.
Examples are the bitstrings #tt[00000000 11011000] and #tt[01000000 00000000 11011000], which correspond to the human description #tt[ADD AL, BL].

A CPU instruction operates on a _CPU state_.
CPU state consists of all stored data a CPU can access: registers, flags, memory, and internal microarchitectural state like caches.
We only need a small part of the CPU state for our analysis.
A CPU state is represented as a bitstring.
That bitstring contains the contents of in-scope registers, flags and memory.
We only store memory areas when we have determined that this memory is accessed, as it would be infeasible to store all $2^{64}$ bytes of memory a 64-bit CPU could access.
A CPU observer is a function that takes as input an instruction and a CPU state, and produces as output a new CPU state.

Our CPU state representation for x86-64 contains 769 bytes (excluding memory). It includes general-purpose registers (#tt[RAX]..#tt[R15]), #tt[RFLAGS], #tt[FS] and #tt[GS]. It also includes state from processor state components 0 (x87), 1 (SSE) and 2 (AVX): the 16 #tt[YMM] registers (including the exception flags and #tt[DAZ] from the #tt[MXCSR] register), and the #tt[ST]/#tt[MMX] registers (including #tt[FSW] and #tt[FTW]).

The x86-64 CPU state representation does not contain unused segment registers (#tt[CS], #tt[DS], #tt[SS], #tt[ES]) or state from other processor state components not mentioned above (e.g., virtualization registers, MPX, or AVX-512).

Anything not listed above is not part of the CPU state.
It is therefore not observable.
This does not mean that instructions using this state cannot be analyzed.
Instead, the resulting semantics describe the instruction as if the parts of the CPU state that are not in our CPU state representation do not exist.
For example, the semantics for a #tt[CLFLUSH] (cache flush) instruction will look like an instruction that does nothing.

== Encodings and Semantics <encoding-analysis:overview:encodings>

We introduce the concept of an _encoding_: a group of instructions that differ only by operands.
The operands must remain of the same type, i.e., registers, flags, immediates or memory.
In order to obtain an encoding, it must have been established what the operands are, and thus what the in- and outputs of the group of instructions are.
An encoding consists of a _bitpattern_ (for grouping instructions), as well as _dataflows_ (for operand identification).

#example[
  Consider the x86-64 instruction #tt[00000000 11011000].
  An encoding contains the following information:

  #v(5mm)

  #grid(
    columns: (auto, auto),
    row-gutter: 0.7em,
    column-gutter: 1cm,
    grid.cell(rowspan: 3, [*Bitpattern:*]), [
      #tt[00000000 110#underline[bb]0#underline[aa]]
    ],
    [ #tt[#underline[aa]]: $[#tt[00] mapsto #tt[RAX], #tt[01] mapsto #tt[RCX], dots]$ ],
    [ #tt[#underline[bb]]: $[#tt[00] mapsto #tt[RAX], #tt[01] mapsto #tt[RCX], dots]$ ],
    [*Dataflows*:], [
      #grid(
        columns: (auto, auto, auto),
        column-gutter: 1em,
        row-gutter: 0.6em,
        [ #tt[#underline[aa]] ],  [ #sym.colon.eq ], [ $ballot_1(#tt[#underline[aa]], #tt[#underline[bb]])$ ],
        [ #tt[RIP] ],             [ #sym.colon.eq ], [ $ballot_2(#tt[RIP])$ ],
        [ #tt[CF] ],              [ #sym.colon.eq ], [ $ballot_3(#tt[#underline[aa]], #tt[#underline[bb]])$ ],
        [ #tt[ZF] ],              [ #sym.colon.eq ], [ $ballot_4(#tt[#underline[aa]], #tt[#underline[bb]])$ ],
      )
    ]
  )
  
] <encoding-analysis:ex:encoding>



To formalize these notions, we introduce various concepts, summarized in @encoding-analysis:tab:summary.
Immediate values and registers (and flags) are straightforward.
An _address computation_ of type $A$ is a function over registers and immediate values (e.g, $#tt[RAX] + 4*#tt[ECX]$).
A _memory access_ of type $M$ is a tuple with an address computation and a size.

#html-compatible-figure([
  #set align(left + horizon)
  #table(
    columns: (auto, auto),
    inset: 2mm,
    stroke: none,
    align: left + horizon,
    table.header(
      [ Component ], [ Type ],
    ),
    [ Immediate Value      ], [ $I$  ],
    [ Register / Flag      ], [ $R$  ],
    [ Address Computation  ], [ $A$  ],
    [ Memory Access        ], [ $M = A times NN$ ],
    [ Part                 ], [ $P = [NN]$ ],
    [ Bitpattern           ], [ $B = P times [BB] harpoon.rb (I union R union A)$ ],
    [ Destination          ], [ $D = P union R union M$  ],
    [ Source               ], [ $S = D union I$ ],
    [ Dataflow             ], [ $F = D times {S}$ ],
    [ Computation          ], [ $C$ ],
    table.hline(),
    [ Encoding             ], [ $E = B times [F]$ ],
    [ Semantic             ], [ $Sigma = E times [C]$ ],
    table.hline(),
  )
], caption: [
  The components of #libLISA's instruction semantics
], kind: "table", supplement: "Table") <encoding-analysis:tab:summary>

#paragraph[Bitpatterns]
The bitpattern identifies _parts_ of the bitstring, as well as the constituents these parts are mapped to, given concrete instantiations.
We name the parts using underlined letters.
Formally, a part can be modeled as a list of indices within the bitstring.
A _bitpattern_, then, is a mapping from parts and bitstrings to constituents: either immediate values, registers or address computations.
Reconsidering @encoding-analysis:ex:encoding, we formally have the parts $[0,1]$ and $[3,4]$  and the bitpattern:

#grid(
  columns: (auto),
  inset: 1mm,
  [
    $
    ([0,1], #tt[00]) mapsto #tt[RAX],
    ([0,1], #tt[01]) mapsto #tt[RCX],
    dots
    $
  ],
  [
    $
    ([3,4], #tt[00]) mapsto #tt[RAX],
    ([3,4], #tt[01]) mapsto #tt[RCX],
    dots
    $
  ],
)

However, we use notation #underline[aa] as in @encoding-analysis:ex:encoding when possible.

#paragraph[Dataflows]
A _dataflow_ identifies a list of _sources_ that are used as inputs to a computation that produces a value stored in a _destination_.
Destinations are represented by parts, registers, or memory accesses.
Sources can be immediate values as well.
A dataflow can thus be instantiated using the part mapping of the bitpattern.
Note that it does not define the computation that actually occurs. 
In @encoding-analysis:ex:encoding, these computations thus have been denoted with undefined boxes.

The generated _semantics_ consist of encodings together with defined _computations_ for all dataflows.
These computations describe how new values for destinations are computed using a set of sources.
Effectively, the boxes in @encoding-analysis:ex:encoding are replaced with actual functions.

#example(title: "Semantics")[
  The semantics for the encoding from @encoding-analysis:ex:encoding are as follows:
  $
  ballot_1(x, y) &= x + y mod 256\
  ballot_2(x)    &= x + 2\
  ballot_3(x, y) &= x + y > 255\
  ballot_4(x, y) &= (x + y mod 256) = 0\
  $
] <encoding-analysis:ex:semantics>

Normally, instructions increment #tt[RIP] by the instruction length to advance to the next instruction.
Branch instructions are considered as normal instructions that update #tt[RIP] by (conditionally) incrementing #tt[RIP] with the jump offset.
Repeating instructions, such as #tt[REPNZ STOSB], perform one iteration of the repetition at a time, but do not increment #tt[RIP] as long as the repeat condition holds.

=== Scope <encoding-analysis:subsec:scope>
We restrict the enumeration scope to keep the runtime feasible.
We exclude instructions with the following prefixes from being analyzed: 
    #tt[REPNZ] (#tt[F2]), 
    #tt[REPZ] (#tt[F3]),
    segment overrides (#tt[26], #tt[2E], #tt[36], #tt[3E], #tt[64], #tt[65]),
    and data overrides and address size overrides~(#tt[66], #tt[67]).
We enforce an ordering on instruction prefixes: a lock prefix (#tt[F0]) must always appear before #tt[REX] (#tt[40]-#tt[4F]) prefixes.

The primary reason for the restrictions on prefixes is running time.
These prefixes can appear in front of any (non-VEX prefixed) instruction.
Even when excluding invalid sequences of prefixes, including these prefixes would increase runtime by at least a factor of $84 times$.
Segmentation, looping instructions, and data and address size overrides are excluded because these are the least commonly used prefixes.
Four out of six segment registers are hard-coded to 0, while the other two have limited uses.
The looping prefixes can only be applied to a handful of instructions, and are ignored for all other instructions.
The data size overrides are used for legacy encodings of SSE operations and 16-bit arithmetic.
The address size overrides are only relevant when using 32-bit pointers. 
As shown in @encoding-analysis:raw-counts in @encoding-analysis:sec:results, the scope still covers $97.36\%$ of instructions found in Linux binaries.

Furthermore, instructions are deemed out of enumeration scope in the following cases: they

+ perform a variable number of memory accesses,
+ do not perform the memory accesses in a fixed order,
+ always fault (e.g., with the undefined instruction exception #tt[UD]),
+ access registers not included in the CPU state representation described in @encoding-analysis:cpu-observers-desc (e.g., #tt[MXCSR]),
+ perform operations involving segment selectors (e.g., #tt[LAR], #tt[LSS]),
+ require privileges (i.e., they do not run in CPU ring 3)
+ save or load CPU state (e.g., #tt[XSAVE] or #tt[FRSTOR])

The rationale behind this scope is a trade-off between the additional implementation complexity and additional running time that adding support for a larger scope would entail, versus the yield.
For example, implementing support for a variable number of memory accesses is very hard and will likely impact the running time, but to the best of our knowledge there is only a single instruction in the x86-64 architecture that exhibits such behavior.

We would like to stress that, even if instructions are out of enumeration scope, they can still be analyzed on-the-fly.
For example, if one wants to analyze a binary and encounters an instruction that is outside the enumeration scope, semantics for this instruction can still be generated on-the-fly, as long as it is within synthesis scope.
We demonstrate this in @encoding-analysis:sec:emulation.
 
We do not synthesize semantics for instructions that perform floating-point arithmetic.
We exclude these, because floating point operations can be approximate.
We found two approaches in related work.
The first consists of using uninterpreted functions and leaving the exact semantics up to the user~@dasgupta2019.
This is not suitable for #libLISA, as it is impossible to synthesize uninterpreted functions.
The second is to define floating-point semantics in terms of the semantics of floating-point instructions~@strata.
We considered this unsuitable for #libLISA, as this means the same semantics might produce different results on different CPUs.

For all other enumerated encodings, i.e., all encodings not using floating-point operations, we expect synthesis to produce semantics. However, this may fail, e.g., due to a time-out (we have a bound of 2 tries of at most 7.5 minutes per encoding).