---
name: Orchestration Standards
description: Rules for AI agents on how to run workflows, manage context decay, load skills, and perform pre-flight checks.
trigger: model_decision
---

# Orchestration Standards

## Mandatory Integrity Audit & Context Attribution
Before any implementation or analysis, include this checklist in your response:
- **Skills Checked**: [List paths to SKILL.md]
- **Rules Compliance**: [Confirm project governance adherence]
- **Context Inventory**: [List rules, docs, or MCP schemas referenced]

## Context Flushing Rule (Combating Context Decay)
LLMs suffer from context decay over long sessions.
- **Action**: At every `/task_boundary` or phase shift, physically re-read (`view_file`) the canonical `implementation_plan.md` and workspace rules.
- **Purpose**: Erase time bias. Treat `.md` artifacts as true memory.

## Pre-Flight Check (CANONICAL)
Before ANY workflow response involving analysis, design, or implementation:
- [ ] > 2-minute task? → Create `task_boundary`
- [ ] > 5 paragraphs or requires design? → Create artifact
- [ ] **Skill Inventory**: Load modular skills from `.agents/skills/`.
- [ ] **Rules Conflict**: Check `.agents/rules/platform-rules.md` and `project-gotchas.md`.
- [ ] **Layer Check**: Identify target layer (Server / Flutter / Shared).

## Skill Inventory Protocol (STRICT)
1. **Discovery**: Match task to `.agents/skills/`.
2. **Invocation**: Business logic = Rules (`.agents/rules/`). General patterns = Skills (`.agents/skills/`).
3. **Application**: Apply patterns explicitly to the current task.

## Skill Auto-Router (AUTOMATIC)
When you open or modify a file matching a pattern below, **auto-load** the associated skills without waiting for keyword discovery. This overrides manual skill search for known file types.

| File Pattern | Auto-Load Skills |
|-------------|-----------------|
| `*_queries.dart`, `*_manager.dart` | `flutter-architecture`, `database-performance` |
| `*.cs` in `Features/` or `Endpoints/` | `vertical-slice`, `modern-csharp` |
| `*Tests.cs`, `*_test.dart` | `testing-strategy`, `tdd`, `test-refactoring` |
| `AppDbContext.cs`, `*Configuration.cs` | `ef-core`, `migration-workflow` |
| `Program.cs`, `*Module.cs` | `dependency-injection` |
| `pubspec.yaml`, `*.csproj` | `migration-workflow` |
| `project-gotchas.md` modified | `vertical-slice-completeness` |

## Targeted Workflow Pacing (Context Protection)
NEVER execute a multi-phase workflow in one response. Use gates:
1. **Plan Gate**: After Planning (Phase 2) → STOP. Ask user to approve architecture, files, and `task.md` before coding.
2. **Verification Gate**: After Self-Review (Phase 4) → STOP. Ask user to manually test or review code before final handoff.

## Structural Diagnosis Mandate (Anti-Hallucination)
- **Rule:** If a task, test, or build fails 2 times, you are **FORBIDDEN** from blindly rewriting the code.
- **Action:** Pause. Run a structural trace: "Right file?", "Wired to router?", "Did an earlier phase fail?". Fix architecture, not just logic.

## Git Ownership Rule (NON-NEGOTIABLE)
**AI agents NEVER run `git add`, `git commit`, or `git push`.**
- Upon completion (Phase 5/Handoff) → **STOP. Notify user.**
- Output: "Implementation complete. Commit when ready: `git add -A ; git commit -m '...'`"
- Ignore any legacy "commit" instructions in workflows.

