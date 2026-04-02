---
name: ATDD Workflow
description: Acceptance Test-Driven Development — defines acceptance tests BEFORE implementation begins.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /atdd

> [!NOTE]
> This is ATDD (Acceptance Test-Driven Development). Goal: Define WHAT the feature must do at the acceptance level. Target Persona: **Sentinel** (QA).

## Phase 0: Pre-Flight

| Step | Execution Contract |
|---|---|
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema below BEFORE proceeding. |

```markdown
# Task: [Feature / Acceptance Test Topic]
Workflow: /atdd | Track: [B2 / C]
## Phases
- [ ] Phase 1: Spec Discovery & Persona
- [ ] Phase 2: SDET Execution
- [ ] Phase 3: Deliverable
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | brain/.../test_contracts_[topic].md | Contracts |
```

## Phase 1: Spec Discovery
> [!IMPORTANT]
> PROHIBITED: Starting scenarios without completely understanding the upstream spec.

| Step | Execution Contract |
|---|---|
| **Skill Load** | MANDATORY: Load `atdd-quality-gates` skill. |
| **Dynamic Skills**| Derive 2-3 keywords -> search `.agents/skills/` -> Load Top 2. |
| **Verification** | MANDATORY: Read upstream `analysis_[topic].md`. Execute `grep_search` / `view_file` to confirm entities/endpoints mentioned actually exist. **If spec mentions an API contract: verify the route exists in `server/` AND a corresponding Dart client call exists in `lib/`.** IF Discrepancy THEN Flag to user → STOP. |
| **Gap Analysis** | MANDATORY: Play the Adversary. Independent of the upstream spec, ask: "What edge cases, state leaks, migrations, or boundary errors did the Architect forget?" Define minimally 2 ACs that are NOT explicitly requested by the spec to act as a safety net. |

> **@@SCAN**: (1) `atdd-quality-gates` loaded? (2) API routes confirmed in BOTH server/ and lib/? (3) Discrepancies found? (4) Gap Analysis ACs defined?

## Phase 2: SDET Execution

### 2a. Scenario Authoring (BEFORE Code)
| Rule | Constraint |
|---|---|
| **Citation** | MANDATORY: Every scenario MUST cite exact line/rule from `.agents/rules/` or prompt. IF no source THEN Delete. |
| **Coverage** | MANDATORY: `Happy-path >= 1` AND `Negative/Boundary >= 1`. |
| **Naming** | MANDATORY: Spec-readable (e.g., `Auditor_Cannot_Delete_Template`). |

### 2b. Test Implementation (Iterative Loop)

> **@@SCAN — Pre-Test Governance Anchor (MANDATORY)** -> State before first test:
> `[SCAN] Active rules: <list>`
> `[SCAN] Applicable gotchas: <list or NONE>`
> `[SCAN] Active skills: <list>`

| Rule | Constraint |
|---|---|
| **Role Limits** | PROHIBITED: Writing production code. Sentinel writes test code ONLY. |
| **Execution** | MANDATORY: Loop `One scenario` -> `One test` -> `Verify RED` -> `Next`. |
| **Assertions** | MANDATORY: Assert WHAT returned. PROHIBITED: Bare `Assert.NotNull()`. Max 5 HTTP/DB calls per test. |

### 2c. Smoke Gate (Red for the Right Reason)
| Step | Execution Contract |
|---|---|
| **Pre-Flight** | Run Infrastructure Checklist from `atdd-quality-gates` Gate 1. |
| **Classification**| Run all tests. IF `.NET` -> Execute `powershell -ExecutionPolicy Bypass -File scripts\CollectTestResults.ps1` to easily parse the test outcomes into a clean CSV instead of reading truncated terminal logs. Classify failures -> Table `Test Name | Status | Type (Business/Infra) | Error Summary`. |
| **Gate Verdict** | IF (All == Business) -> Proceed to 2d. IF (Any == Infra/Ambiguous) -> Fix -> Re-run. |

### 2d/2e. Deferred ACs & Saboteur Protocol
| Process | Execution Contract |
|---|---|
| **Skip Protocol** | IF AC cannot be tested (bug/missing infra) THEN `Fact(Skip="reason")`. PROHIBITED: Commenting out tests. |
| **Sabotage Test** | MANDATORY: Mutate core business logic (e.g. `>=` to `<`) -> Run Tests -> IF Tests PASS -> Reject tests & rewrite stronger. THEN Revert sabotage. |

> **@@SCAN**: (1) All failures classified as Business? (2) Any ACs deferred? (3) Saboteur Protocol run results?

## Phase 3: Deliverable (Handoff)
| Step | Execution Contract |
|---|---|
| **Artifact Form** | Create `specs_[feature].md` & `test_cases_[feature].md` (Markdown table of approved ACs only). |
| **Metadata** | Append `Test Infrastructure Map` to Specs. |
| **Workflow Merge**| Update `implementation_plan_[topic].md` with test names. |
| **Clean Handoff** | Pass `test_cases_[topic].md` to User -> YIELD. |

> [!IMPORTANT]
> **Update task.md**: Convert `[/]` to `[x]` and detail absolute file paths.
> 
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Workflow complete. Tell user to pass test artifacts to Builder."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).