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
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. |
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
| **Blind Objective Research** | MANDATORY: Do NOT propose implementation solutions yet. Extract facts only. Execute a blind dependency scan to learn how the current code actually works. If you assume how it works, you will hallucinate. |
| **Origin Idea Alignment** | MANDATORY: Extract the `[ORIGIN_IDEA]` tag from upstream artifacts. Before proposing a technical plan, explicitly counter-check: Does this exact solution genuinely solve the human's original idea? If the research drifted from the original goal, halt and realign the plan immediately. |
| **Hostile Artifact Validation** | MANDATORY: If an input artifact (e.g., ADR or Research) is provided, you MUST physically validate its assumptions against the real codebase. Check 1) Does the idea violate Clean Architecture boundaries? 2) Does it trigger severe unintended consequences (e.g., Router eviction)? If the input artifact contains physically dangerous or impossible ideas, you MUST override and reject them. Be a gatekeeper, not a blind translator. |
| **Skill Load** | Extract Persona -> Load 1-2 matching skills from `.agents/skills/`. |
| **Constraint Def**| Define Strict Boundaries (WHAT it does) AND YAGNI (WHAT is OUT OF SCOPE). MANDATORY: Enforce Simplicity First. Outline absolute minimum code that solves the problem. Explicitly state what 'flexible' or 'configurable' ghost requirements are OUT OF SCOPE. |
| **Vertical Micro-Slicing**| MANDATORY: Never slice horizontally by layer (e.g., DB-only). All plans must be end-to-end and testable. If a plan is too large, slice VERTICALLY by removing infrastructure complexity (e.g., build brute-force data flow first, add cache in a future slice). |
| **Trade-Off Analysis (Crickett's Rule)** | Explicitly answer: What does this approach do? Why is it done this way? What are the tradeoffs against >= 1 alternative "Ideal Enterprise" approach? Justify the pragmatic choice in simple English. |
| **Risk Assessment** | Formally assess the technical and operational risks of the chosen approach, and document mitigation strategies. |
| **NFR Constraints** | MANDATORY: Explicitly define 3 Non-Functional Requirements for this feature: Performance (latency/load limits), Security (Auth rules/data isolation), and Observability (required telemetry/logs). |

> **@@SCAN**: (1) Core business value? (2) YAGNI defined? (3) Did you restrict the generated plan to a single Micro-Slice if layers > 2? (4) NFR Constraints defined? (5) Risk Assessment included?

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
| **High-Level Design Document** | MANDATORY: Use `write_to_file` to generate `implementation_plan_[topic]_[ConversationID].md` into the `brain/` directory. NEVER dump the tactical plan directly into the chat UI. Keep the document highly readable for human review before execution. |
| **Artifact Generation** | The final plan MUST contain explicit *Verifiable Goals* (e.g., 'Write X test -> Verify Red -> Implement Y -> Verify Green') rather than just vague developer instructions. |
## Phase 4: Route Implementation (The ATDD Gate)

> [!CAUTION]
> **[SCOPE_ESCALATION_TRAP]**: IF (requires DB migration OR alters core infrastructure like routing/auth OR introduces new architectural patterns OR spans >2 distinct feature domains) THEN STOP -> Escalate to Track C -> Run `/analyze-epic`. DO NOT ROUTE HERE.

| Signal Check | Route: B1 (Direct Implement) | Route: B2 (QA ATDD Spec) |
|---|---|---|
| **Correctness**| Obvious interpretations | Ambiguous interpretations |
| **Pattern** | Extends existing pattern | New algorithm/pattern |
| **State** | Simple flag | Complex state machine |
| **Testing** | Low risk (UI/Cosmetic) | High risk (Silent corruption) |

## 🚦 User Handoff & Next Steps

> [!IMPORTANT]
> **Output Created:** `implementation_plan_[topic]_[ConversationID].md`
> 
> **YOUR NEXT COMMAND & CONCURRENCY:**
> - **Concurrency Strategy**: If you generated multiple Micro-Slices, explicitly declare which slices are `[BLOCKING]` (must run alone/first) and which are `[PARALLEL]` (can be dispatched concurrently in separate AI windows to save user waiting time).
> - **If Track B2 (High Risk):** Switch to Sentinel QA and type: `@[/atdd] Execute based on this exact plan: {Absolute_Path_to_implementation_plan.md}`
> - **If Track B1 (Low Risk):** Switch to Forge Builder and type: `@[/implement] Execute based on this exact plan: {Absolute_Path_to_implementation_plan.md}`

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `implementation_plan_[topic]_[ConversationID].md` MUST INCLUDE: `<latent_space_scratchpad>` (to artificially expand your computational thinking on edge cases prior to outputting the plan), `Executive Summary & YAGNI`, `Trade-Off Analysis (Pros/Cons)`, `Risk Assessment`, `Decision Rationale`, `4-State Matrix`, `Business Rules`, `Proposed Deltas ([NEW]/[MOD]/[DEL])`, `## Execution Slices` (MANDATORY: You must group the proposed deltas into isolated, testable Micro-Slices. E.g. Slice 1: Database, Slice 2: Core Logic. If you fail to slice the work, the Builder session will crash under context weight), `Tactical Rollback Plan`, `Verification Plan`, and `<forensic_evidence>` tags (list of terminal commands run).
>
> **Update task_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}rain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).