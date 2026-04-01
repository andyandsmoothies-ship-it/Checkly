---
name: Feature Analysis Workflow
description: Lightweight, Tactical Analysis for Standard Features and Bugs (Track A/B).
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analyze-feature

## Step 0: Context Initialization (CRITICAL FAIL-SAFE)
> [!IMPORTANT]
> If you do not have `.agents/rules/governance-rules.md` in active memory, `view_file` it now. Do not proceed until confirming adherence.

> [!NOTE]
> This is the **Tactical Dispatcher** workflow. It is designed for Small/Medium tasks (Track A/B) or individual slices handed down from an Epic. It bypasses architectural heavy-lifting to strictly focus on generating an immediate, safe Implementation Plan.

## Pre-Flight Setup
> [!IMPORTANT]
> Define a reasoning trace. Do NOT pollute artifacts with internal monologue.
> **MANDATORY ARTIFACT**: Create `task.md` right now before Phase 1 using this schema:
> ```
> # Task: [Feature / Bug / Topic Name]
> Workflow: /analyze-feature | Track: [A / B1 / B2 / C]
> ## Phases
> - [ ] Phase 1: Skill Loading
> - [ ] Phase 1.5: Requirement Deconstruction
> - [ ] Phase 2: Blast Radius Review
> - [ ] Phase 2.5: Edge Case & State Matrix
> - [ ] Phase 3: Deliverable
> - [ ] Phase 4: Route Implementation
> ## Artifact Inventory
> | Status | File Path | Type |
> | [NEW]  | brain/.../implementation_plan_[topic].md | Plan |
> ```

## Phase 1: Skill Loading (Precision Focus)
- **Instruction**: Assume the persona of the exact specialist needed.
- **Action**: Search `.agents/skills/` to find 1-2 matching skills.
- **Load**: `view_file` the `SKILL.md` files and let them dictate your approach.

> **@@SCAN**: (1) Skills loaded? (2) Following skill methodology?

## Phase 1.5: Requirement Deconstruction (First Principles)
- **Instruction**: Strip the requirement down. What is the fundamental business value?
- **Action**: Explicitly define *Strict Boundaries*. State what it MUST do and what is OUT OF SCOPE (YAGNI).
- **Boolean Integrity**: Define if conditional logic is ALLOWLIST or BLOCKLIST.
- **Alternatives**: Identify ≥1 alternative tactical approach (e.g., extend existing vs create new).
- **Action**: Formulate core logic independently of code implementation.

> **@@SCAN**: (1) Core business value? (2) OUT OF SCOPE defined? (3) Alternative approach identified?

## Phase 2: Tactical Blast Radius Review
- **Instruction**: Identify exactly what you might step on.
- **Action**: Consult your actively loaded `GEMINI.md` Context Cascade for constraints.
- **Action**: Verify callers of existing modified functions to prevent upstream breakage.

> **@@SCAN**: (1) Applicable gotcha rule? (2) Callers checked?

## Phase 2.5: Edge Case & State Matrix
- **Instruction**: Define resilience boundaries before coding.
- **Action**: Define 4 critical extremes:
  - **Loading State:** Network latency / async init.
  - **Empty State:** Target record missing.
  - **Error State:** 404s, 500s, validation failures.
  - **Success State:** Exact happy-path mutation.

> **@@SCAN**: (1) All 4 states defined? (2) Unhandled silent failures?

## Phase 3: Deliverable (Enterprise-Grade Tactical Plan)
- **Requirement**: You MUST generate an `implementation_plan_[topic].md` artifact. This plan must be deeply analytical but narrowly scoped to the tactical objective.
- **Action**: Output the plan containing:
  - **Executive Summary & Scope:** What are we building, and what is strictly out of scope?
  - **Decision Rationale:** Brief explanation of why this implementation path is optimal over the alternative.
  - **State Matrix & Resilience:** The 4-state matrix (Loading, Empty, Error, Success) defining error boundaries.
  - **Business Logic Rules:** The core business rules and constraints derived from your First Principles analysis.
  - **Proposed Changes:** Grouped by file with [NEW]/[MODIFY]/[DELETE].
  - **System Impact:** How blast radius is avoided. **MANDATORY**: Define Tactical Rollback Plan (e.g., Git revert safety, feature toggle).
  - **Dependency Context Array:** A list of every service/manager the touched files depend on, along with their exact import paths, so the QA agent can mock them without hallucinating.
  - **Behavioral Expectations (EDD):** Brief, explicit rules for testing interactions.
  - **Verification Plan:** Exact steps to prove it works in the local environment.

## Phase 4: Route Implementation (The ATDD Gate)

> [!IMPORTANT]
> The B1/B2 verdict is decided **here**, after full analysis. If this slice came from an epic dispatch table that listed `/atdd` in the chain, that was a **forecast**, not a mandate. Follow the gate below, not the epic's assumption.

> [!CAUTION]
> **Scope Escalation**: If analysis reveals this feature touches >5 files, requires new DB migrations, new services, or a new architectural pattern — **STOP**. This is a Track C epic in disguise. Inform the user and invoke `/analyze-epic` instead. Do not proceed to Phase 4 routing.

- **Instruction**: Evaluate the generated plan against the **ATDD Decision Gate**.

  | Signal | Skip ATDD (Track B1) | Require ATDD (Track B2) |
  |--------|----------------|---------------------|
  | Correctness | Obvious from the spec | Ambiguous — multiple valid interpretations |
  | Pattern | Extends existing, well-understood pattern | New pattern or algorithm |
  | State | Simple flag/branch | Complex state machine or multi-step transitions |
  | Edge cases | Few, easily enumerated | Many, easy to miss without formal test writing |
  | Risk | Low — failure is visible and recoverable | High — silent corruption or data loss |

- **Handoff (B1):** Pass `implementation_plan_[topic].md` to the user for `/implement`.
- **Handoff (B2):** Pass `implementation_plan_[topic].md` to the user for `/atdd`.

---

## Final Phase: Artifact Handoff (Hard Gate)
- Output literal file path of implementation plan.

> [!IMPORTANT]
> **Update `task.md`**: Before running the script below, you MUST update your `task.md` to change all lines to `[x]` and update the `Artifact Inventory` with the absolute paths of the files you just wrote.

- Run the verification script (do NOT substitute `list_dir`):
  `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
  - Code 0 (PASS): Tell user to pass `implementation_plan_[topic].md` to next agent.
  - Code 1 (FAIL): Fix reported errors and retry.
  - 2-Strike Rule: Two consecutive failures → write `handoff_[topic].md`. Tell user: "Hard gate blocked on: [error]".

> [!CAUTION]
> **Clean Handoff**: Before context limit, write `handoff_[topic].md` listing completed phases, remaining phases, and key decisions.
