---
tool: "Unicorn"
status: "fixed"
tracker: "https://github.com/unicorn-engine/unicorn/issues/1813"
---

# ARM64 executes wrong instruction when pc=`0xFFFFFFFFFFFFFFFC`
When an instruction was placed and executed at the highest possible address, `0xFFFFFFFFFFFFFFFC`, and then unmapped, it wasn't properly removed from caches.
When later placing a new instruction at `0xFFFFFFFFFFFFFFFC` and executing it, the old instruction would be executed instead.