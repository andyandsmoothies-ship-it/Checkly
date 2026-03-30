---
name: Environment Rules
description: System rules for Windows shell execution to prevent interactive terminal hanging.
trigger: always_on
---

# Environment Rules

> Shell execution rules live in `GEMINI.md §1`. Git command rules live in `GEMINI.md §8`.

**Quick reference:**
- Always prefix commands with `cmd /c` — ensures EOF signal is sent.
- Chain commands with `;` inside one `cmd /c` call. Never use `&&`.
- No interactive shells. If a persistent session is needed, use `cmd /k` with a self-terminating command.
