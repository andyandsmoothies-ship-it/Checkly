---
name: Governance Rules
description: Project-specific coding governance — shared-code reuse mandate and self-curation rules.
trigger: always_on
---

# Governance Rules

> The Surgical Strike Mandate (no full file rewrites) is defined globally in `GEMINI.md §2`.
> The Learning Loop (hypothesis tagging, knowledge extraction) is defined globally in `GEMINI.md §4`.

## The Anti-MacGyver Protocol (STRICT)
Before implementing ANY local utility, routing logic, data transformation, or UI component:
- **Rule**: Run `grep_search` within `server/Common/` or `lib/_shared/` first.
- **Purpose**: Prove you are using the project's existing canonical tools before building custom logic.
- **Prohibition**: No custom date parsers, unauthorized navigation extensions, or ad-hoc security guards.

## Post-Task Self-Curation (ALWAYS-ON)
After any significant implementation, debug, or refactor, assess whether a new lesson was discovered.

1. **Target file**: `.agents/rules/project-gotchas.md`. Do NOT use `AGENTS.md`.
2. **DO ADD**: Project-breaking quirks, vendor-specific edge cases, architectural deviations.
3. **DO NOT ADD**: Generic C#/Dart/Flutter knowledge, one-off syntax errors, business logic already in `platform-rules.md`.
4. **Self-Prune**: Consolidate duplicates, delete outdated entries. Keep the file lean.
