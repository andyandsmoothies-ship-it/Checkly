---
description: High-Compliance Diagnostic Workflow for System Errors.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /diagnose

> [!NOTE]
> Enforces systematic root cause analysis. PROHIBITED: Guessing. 

## Phase 0: Pre-Flight (Anti-Poisoning Mandate)

| Step | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. |
| **Reasoning Phases**| Structure internal thoughts via exactly 4 phases: `Initial Hypothesis`, `Evidence Gathered`, `Root Cause Identified`, `Fix Strategy`. PROHIBITED: Outputting monologue outside `task_[ConversationID].md`. |

```markdown
# Task: [Bug / Error Topic Name]
Workflow: /diagnose | Track: [A / B1 / B2 / C]
## Phases
- [ ] Phase 1: Symptom Isolation
- [ ] Phase 2: Skill & Rule Discovery
- [ ] Phase 3: Resolution Plan
- [ ] Phase 4: Deliverable Handoff
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | brain/.../failure_report_[topic]_[ConversationID].md | Report |
```

## Phase 1: Symptom Isolation

| Vector | Execution Contract |
|---|---|
| **Context Trace** | IF (stack_trace == missing) THEN MANDATORY: Request trace from user. PROHIBITED: Debugging blind from static code. |
| **Targeting** | MANDATORY: Use `view_file` targeted lines or `grep_search` targeted functions. PROHIBITED: Reading entire long files (Attention Bias failure). IF symptom crosses API/DTO/DB boundary: `grep_search` BOTH `lib/` and `server/` — the bug may live on the opposite side of the call. |
| **Formal Reasoning**| MANDATORY: 1. `Premises` and `Execution Trace`. 2. Generate 3-5 explicit Hypotheses (with Evidence For/Against). 3. You MUST log these hypotheses strictly to `.agents/tmp/DEBUG.md` to prevent context sliding. |

> **@@SCAN**: (1) Exact file/line identified? (2) Were BOTH lib/ and server/ searched? (3) Are 3-5 hypotheses explicitly tracked in `.agents/tmp/DEBUG.md`?

## Phase 2: Skill & Rule Discovery

| Step | Execution Contract |
|---|---|
| **Skill Load** | Extract 2-3 keywords (e.g., "ground-truth"). `grep_search` `.agents/skills/`. Load Top 2 Error/Debug skills. |
| **Rule Bounds**| Consult `.agents/rules/` for known locking/state gotchas that explain failure. |

> **@@SCAN**: (1) Debug skills loaded? (2) Any `.agents/rules/` explain failure?

## Phase 3: Resolution Plan

| Step | Execution Contract |
|---|---|
| **Skill Refresh** | IF (Root cause domain != Symptom domain) THEN Re-scan and load new Domain `SKILL.md`. |
| **Artifact Gen** | Export `failure_report_[topic]_[ConversationID].md`. |
| **Constraint (Micro-Experiments)** | PROHIBITED: Broad code refactors. ALLOWED: "Micro-Experiments" (max 5 lines) to falsify hypotheses. IF a test fails twice, you MUST formally reject it in `.agents/tmp/DEBUG.md` and pivot. |

> **@@SCAN**: (1) If code was changed, was it strictly under 5 lines? (2) If a test failed twice, did you officially pivot to a new hypothesis?

## Phase 4: Deliverable Handoff

| Step | Execution Contract |
|---|---|
| **Gotcha Protocol**| MANDATORY: Append `### Gotcha Addition Proposal` to report. IF (project-specific logic) THEN Propose bullet point for `GEMINI.override.md`. ELSE -> State "No new gotcha detected". |
| **Routing** | MANDATORY: Output an "Execution Queue" checklist in the final chat response containing the exact implementation command (e.g., `- [ ] @[/implement] brain/.../failure_report.md`) so the user can easily invoke the Builder Agent. -> YIELD. |

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your `failure_report_[topic]_[ConversationID].md` MUST INCLUDE: `Root Cause`, `Explicit Code Trace (Premises + Proof)`, `Proposed Scope-Limited Fix`, and `<forensic_evidence>` tags logging all terminal tools/commands executed.
> 
> **Handoff Block Suffix:** You MUST append a `## Handoff Block` at the absolute EOF containing:
> 1. Final Diagnostic Verdict & Persistent path.
> 2. The required fix and its blast radius.
> 3. An "Execution Queue" checklist of the exact commands for the user to copy-paste (e.g., `- [ ] @[/implement] brain/.../failure_report.md`).
>
> **Update task_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).