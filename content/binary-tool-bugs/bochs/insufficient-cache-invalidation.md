---
tool: "Bochs"
status: "fixed"
tracker: "https://github.com/bochs-emu/Bochs/issues/567"
---

# Insufficient cache validation causes incorrect page faults
Bochs uses an instruction cache to speed up instruction execution.
This instruction cache needs to be cleared whenever the contents in memory change, or if the page table is updated.

One particular edge-case is instructions that cross page bounds.
For example, a 3-byte instruction at `0x1fff` covers both page `0x1___` and `0x2___`.
When the page `0x2___` was unmapped, the cache entry for the instruction at `0x1fff` failed to be invalidated.
This caused Bochs to trigger page faults too late: instead of a page fault at `0x2000` when the instruction at `0x1fff` was executed, a page fault at `0x2002` would occur when the following instruction was executed.