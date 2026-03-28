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
> Before you draft any plans, you MUST verify you fully understand the global governance rules.
> **Rule**: If you do not currently have the exact contents of `.agents/rules/governance-rules.md` in your active memory, you MUST use the `view_file` tool to read it right now. Do not proceed to Phase 1 until confirming adherence.

> [!NOTE]
> This is the **Tactical Dispatcher** workflow. It is designed for Small/Medium tasks (Track A/B) or individual slices handed down from an Epic. It bypasses architectural heavy-lifting to strictly focus on generating an immediate, safe Implementation Plan.

## Pre-Flight Setup (ANTI-POISONING MANDATE)
> [!IMPORTANT]
> You must establish a clear internal reasoning trace before starting your analysis. Keep your thinking rigorous but internal.
> 
> **MANDATORY ARTIFACT**: You MUST explicitly create a `task.md` document right now before proceeding to Phase 1, using this exact schema:
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
> |--------|-----------|------|
> ```

## Phase 1: Skill Loading (Precision Focus)
- **Instruction**: Do not act as a generic AI. You MUST assume the persona of the exact specialist needed for this scoped task.
- **Action**: Search `.agents/skills/` to find the 1-2 skills that perfectly match this feature (e.g., `ui-ux-designer`, `react-patterns`, `postgres-best-practices`).
- **Load**: Use `view_file` to read the specific `SKILL.md` files. You will let the loaded skill dictate your approach for the rest of this workflow.

> **@@SCAN** Before proceeding, PAUSE and INTERNALLY evaluate: (1) Which strict, tactical skill(s) did you load? (2) Are you following that skill's specific methodology?

## Phase 1.5: Requirement Deconstruction (First Principles)
- **Instruction**: Strip the requirement down to its absolute core. What is the fundamental business value being created or protected?
- **Action**: Explicitly define the *Strict Boundaries* of the feature. State exactly what this feature MUST do, and explicitly state what is OUT OF SCOPE (YAGNI).
- **Action (Boolean Integrity)**: If the feature involves conditional logic or state rules, explicitly define if it is an **ALLOWLIST** (only X is true, everything else is false) or a **BLOCKLIST** (only X is false, everything else is true). Do not leave boundary conditions mathematically ambiguous.
- **Action**: Formulate the core underlying logic or state transition independently of the code implementation.

> **@@SCAN** Before proceeding, PAUSE and INTERNALLY evaluate: (1) What is the core business value? (2) What is explicitly OUT OF SCOPE for this tactical feature? (3) What is the fundamental state transition required?

## Phase 2: Tactical Blast Radius Review
- **Instruction**: Even tiny features break things. You must identify exactly what you might step on.
- **Action**: Check `.agents/rules/project-gotchas.md`. Does this feature conflict with any known project gotcha (e.g., FAB padding, navigation routing order, EF Core snake_case)?
- **Action**: If modifying an existing function/component, verify its callers before proceeding to ensure you aren't breaking an upstream dependency.

> **@@SCAN** Before proceeding, PAUSE and INTERNALLY evaluate: (1) Which specific rule from `project-gotchas.md` applies here, if any? (2) Did you check the current callers of the code you are modifying?

## Phase 2.5: Edge Case & State Matrix
- **Instruction**: Enterprise-grade code does not fail silently. You must define the resilience boundaries before writing any implementation code.
- **Action**: Generate a strict **State Matrix** identifying how the feature behaves in 4 critical extremes:
  - **Loading State:** What happens during network latency or async initialization?
  - **Empty State:** What renders or returns if the targeted record/list does not exist?
  - **Error State:** How does the UI/Handler respond to 404s, 500s, or validation failures? (Are we using showErrorToast / Domain Errors?)
  - **Success State:** What is the exact happy-path mutation?

> **@@SCAN** Before proceeding, PAUSE and INTERNALLY evaluate: (1) Have you fully defined the Loading, Empty, Error, and Success states for this scoped feature? (2) Are there any unhandled silent failures?

## Phase 3: Deliverable (Enterprise-Grade Tactical Plan)
- **Requirement**: You MUST generate an `implementation_plan_[topic].md` artifact. This plan must be deeply analytical but narrowly scoped to the tactical objective.
- **Action**: Output the plan containing:
  - **Executive Summary & Scope:** What are we building, and what is strictly out of scope?
  - **State Matrix & Resilience:** The 4-state matrix (Loading, Empty, Error, Success) defining error boundaries.
  - **Business Logic Rules:** The core business rules and constraints derived from your First Principles analysis.
  - **Proposed Changes:** Grouped by file with [NEW]/[MODIFY]/[DELETE].
  - **System Impact:** Brief note on how you are avoiding the blast radius identified in Phase 2.
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

- **Handoff (B1):** Instruct the user to run `/implement` directly.
- **Handoff (B2):** Instruct the user to run `/atdd` first, then `/implement`.

---

## Final Phase: Artifact Handoff (CRITICAL)
<strict-instruction>
Before concluding this workflow and replying to the user, you MUST ensure you have produced the physical artifacts required for the next agent in the chain.

- **Mandatory Output**: You must explicitly output the literal file path of the generated implementation plan.
- **Physical Verification**: Run `list_dir` on the brain/artifact directory and confirm the `implementation_plan_[topic].md` file is visible on disk before handing off.

You are strictly FORBIDDEN from subjectively grading your own work. The human or the auditor agent will perform the verification.
</strict-instruction>

> [!CAUTION]
> **Clean Handoff Protocol**: If you are nearing your context limit or hit a blocking error before this phase is complete, do NOT silently stop. Write a `handoff_[topic].md` listing completed phases, remaining phases, and key decisions made so far. Then tell the user: *"Context limit reached. Resume from `handoff_[topic].md` in a new session."*
