#import "../theme.typ": *

= Implementation
In this section we describe the implementation of #sem86.
We aim to build an emulator that is capable of booting real-world operating systems, such as Windows 98, XP and 7, loading semantics at runtime from an input file.
Booting these operating systems requires executing hundreds of millions (Windows 98) up to tens of billions of instructions (Windows 7).
Therefore, emulation performance is extremely important.

#sem86 provides implementations of all necessary hardware to run normal operating systems.
This includes PIT, PIC, CMOS and PS/2 devices, PCI,
a VBE-compatible VGA card,
as well as optional hardware such as the ES1370 sound card and the and the NE2000 network card.
We provide support for IDE disks, ATAPI CD-ROM drives, and floppy disks.
For more modern operating systems, basic APIC support is also available.

Instruction semantics are loaded from a data file at runtime.
Other aspects of the architecture, such as the execution loop, paging, control registers, interrupt handling and system hardware are not specified in the semantics, and are hard coded in the emulator itself.
While this reduces the expressivity of the semantics, it makes it possible to implement performance optimizations such as the fast memory technique or caching.

== Semantics
An emulator requires (1) a mapping from bitstrings to semantics, i.e., an _instruction decoder_, and (2) an intermediate language in which semantics can be specified.

=== Instruction Decoding
x86 instruction decoding typically requires an expressive language:
since x86 has variable-length instructions, extra instruction bytes may need to be fetched during decoding.
It is not possible to fetch all potentially-needed instruction bytes in advance,
as page faults can reveal how far ahead the instruction decoder is fetching bytes.
//  https://github.com/intelxed/xed/commit/7561f549d787edc55949b671dee2255a8435741a

Additionally, x86 instructions can use _prefixes_: bytes that can be prefixed once or multiple times to the instruction bitstring.
Prefixes can, for example, affect register operands, change address- and operand size or override the segment register used by a memory access.
There are even corner-cases where some prefixes behave differently on different CPUs~@sandsifter.
Thus, instruction decoding should not be hard-coded.

Our implementation instead uses _bitpatterns_ to match instructions.
A bitpattern is a sequence of fixed bits (0, 1) and parts (a, b, c, #sym.dots).
An instruction bitstring is decoded by matching it against the bitpattern.
The result of successful decoding is a mapping of parts to matched values.

#example[
  The bitpattern #tt[IMUL] instruction is #tt[00001111 10101111 11#underline[bbb]#underline[aaa]]. Here, the parts #underline[bbb] and #underline[aaa] represent registers.

  To decode an instruction, for example #tt[00001111 10101111 11001010], we first verify that all fixed bits match the instruction. Then, we compute a mapping of parts to their corresponding values. For this example, part #tt[aaa] is #tt[010] and part #tt[bbb] is #tt[001].
] <sem86:ex:imul1>

To decode instruction prefixes, we use finite state automata to compute a _shortest equivalent prefix sequence_.
We then add separate bitpatterns and semantics for each possible combination of prefixes.


