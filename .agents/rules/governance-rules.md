---
trigger: manual
---

# Governance Rules

## The Surgical Strike Mandate (Preventing Comprehension Debt)
- **Problem**: "Just Regenerating" entire files destroys institutional context (hidden edge cases, vendor quirks) and creates massive Comprehension Debt for human reviewers.
- **Rule**: You are STRICTLY FORBIDDEN from rewriting an entire file or massive function from scratch just to implement a missing feature.
- **Action**: You MUST use surgical, targeted edits. Preserve the existing code structure, even if it looks slightly "messy." Only re-architect lines if specifically ordered to perform a refactor.

## The Anti-MacGyver Protocol (STRICT)
Before implementing ANY local utility behavior, routing logic, data transformation, or UI component:
- **Rule**: You MUST execute a `grep_search` within `server/Common/` or `lib/_shared/`.
- **Purpose**: You must prove you are using the project's existing "Stove" (canonical tools) before you are allowed to build a "Lighter" (custom local logic).
- **Prohibition**: Do not write custom date parsers, unauthorized navigation extensions, or ad-hoc security guards. Use what exists.

## Self-Maintenance & Governance
### Post-Task Reflection & Self-Curation (ALWAYS-ON)
After completing any significant implementation, debug, or refactor, assess whether a new LESSON, GOTCHA, or PATTERN was discovered that must be preserved.

1. **Target File**: Update `.agents/rules/project-gotchas.md`. Do NOT use `AGENTS.md`.
2. **Curation Rules (Preventing Bloat & Comprehension Debt)**:
   - **DO ADD**: Highly specific, project-breaking quirks or vendor-specific edge cases. This acts as our defense against future AI "cleanups" breaking production.
   - **DO ADD**: Architectural decisions that deviate from standard tutorials.
   - **DO ADD**: Undocumented library bugs or workarounds specific to this stack.
   - **DO NOT ADD**: Generic C#, Dart, or Flutter knowledge.
   - **DO NOT ADD**: One-off typos or syntax errors that the compiler caught.
   - **DO NOT ADD**: Features or business logic already documented in `platform-rules.md`.
3. **Self-Prune**: Before finishing, review `.agents/rules/project-gotchas.md`. Consolidate duplicates, delete outdated rules, keep the file lean.
