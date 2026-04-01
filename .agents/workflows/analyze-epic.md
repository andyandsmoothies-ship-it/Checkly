---
name: Deep Epic Analysis Workflow
description: Architect's Strategic Research Workflow for Massive Epic Systems (Track C).
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analyze-epic

## Step 0: Context Initialization (CRITICAL FAIL-SAFE)
> [!IMPORTANT]
> If you do not have `.agents/rules/governance-rules.md` in active memory, `view_file` it now. Do not proceed until confirming adherence.

> [!NOTE]
> This is the **Deep Architecture Pipeline** — used for massive, multi-layer epics (Track C) that require extreme rigor, Red Team adversarial review, and formal use-case slicing. 
> For simple features or bugs, abort this workflow and switch to `/analyze-feature`.

## Pre-Flight Setup
> [!IMPORTANT]
> Define a reasoning trace. Do NOT pollute artifacts with internal monologue.
> **MANDATORY ARTIFACT**: Create `task.md` right now before Phase 1 using this schema:
> ```
> # Task: [Epic Name]
> Workflow: /analyze-epic | Track: C
> ## Phases
> - [ ] Phase 1: Technical Discovery & Reuse Audit
> - [ ] Phase 2: Feasibility & System Impact Audit
> - [ ] Phase 3: Adversarial Review (Red Team)
> - [ ] Phase 4: Deliverable
> - [ ] Phase 5: Task Slicing & Dispatch
> ## Artifact Inventory
> | Status | File Path | Type |
> | [NEW]  | brain/.../epic_plan_[topic].md | Epic Plan |
> ```

## Phase 1: Technical Discovery & Reuse Audit
- **Instruction**: Assume Principal Software Engineer persona. Determine if we should build this.
- **Consume Research**: Read `concept_brief_[topic].md` or `research_[topic].md` if provided.
- **Skill Discovery**: Load architectural skills (e.g., `clean-architecture`). Declare loaded skills.
- **Reuse vs. Build**: Use `grep_search` to determine if requirement can be met by configuring existing components.
- **Alternatives**: Identify ≥2 viable architecture options before deciding.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Loaded skills? (2) Can this be reused? (3) Core entities/tables touched? (4) ≥2 alternatives identified?

## Phase 2: Feasibility & System Impact Audit
- **Instruction**: Evaluate logic against workspace rules in `.agents/rules/`.
- **System Impact Audit**: Search for cross-feature conflicts. Identify core tables/services touched. **Use `grep_search` to find all usages.**
- **Boolean Integrity**: If feature involves conditional logic, explicitly define ALLOWLIST vs BLOCKLIST. Do not leave ambiguous.
- **Action**: Identify logical flaws, unhandled edge cases, security risks, and standards deviations.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) What could break? (2) Which rules apply? (3) Did you file-search affected components?

## Phase 3: Adversarial Review (Red Team)
- **Instruction**: Switch to Red Team persona. Destroy proposed implementation plan before coding.
- **Skill Refresh**: Re-scan `.agents/skills/` for error/concurrency skills. Load 1-2.
- [ ] **Hostile Interrogation**: Run verification-loop Part C gate. Answer 3 failure questions.
- [ ] **Resolution**: Mitigate failures or reject epic.

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Hostile Interrogation run? (2) 3 failure scenarios? (3) Unmitigable failures?

## Phase 4: The Deliverable (Production-Grade Architecture Document)
- **Requirement**: You MUST create a rigorous, structured `analysis_epic_[topic].md` artifact. This is a Software Engineering Design Document.
- **The artifact MUST include the following mandatory sections**:
  1. **Executive Summary & Goals**: What are we building and why?
  2. **Design Rationale & Alternatives**: Explicit trade-off matrix (max 3 options). State EXACTLY why alternatives were rejected.
  3. **System Architecture & Data Flow**: Clear description of how the system will interact across the UI, Backend (API), and Database. Use a Mermaid diagram if complex.
  4. **Database & Schema Changes**: Table modifications, migrations, and index strategies.
  5. **API Contracts**: Request/Response payloads and endpoint designs.
  6. **System Impact & Blast Radius**: List existing components at risk. **MANDATORY**: Define Rollback/Reversibility Strategy (e.g., feature toggles, backward-safe DB).
  7. **Adversarial Review & Edge Cases**: The 3 Red Team failures and their mitigations. Error handling strategies (offline, timeouts, invalid data).
  8. **Security & Permissions**: RLS, Auth, or authorization checks required.
  9. **Observability**: How to prove it works in production? (Logging, telemetry hooks).
  10. **Behavioral Expectations (EDD)**: You MUST generate 3-5 clear, plain-text expectations for the feature. Incorporate "Hostile Expectations" from the Red Team. 

> **@@SCAN** PAUSE and INTERNALLY evaluate: (1) Does artifact include ALL 10 sections? List skipped ones.

## Phase 5: Task Slicing & Dispatch
- **Instruction**: Track C tasks must be sliced into Track A/B pieces. DO NOT hand to `/implement`.
- **Action**: 
  1. `view_file` `.agents/skills/use-case-slicing/SKILL.md`.
  2. Slice epic into independent Track A or Track B slices.
  3. Append Slices to the `analysis_epic_[topic].md` artifact.
- **Handoff**: Give `analysis_epic_[topic].md` to the user with a **Dispatch Table**:

  | Slice | Track | Dispatch Chain |
  |-------|-------|----------------|
  | Slice N — [name] | Track A or B | `/analyze-feature` → `/implement` OR `/analyze-feature` → `/atdd` → `/implement` |

  - **Track A** (cosmetic, copy, UI-only with no logic branches): `/analyze-feature` → `/implement`
  - **Track B** (new logic, state machine, recursive validation, data mutation): `/analyze-feature` → `/atdd` → `/implement`
  - State clearly: "Do NOT dispatch Slice N+1 until Slice N is verified GREEN."

> [!CAUTION]
> **Clean Handoff**: Before context limit, write `handoff_[topic].md` listing completed phases + slice table state. Tell user: "Context limit reached. Resume from handoff file."

## Final Phase: Script Verification Gate

> [!IMPORTANT]
> **Update `task.md`**: Before running the script below, you MUST update your `task.md` to change all lines to `[x]` and update the `Artifact Inventory` with the absolute paths of the files you just wrote.

Run EXACTLY:
`cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`

- Code 0 (PASS): Workflow complete. Tell user to pass `analysis_epic_[topic].md` to next agent.
- Code 1 (FAIL): Fix reported errors and retry.
- 2-Strike Rule: Same error fails twice → STOP. Write `handoff_[topic].md` with error. Tell user: "Hard gate blocked on: [error]".

