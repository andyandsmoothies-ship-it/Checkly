---
description: Architect's Strategic Research Workflow for Massive Epic Systems (Track C).
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /analyze-epic

> [!NOTE]
> Deep Architecture Pipeline. Target: Massive, multi-layer epics (Track C). Requires Red Team adversarial review and formal slicing.

> [!CAUTION]
> **ANTI-HALLUCINATION GUARDRAIL:** PROHIBITED: Generating exact implementation code, literal SQL table schemas, Dart class definitions, or C# line-by-line diffs. The Epic Analysis MUST remain at the Macro-level. Limit output to Component Architecture Flow, System API Contracts, Risk Mapping, and Use-Case Vertical Slicing. Leave code definitions for the Feature agents.

## Phase 0: Initialization

| Step | Execution Contract |
|---|---|
| **Governance** | IF `.agents/rules/governance-rules.md` NOT in memory THEN `view_file` it immediately. |
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. |

```markdown
# Task: [Epic Name]
Workflow: /analyze-epic | Track: C
## Phases
- [ ] Phase 1: Technical Discovery
- [ ] Phase 2: Red Team Adversarial Review
- [ ] Phase 3: Deliverable
- [ ] Phase 4: Slicing Dispatch
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | brain/.../analysis_epic_[topic]_[ConversationID].md | Epic Plan |
```

## Phase 1: Technical Discovery & Feasibility

| Vector | Execution Contract |
|---|---|
| **Skill Load** | Load abstract architectural skills (e.g., `clean-architecture`). |
| **Build vs Buy** | MANDATORY: `grep_search` codebase to verify if requirement can be met via existing component reuse. |
| **Options** | Explicitly define >= 2 architectural alternatives. |
| **Dependency Root Tracing**| MANDATORY: Before proposing an architecture, you MUST execute `grep_search` using exact entity names across the entire project. You must mathematically prove the 3-Tier Boundary: Database roots, DI Container registrations, and Cross-Platform API contracts. |
| **Trade-Off Matrix**| MANDATORY: For each alternative, explicitly document Pros, Cons, and Blast Radius. Justify the chosen option over the ideal enterprise option. |
| **Risk Assessment** | Formally assess the technical and operational risks of each decision/alternative, and document mitigation strategies. |
| **NFR Constraints** | MANDATORY: Explicitly define System-wide limits for Performance, Security, and Observability before proceeding. |

> **@@SCAN**: (1) Dependency Roots mathematically traced via grep_search? (2) >=2 Alternatives mapped? (3) NFR Constraints defined? (4) 3-Tier Boundary proven?

## Phase 2: Red Team Adversarial Review

| Vector | Execution Contract |
|---|---|
| **Skill Swap** | Load `dotnet-resilience` / concurrency skills. |
| **Virtual Readers**| MANDATORY: Execute **Virtual Reader Scoring**. Roast the architectural plan via 3 Personas: 1) DB Architect, 2) Security Auditor, 3) Junior Dev (maintenance burden). Score each out of 10. IF any score < 7 -> FAIL. |
| **Resolution** | Define mitigations for every low score/flaw OR reject the Epic entirely. |

> **@@SCAN**: (1) Hostile Interrogation run? (2) 3 Failure Scenarios? (3) Mitigations concrete?

## Phase 3: Production-Grade Deliverable

| Process | Execution Contract |
|---|---|
| **Artifact Gen** | Create `analysis_epic_[topic]_[ConversationID].md` (IsArtifact: True). |
| **Persist Copy** | Copy deliverable to `.agents/tmp/research/analysis_epic_[topic]_[ConversationID].md` via terminal. |
> **@@SCAN**: Does artifact include ALL 10 sections? (List skipped).

## Phase 4: Slicing & Dispatch Loop

> [!CAUTION]
> **[DISPATCH_LOCK]**: PROHIBITED: Handoff of Track C Epic directly to `/implement`. MUST slice to Track A/B.

| Step | Execution Contract |
|---|---|
| **Slicer Lock** | Load `use-case-slicing` skill. Break Epic into 3-5 vertical UI-to-DB slices. Append slices to `analysis_epic_[topic]_[ConversationID].md`. |
| **Dispatch Map** | Generate Routing Table. `Slice N | Track A/B | Route Path`. |

### Dispatch Map Schema
- **Track A (Cosmetic/Static):** `/analyze-feature` -> `/implement`
- **Track B (Logic/State/Mutation):** `/analyze-feature` -> `/atdd` -> `/implement`
- **Concurrency & Gating Strategy**: For every slice, explicitly declare its execution dependency:
    - `[BLOCKING]`: Must be analyzed/implemented FIRST and ALONE (subsequent slices depend on it).
    - `[PARALLEL]`: Independent slice. Explicitly state which other slices it can be executed concurrently with (to save waiting time via multiple AI sessions).
    - `[SEQUENTIAL]`: Must be executed in strict order after a specific Slice N.

### Final Generation Mandate (Suffix)
> [!IMPORTANT]
> **Payload Schema:** Your generated `analysis_epic_[topic]_[ConversationID].md` MUST INCLUDE: `1. <latent_space_scratchpad>` (to artificially expand test-time compute by thinking through tradeoffs and edge cases *before* concluding), `2. Exec Summary`, `3. Decision Matrix`, `4. Risk Assessment`, `5. Sys Arch Flow (Mermaid)`, `6. DB Migrations`, `7. API Contracts`, `8. Blast Radius/Rollback Plan`, `9. Red Team Adversarial Log`, `10. Security/RLS`, `11. Observability Hooks`, `12. EDD Expectations`, and `13. <forensic_evidence>` tags (terminal log proof).
>
> **Update task_[ConversationID].md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).