---
tool: "Dasgupta et al."
---

# `CMPS` performs comparison incorrectly
The CMPS variants perform a comparison by setting flags according to `Mem2 - Mem1`, but they should be set according to `Mem1 - Mem2`.