---
tool: "Dasgupta et al."
status: "fixed"
tracker: "https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=2f399d995b59a522c2739c0ab163c501c082cafb"
---

# `XCHGL` is disassembled incorrectly
The instruction `XCHGL EAX, EAX` can be encoded as both `87C0` and `90`. The second encoding has the semantics of `NOP` (do nothing), while the first has the semantics of `XCHGL` (set the upper 32 bits of `RAX` to zero). `objdump`, the disassembler used by Dasgupta et al. incorrectly disassembles `90` with a `REX` prefix as `XCHGL` instead of `NOP`."

This bug [has since been fixed in binutils](https://sourceware.org/git/?p=binutils-gdb.git;a=commit;h=2f399d995b59a522c2739c0ab163c501c082cafb).
Please note that older versions of Ubuntu ship old versions of binutils that still contain this bug. You will need a version newer than Ubuntu 22.04.