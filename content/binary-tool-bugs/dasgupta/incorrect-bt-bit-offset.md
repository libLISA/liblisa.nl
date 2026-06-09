---
tool: "Dasgupta et al."
---

# Incorrect bit offset for `BT`/`BTS`/`BTR`/`BTC` with memory operand

In all bit test variants (`BT`/`BTS`/`BTR`/`BTC`) on memory with a register bit offset, the bit offset is computed incorrectly. The bit offset is converted to a byte offset by shifting right by 3, then zero-extending the result to 64 bits. It should be sign-extended, to preserve the sign bits of negative offsets.