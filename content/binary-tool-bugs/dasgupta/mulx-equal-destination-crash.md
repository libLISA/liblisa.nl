---
tool: "Dasgupta et al."
---

# Crash when MULX is executed with identical destination registers
The `MULX` instructions write a result to two destination operands. The destination operands can be equal. Dasgupta et al.'s semantics have not taken this possibility into account, causing the K prover to crash when `MULX` with equal destination operands is executed.