#example[
  The #tt[IMUL] instruction may optionally take a data-size override prefix (#tt[66]) which reduces operand sizes to 16-bit instead of 32-bit (or vice versa when the CPU is running in 16-bit mode). This means that there will be two entries for this instruction: one with a data-size override prefix (the byte sequence #tt[66]), and one without (the empty byte sequence $epsilon$). Each will have a state machine to map all possible equivalent prefix sequences:

  \

  $ 
  { #tt[66], #tt[662E], #tt[2E66], #tt[3E66], dots } mapsto #tt[66]
  $

  $ 
  { epsilon, #tt[2E], #tt[3E], dots } mapsto epsilon
  $

  \

  For example, when encountering an instruction prefixed with #tt[2E], we first reduce this to the empty byte sequence $epsilon$ (according to the mapping provided by the finite state machine), and then match the rest of the instruction bitstring against the bitpattern.
]


Even though this approach is much less expressive than Turing-complete languages typically used for instruction decoding, it is sufficient to represent all x86 instructions.
The downside of this approach is that it is not as compact as hand-crafted solutions: a single instruction form like #tt[IMUL] may be encoded with dozens of different finite state machines and bitpatterns.
In practice this is not a problem, as caching and JIT compilation mean that instruction decoding plays no role in emulator performance.

=== Intermediate Language
We encode instruction semantics in a simple intermediate language, of which the grammar is shown in @sem86:fig:semantics-grammar.
The grammar consists of assignments, if-statements, memory- and port I/O accesses, segment descriptors loads, and various exceptional early returns.
All values are 128-bit integers, which means the semantics do not require typing.
Operators consist of typical integer arithmetic, bitwise operations and floating point arithmetic.

We intentionally do not implement constructs such as loops or gotos.
Absence of these constructs makes it trivial to translate this intermediate language to equivalent operations in other specification languages, SMT, or provers.

Expressions to compute memory addresses are restricted to a sum of terms, where each term consists of a single register, shifted right by a constant, and then multiplied by a constant.
This is sufficient to model all possible memory accesses on x86.

#html-compatible-figure([
  #let ref(name) = [ $⟨italic(name)⟩$ ]
  #let rule(name, ..options) = [
    #set align(left + horizon)
    #grid(
      columns: (auto, auto),
      inset: 3pt,
      grid.cell(colspan: 2)[ #ref(name) ::= #options.at(0) ],
      ..options.pos().map(opt => (
        [
          #h(1em) | 
        ],
        opt,
      )).flatten()
    )
  ]

  #block[
    #rule(
      "state-val",
      ref("register"),
      ref("memory"),
    )

    #rule(
      "val",
      ref("const"),
      $"SignExt"[N](#ref("state-val"))$,
      ref("state-val"),
      ref("temp-var"),
    )

    #let v = ref("val")
    #rule(
      "statement",
      v,
      $"op"(#v, #v, dots)$,
      $"'IF'" #v "'THEN'" #ref("statement")* "'ELSE'" #ref("statement")* "'FI'"$,
      $"Exception"(e, #v)$,
      $"Handler"("id", #v)$,
      $"PortIn"("size", #v, #v)$,
      $"PortOut"("size", #v, #v)$,
      $"ReadDescriptor"(dots)$,
    )
  ]
], framed: true, caption: [
  The grammar of #sem86's semantics.
  By keeping the grammar simple, it is easier to implement translation to other languages such as LLVM IR or SMT-LIB.
], label: <sem86:fig:semantics-grammar>)

#example([
  We show the semantics for the #tt[IMUL] instruction in @sem86:fig:imul-semantics.
  There are two placeholders that depend on the output of instruction decoding: "#tt[\<a\>]" and "#tt[\<b\>]".
  These will be substituted with the register corresponding to the value of the respective parts.

  #html-compatible-figure([
    #set raw(
      syntaxes: "semantics.sublime-syntax",
    )

    ```sem86
    tmp0 := Mul(SignExt[32](<a>), SignExt[32](<b>))
    <a> := tmp0
    tmp1 := And(tmp0, 0xFFFFFFFF80000000)
    tmp2 := Xor(tmp1, 0xFFFFFFFF80000000)
    tmp3 := ite(tmp1, tmp2, tmp1)
    Flag(CF) := ite(tmp3, 0x1, 0x0)
    Flag(OF) := Flag(CF)
    Flag(AF) := 0x0
    Flag(SF) := SelectBit(31)(tmp0)
    Flag(PF) := Parity(tmp0)
    tmp4 := And(tmp0, 0xFFFFFFFF)
    Flag(ZF) := IsZero(tmp4)
    ```
  ], caption: [
    The semantics for the IMUL instruction operating on two 32-bit register operands.
    First, the product is computed and stored in #tt[tmp0] and copied to destination register #tt[a].
    Next, all flags are updated.
    Updates to the AF, SF, PF and ZF are undefined.
    In this example, the flags are updated to reflect the result of the multiplication.
  ], label: <sem86:fig:imul-semantics>)
])

The semantics for each instruction also store control-flow behavior.
Control-flow behavior can be sequential, relative near jumps, and semantics-defined jumps.
Sequential means that the program counter is incremented by the instruction length.
Relative near jumps add a constant offset to the program counter.
Optionally, adding this constant offset can be conditional on a value computed by the semantics.
Semantics-defined jumps indicate that the program counter is updated by the semantics in a non-standard way.
These are used to implement operations such as jumps to absolute offsets or long jumps.

