---
tool: "Unicorn"
status: "fixed"
tracker: "https://github.com/unicorn-engine/unicorn/issues/1931"
---

# RISC-V64 errors when calling `emu_start` with `count = 1` at end of page
When executing a single instruction at the end of a page with the following page unmapped, unicorn would return a memory error (`FETCH_UNMAPPED`) instead of stopping.
This was caused by Unicorn decoding the next instruction, before checking if it should interrupt execution.
Because of this, a fetch to the unmapped page would always occur after executing the single instruction,
causing an error to be returned.