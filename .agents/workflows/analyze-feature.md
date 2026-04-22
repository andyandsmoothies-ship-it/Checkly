---
description: Lightweight, Tactical Analysis for Standard Features and Bugs (Track A/B).
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /analyze-feature

> [!NOTE]
> Tactical Dispatcher. Target: Small/Medium Tasks (Track A/B). Goal: Fast, safe Implementation Plan generation without architectural bloat.

## Phase 0: Initialization

| Step | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. List ONLY the implementation plan artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation phase. |
| **Contract Ingestion** | MANDATORY: If this feature is part of an Epic, you MUST read the parent Epic's API Contracts and Dispatch Map. Your sole purpose is to translate ONE specific Epic Slice into an exact execution plan. You are required to generate the specific Database Schemas, File Paths, and exact Diffs required to fulfill the Epic Contract without changing the contract itself. |

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
| [NEW]  | brain/.../implementation_plan_[topic]_[ConversationID].md | Plan |
```

## Phase 1: Discovery & Deconstruction

| Vector | Execution Contract |
|---|---|
| **Topology & Baseline** | Parse config files (.csproj, pubspec.yaml). Find structural boundaries. |
| **Blind Objective Research** | Extract facts only. Execute a blind dependency scan to learn how the current code actually works before planning. |
| **Hostile Validation** | If an input artifact (ADR/Research) is provided, physically validate its assumptions via grep_search. Reject impossible ideas. |
| **Constraint Def (YAGNI)**| Define Strict Boundaries. Outline absolute minimum code. State what ghost requirements are OUT OF SCOPE. |
| **Trust But Verify**| Spot-check at least 1 core plan claim via grep_search before finalizing the plan. |

> **@@SCAN**: (1) Core business value? (2) YAGNI defined? (3) Spot-check complete?

## Phase 2: Resilience & Blast Radius

| Vector | Execution Contract |
|---|---|
| **Dependency Root Tracing** | MANDATORY: Before modifying ANY Class, Method, or API, you MUST execute `grep_search` using the exact entity name across the entire project root (`/server`, `/lib`, `/src`, etc.). Track all 6 boundary axes: 1) UI, 2) Routing, 3) DB schemas, 4) Mocks, 5) Events/PubSub listeners, 6) DI/IoC registrations. |
| **Blast Radius Check** | You are strictly prohibited from changing tests or mocks to make broken upstream code pass. Adapt your logic to the proven X-Ray boundary. If touching an API or DB, map both Backend and Frontend files. |
| **Data Lineage Contract** | Never trust UI state alone. If your plan intercepts conditional data (e.g., `if status == 'x'`), you MUST `grep_search` its definitive Source of Truth (DB/API/Cache) to prove that boundary is capable of emitting that exact state. |
| **State Matrix** | MANDATORY: Define the 4 System Extremes -> `Loading`, `Empty`, `Error`, `Success`. |

> **@@SCAN**: (1) Dependency Roots mathematically traced via grep_search? (2) Backend and Frontend mapped? (3) 4-State Matrix defined?

## Phase 3: Tactical Plan Deliverable

| Process | Execution Contract |
|---|---|
| **QA Test Contracts (TDD)** | MANDATORY for Track B2/C: Generate raw data for QA. Your plan MUST include a Test Contract section (Format: ID, Exact Text, State Matrix, Why RED) that the SDET can easily ingest into their test suite. |
| **JIT Harness & Verification** | Declare [ACTIVE_SKILLS] needed for the Builder. Declare terminal validation commands (e.g. lutter test or dotnet test) upfront. |
| **High-Level Design Document** | MANDATORY: Use `write_to_file` to generate `implementation_plan_[topic]_[ConversationID].md` into the `brain/` directory. NEVER dump the tactical plan directly into the chat UI. Keep the document highly readable for human review before execution. |
| **Artifact Generation** | The final plan MUST contain explicit *Verifiable Goals* (e.g., 'Write X test -> Verify Red -> Implement Y -> Verify Green') rather than just vague developer instructions. |
## Phase 4: Route Implementation (The ATDD Gate)

> [!CAUTION]
> **[SCOPE_ESCALATION_TRAP]**: IF (Unknown requirements OR New state machines OR New user personas OR Spans >1 new DB table) THEN STOP -> Escalate to Track C -> Run `/analyze-epic`. DO NOT ROUTE HERE unless requirements are absolute, uses existing UI/architecture, and is an isolated addition.

| Signal Check | Route: B1 (Direct Implement) | Route: B2 (QA ATDD Spec) |
|---|---|---|
| **Correctness**| Obvious interpretations | Ambiguous interpretations |
| **Pattern** | Extends existing pattern | New algorithm/pattern |
| **State** | Simple flag | Complex state machine |
| **Testing** | Low risk (UI/Cosmetic) | High risk (Silent corruption) |

## 🚦 Handoff

> [!IMPORTANT]
> **Action:** Output the exact routing commands below for the user. Map each generated Execution Slice to its required route.
>
> **Route 1: Logic/Standard (QA-First)**
> @[/tdd] Execute tests for Slice [N]: {Absolute_Path_to_plan}
>
> **Route 2: Cosmetic/Low-Risk (Direct Build)**
> @[/implement] Execute build for Slice [N]: {Absolute_Path_to_plan}
>
> **Route 3: Epic/High-Risk (ATDD-First)**
> @[/atdd] Execute specs for Slice [N]: {Absolute_Path_to_plan}
>
> **Concurrency:** State explicitly which slices are [BLOCKING] vs [PARALLEL].

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `implementation_plan_[topic]_[ConversationID].md` MUST INCLUDE the following EXACT headers and sections. Keep it dense and brief.
> - `<latent_space_scratchpad>`: Computational thinking on edge cases prior to outputting the plan.
> - `## Executive Summary & YAGNI`
> - `## 4-State Matrix` (Success, Error, Empty, Loading)
> - `## Test Contracts` (ID, Exact Text, State Matrix, Why RED)
> - `## JIT Harness & Verification` (Active skills and terminal validation commands)
> - `## Proposed Changes`: List `[NEW]/[MOD]/[DEL]` files.
> - `## Concept Diagram`: A short, concise text-based flowchart (e.g., `[Actor] --> [Action] --> [System]`) explaining the core logic or state changes.
> - `## Execution Slices`: **(CRITICAL)** Group work into isolated slices. Define the **Structural Blueprint** (e.g., 'Add nullable field', 'Wrap in Try/Catch'). **DO NOT write exact code diffs.** The Builder will write the code.<br><br>**CRITICAL:** For each slice or major design decision, you MUST present the **Trade-offs / Pros & Cons** of the chosen approach versus alternatives. Yield to the user to make the final executive decision before jumping to implementation.
> - `<forensic_evidence>`: Tags containing a list of terminal commands run.
> - `## Handoff Block`: An AI Agent Mission Brief (TL;DR for the next AI agent). **MANDATORY:** You MUST include the exact `@[/...]` routing commands (e.g., `@[/tdd]` or `@[/implement]`) for EVERY Execution Slice here, mapping them to their absolute file paths.
>
> **Update task_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).