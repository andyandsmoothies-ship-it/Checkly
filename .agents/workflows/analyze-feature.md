---
description: Lightweight, Tactical Analysis for Standard Features and Bugs (Track A/B).
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analyze-feature

> [!NOTE]
> Tactical Dispatcher. Target: Small/Medium Tasks (Track A/B). Goal: Fast, safe Implementation Plan generation without architectural bloat.

## Phase 0: Initialization

| Step | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema below BEFORE proceeding. |

```markdown
# Task: [Feature / Bug / Topic Name]
Workflow: /analyze-feature | Track: [A / B1 / B2]
## Phases
- [ ] Phase 1: Skill Loading & Deconstruction
- [ ] Phase 2: Blast Radius & State Matrix
- [ ] Phase 3: Deliverable
- [ ] Phase 4: Route Implementation
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | brain/.../implementation_plan_[topic].md | Plan |
```

## Phase 1: Discovery & Deconstruction

| Vector | Execution Contract |
|---|---|
| **Skill Load** | Extract Persona -> Load 1-2 matching skills from `.agents/skills/`. |
| **Constraint Def**| Define Strict Boundaries (WHAT it does) AND YAGNI (WHAT is OUT OF SCOPE). |
| **Trade-Off Analysis** | Identify >= 1 alternative "Ideal Enterprise" approach. Explicitly list the Pros, Cons, and Blast Radius to justify the pragmatic choice over the ideal choice. |
| **Risk Assessment** | Formally assess the technical and operational risks of the chosen approach, and document mitigation strategies. |

> **@@SCAN**: (1) Core business value? (2) YAGNI defined? (3) Pros/Cons of Ideal vs Pragmatic approaches explicitly mapped? (4) Risk Assessment included?

## Phase 2: Resilience & Blast Radius

| Vector | Execution Contract |
|---|---|
| **Radius Check** | Traverse `GEMINI.md` cascade for constraints. Verify upstream callers of modified functions. |
| **Boundary Check** | If touching an API, DTO, or DB Schema, MANDATORY `grep_search` across BOTH `lib/` (Flutter) AND `server/` (C#). Never treat the server as a black box. |
| **State Matrix** | MANDATORY: Define the 4 System Extremes -> `Loading`, `Empty`, `Error`, `Success`. |

> **@@SCAN**: (1) Upstream callers checked? (2) Both C# and Dart API boundaries explicitly mapped via `grep_search`? (3) 4-State Matrix defined?

## Phase 3: Tactical Plan Deliverable

| Process | Execution Contract |
|---|---|
| **Artifact Generation** | Create `implementation_plan_[topic].md`. |
## Phase 4: Route Implementation (The ATDD Gate)

> [!CAUTION]
> **[SCOPE_ESCALATION_TRAP]**: IF (touches >5 files OR requires DB migration OR new architecture) THEN STOP -> Escalate to Track C -> Run `/analyze-epic`. DO NOT ROUTE HERE.

| Signal Check | Route: B1 (Direct Implement) | Route: B2 (QA ATDD Spec) |
|---|---|---|
| **Correctness**| Obvious interpretations | Ambiguous interpretations |
| **Pattern** | Extends existing pattern | New algorithm/pattern |
| **State** | Simple flag | Complex state machine |
| **Testing** | Low risk (UI/Cosmetic) | High risk (Silent corruption) |

- **B1 Handoff**: Yield `implementation_plan.md` -> Tag `@Forge` `/implement`.
- **B2 Handoff**: Yield `implementation_plan.md` -> Tag `@Sentinel` `/atdd`.

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `implementation_plan_[topic].md` MUST INCLUDE: `Executive Summary & YAGNI`, `Trade-Off Analysis (Pros/Cons)`, `Risk Assessment`, `Decision Rationale`, `4-State Matrix`, `Business Rules`, `Proposed Deltas ([NEW]/[MOD]/[DEL])`, `Tactical Rollback Plan`, `Verification Plan`, and `<forensic_evidence>` tags (list of terminal commands run).
>
> **Update task.md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).