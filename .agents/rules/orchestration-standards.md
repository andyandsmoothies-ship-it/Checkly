---
name: Orchestration Standards
description: Rules for AI agents on how to run workflows, manage context decay, load skills, and perform pre-flight checks.
trigger: model_decision
---

# Orchestration Standards

## Mandatory Integrity Audit & Context Attribution
Before ANY technical implementation, research, or audit, you MUST perform a mental (or explicit) audit. Every response involving code changes or architectural analysis SHOULD include a brief checklist and attribution block at the start or end of your message:
- **Skills Checked**: [List paths to SKILL.md files viewed]
- **Rules Compliance**: [Confirm coding patterns follow project governance and orchestration rules]
- **Context Inventory**: [Explicitly list all `.md` rule files, MCP schemas, or documentation URLs you referenced to produce this response/artifact]

## The Context Flushing Rule (Combating Context Decay)
LLMs suffer from context decay; instructions given earlier in long sessions lose their weight. Do not rely on conversational memory for long-running tasks.
- **Action**: Whenever you cross a new `/task_boundary` or shift to a new phase of work, you MUST physically re-read (`view_file`) the canonical `implementation_plan.md` and applicable workspace rules.
- **Purpose**: This refreshes the exact "shape of the container" at the top of your context window, erasing the time-bias decay. Treat `.md` artifacts as the true "Externalized Memory".

## Pre-Flight Check (CANONICAL)
<pre-flight-check>
Before ANY workflow response that involves analysis, design, or implementation:
- [ ] Is this more than a 2-minute task? → Create `task_boundary`
- [ ] Does the answer have >5 paragraphs or require design? → Create an artifact
- [ ] **Skill Inventory**: Match the task to modular skills in `.agents/skills/`.
- [ ] **Rules Conflict**: Confirm no existing logic in `.agents/rules/platform-rules.md` or `.agents/rules/project-gotchas.md` conflicts.
- [ ] **Layer Check**: Identify target layer (Server / Flutter / Shared) before planning.
</pre-flight-check>

## Skill Inventory Protocol (STRICT)
Before ANY technical implementation or research:
1. **Discovery**: Match the task to available skills in `.agents/skills/` (e.g., `clean_coder`, `systematic-debugging`).
2. **Invocation**: For project-specific business logic, refer to the Rules in `.agents/rules/`. For cross-project behaviors, refer to the Skills in `.agents/skills/`.
3. **Task-Based Application**: Apply the patterns defined in the relevant Rule or Skill for the current task.

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
You are strictly forbidden from executing an entire multi-phase workflow in a single response cycle. You must pace your execution using targeted logical gates:
1. **The Plan Gate:** You MUST stop generation and yield to the user after completing the Discovery & Planning phases (e.g., Phase 2). Explicitly ask for approval on your proposed architecture, files, and `task.md` before writing any code.
2. **The Verification Gate:** You MUST stop generation and yield to the user after completing the Coding & Self-Review phases (e.g., Phase 4). Explicitly ask the user if they want to manually test the implementation or review the code before you finalize commits and write handoff artifacts.

## Structural Diagnosis Mandate (Anti-Hallucination)
Graph optimization matters more than prompt or instruction tuning. If a failure is structural, fixing the logic won't help.
- **Rule:** If you fail a task, test, or compilation step 2 times in a row, you are **FORBIDDEN** from blinding rewriting the code again. 
- **Action:** You MUST pause and run a structural trace. Ask: "Am I executing the right file?", "Is the component wired to the router?", "Did an earlier workflow phase fail silently?" Verify the overarching architecture and workflow trace before tweaking the implementation logic.