Having this control-flow information available in a format that does not require analysis of the semantics themselves, makes it easy to determine the control flow of instructions.
This is used, for example, to accurately determine the next instruction after a conditional jump.
Without explicit control-flow information, we would have to inspect the program counter after each instruction to determine whether the jump was taken or not.
However, since the control-flow behavior explicitly defines what the condition for taking the jump is, we can use this condition instead, which allows for more performant code generation.

== Instruction Execution
The basic execution loop of #sem86 is a cached interpreter.
When new instructions are executed, they are stored in a cache data structure as a tuple of a function pointer to the instruction execution function and a decoded representation of the instruction bitstring.

The instruction execution function is compiled by translating the instruction semantics to LLVM IR, and compiling it with LLVM.
This generates functions that are similar to the manual implementations found in Bochs~@bochs.
In our current implementation these functions are compiled on-the-fly, but could also be compiled ahead of time.

The cache data structure also contains a pointer to the instruction that will be executed next.
This means that typically, no page walk, memory read, or instruction decode is necessary to determine which instruction to execute next.
Executing the next instruction typically only requires following a pointer and an indirect call to the function pointer of the instruction execution function.

There are two conditions under which the cache becomes invalid: memory may be overwritten, or page mappings may change.
We handle both of these conditions with page granularity.

Unlike many other architectures, x86 does not require the use of an instruction cache invalidation instruction to indicate that the instruction cache should be cleared.
Instead, it is expected that any memory writes are immediately reflected in the instruction cache.
When a page containing cached instructions is written, we mark it as 'dirty'.
For dirty pages, the cache re-verifies memory contents for every executed instruction.
This ensures that changed instructions are detected immediately.

When page mappings change, physical memory may have moved to different logical addresses.
On x86, operating systems are required to explicitly signal that page mappings have changed by executing specific instructions.
When this happens, we clear cached pointers to instructions on any page that has changed.
This means that the execution loop will re-walk the page table to redetermine the correct pointer.
Pointers between instructions on the same page can remain unchanged, as a page mapping always maps an entire page.

=== Memory
We implement the _fast memory_ technique.
This technique uses the host's MMU to accelerate memory accesses.
When starting, we pre-allocate an entire 4 GiB memory region and a metadata array.
The allocated memory region covers the entire x86 instruction space.
This means that if the correct memory is mapped into the allocated memory region,
a memory access could be performed by simply adding the emulated address to the start of the memory region.
The metadata array contains flags for each page, that indicate whether memory reads and writes can be performed directly on the mapped memory region.
When memory needs to be mapped at a certain location, we use #tt[mmap] to place memory at the right location inside the 4 GiB memory region and update the metadata.

For often-executed code pages, we rely on _just-in-time_ (JIT) code generation to compile sequences of instructions into native code.
We choose page-wide code generation because this allows for simple cache invalidation.
Assuming code pages are not written, they can only be moved in their entirety through page remapping.
This means that, although the code on the page may be moved to a different memory location in its entirety, the instructions on a single page, as well as relative jumps, will remain the same.

=== JIT
For JIT code generation, we use off-the-shelf LLVM.
LLVM compilation is too slow to be executed in the main execution loop,
so compilation is instead done on dedicated threads.
The semantics of all instructions in a sequence are concatenated and transformed to LLVM IR, which is then compiled to a single function by LLVM.
For jumps to other instructions on the same page, we generate inline tail calls.
This avoids the overhead of the cache lookup in the interpreter loop.

== Bisection and save states
Bisection consists of performing a binary search over some search space, for example the number of instructions executed, to find the point where a change in execution occurs#footnote([We borrow this term from software engineering~@bisect, where bisection is typically used to identify which change introduced a bug, for example with #tt[git bisect].]).
In Section~@sem86:sec:results we use it to analyze a toy malware sample that attempts to detect whether it is running in an emulator using undefined behavior of instructions.

The speed of bisection depends on how quickly one can determine whether a certain point in the search space exhibits the bug or not.
If a full operating system needs to boot before being able to determine this,
it can take a long time to search through billions of instruction executions.

#sem86 implements _save states_, i.e., capturing and storing the current CPU, memory, and system hardware state.
This save state can then be stored to memory or disk, and be used later on to resume execution.
The save states can be configured to also include any changes written to disk.
This allows save states to be used to rewind back to an earlier point in time.

Since save states can rewind execution to earlier points in time, save states can be used to speed up bisection.
Rather than restarting the emulator from scratch, bisection can resume from a save state.
