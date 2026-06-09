---
tool: "Dasgupta et al."
---

# OF incorrect for RCLB/RCRB

The overflow flag (OF) of RCLB/RCRB is undefined when the masked rotate count is not 0 or 1. However, Dasgupta et al. specifies the OF as undefined when the masked rotate count *modulo the operand size + 1* is not 0 or 1.