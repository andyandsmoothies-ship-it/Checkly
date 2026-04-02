---
name: Deep Epic Analysis Workflow
description: Architect's Strategic Research Workflow for Massive Epic Systems (Track C).
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /analyze-epic

> [!NOTE]
> Deep Architecture Pipeline. Target: Massive, multi-layer epics (Track C). Requires Red Team adversarial review and formal slicing.

## Phase 0: Initialization

| Step | Execution Contract |
|---|---|
| **Governance** | IF `.agents/rules/governance-rules.md` NOT in memory THEN `view_file` it immediately. |
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema below BEFORE proceeding. |

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
| [NEW]  | brain/.../analysis_epic_[topic].md | Epic Plan |
```

## Phase 1: Technical Discovery & Feasibility

| Vector | Execution Contract |
|---|---|
| **Skill Load** | Load abstract architectural skills (e.g., `clean-architecture`). |
| **Build vs Buy** | MANDATORY: `grep_search` codebase to verify if requirement can be met via existing component reuse. |
| **Options** | Explicitly define >= 2 architectural alternatives. |
| **System Impact**| `grep_search` all core tables/services affected. Define ALLOWLIST vs BLOCKLIST conditional logic. |
| **Trade-Off Matrix**| MANDATORY: For each alternative, explicitly document Pros, Cons, and Blast Radius. Justify the chosen option over the ideal enterprise option. |

> **@@SCAN**: (1) Component reuse verified? (2) >=2 Alternatives with Pros/Cons mapped? (3) Core tables explicitly grepped across BOTH lib/ and server/?

## Phase 2: Red Team Adversarial Review

| Vector | Execution Contract |
|---|---|
| **Skill Swap** | Load `dotnet-resilience` / concurrency skills. |
| **Hostile Gate** | Execute **Hostile Interrogation** (verification-loop Part C). Must output 3 hard failure conditions. |
| **Resolution** | Define mitigations for all 3 failures OR reject the Epic. |

> **@@SCAN**: (1) Hostile Interrogation run? (2) 3 Failure Scenarios? (3) Mitigations concrete?

## Phase 3: Production-Grade Deliverable

| Process | Execution Contract |
|---|---|
| **Artifact Gen** | Create `analysis_epic_[topic].md`. |
| **10-Point Payload**| `1. Exec Summary`, `2. Decision Matrix (Pros/Cons/Blast Radius per option)`, `3. Sys Arch Flow (Mermaid)`, `4. DB Migrations`, `5. API Contracts`, `6. Blast Radius/Rollback Plan`, `7. Red Team Adversarial Log`, `8. Security/RLS`, `9. Observability Hooks`, `10. EDD Expectations`. |

> **@@SCAN**: Does artifact include ALL 10 sections? (List skipped).

## Phase 4: Slicing & Dispatch Loop

> [!CAUTION]
> **[DISPATCH_LOCK]**: PROHIBITED: Handoff of Track C Epic directly to `/implement`. MUST slice to Track A/B.

| Step | Execution Contract |
|---|---|
| **Slicer Lock** | Load `use-case-slicing` skill. Break Epic into 3-5 vertical UI-to-DB slices. Append slices to `analysis_epic_[topic].md`. |
| **Dispatch Map** | Generate Routing Table. `Slice N | Track A/B | Route Path`. |

### Dispatch Map Schema
- **Track A (Cosmetic/Static):** `/analyze-feature` -> `/implement`
- **Track B (Logic/State/Mutation):** `/analyze-feature` -> `/atdd` -> `/implement`
- **Mandate:** *"DO NOT dispatch Slice N+1 until Slice N is verified GREEN."*

> [!IMPORTANT]
> **Update task.md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
