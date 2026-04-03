---
description: Pre-PR quality gate — dynamically enforces project gotchas and vertical-slice completeness.
---

@[.agents/rules/orchestration-standards.md]
@[.agents/rules/governance-rules.md]
@[.agents/rules/artifact-protocol.md]

# Workflow: /preflight

> [!NOTE]
> Project-agnostic Pre-PR Quality Gate. Dynamically enforces `.agents/rules` and `GEMINI.md` cascade rules.

## Phase 1: Scope & Rule Hydration

| Vector | Execution Contract |
|---|---|
| **Git Diff** | Execute `git diff --name-only` -> identify active modified files. |
| **Task Tracking** | MANDATORY: Create `task.md` using the strict schema below BEFORE proceeding. |
| **Rule Load** | Parse dynamically loaded `GEMINI.md` Context Cascade for project gotchas. |

## Phase 2: Dynamic Classification

| Vector | Execution Contract |
|---|---|
| **`GREP_CHECKABLE`**| Gotcha can be scanned via text pattern (e.g. missing `.limit()`). |
| **`DIFF_CHECKABLE`**| Gotcha requires component parity (e.g. Entity field needs DTO field). |
| **`MANUAL_REVIEW`** | Gotcha requires human judgment (e.g. UX label clarity). |
| **Action** | Output distinct table classifying ALL loaded project gotchas into these 3 buckets. |

## Phase 3: Automated Enforcement

| Vector | Execution Contract |
|---|---|
| **Grep Audit** | Run `grep_search` on `GREP_CHECKABLE` rules against modified files. Score PASS/FAIL. IF any modified file is an API, DTO, or DB: MANDATORY re-run `grep_search` against the opposite stack (`lib/` ↔ `server/`) to verify the counterpart is updated. |
| **Diff Audit** | Check codebase for `DIFF_CHECKABLE` counterparts. IF counterpart missing → FAIL. |

> **@@SCAN**: (1) GREP gotchas count? (2) FAIL count? (3) If API/DTO modified: cross-stack counterpart confirmed?

## Phase 4: Vertical-Slice Completeness

| Vector | Execution Contract |
|---|---|
| **Trigger** | IF (modified files == Entities OR DTOs OR Models) THEN Execute. |
| **Execution** | Load `vertical-slice-completeness` skill. Run Layer Propagation Checklist. Score PASS/FAIL. |

## Phase 5: Reporting & The Hard Gate

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `preflight_report_[date].md`. |
| **Payload Schema**| `Summary Counts` | `Automated Results Table (w/ rules & FAIL details)` | `Vertical-Slice Completeness Table` | `Manual Checkboxes [ ]`. |

### Hard Gate Logic
| State | Condition | Consequence |
|---|---|---|
| **BLOCK** | ANY automated test == `FAIL` | Recommend exact fix. Prohibit PR. |
| **COND. PASS**| Only `MANUAL` items left | Yield for human checklist sign-off. |
| **CLEAR** | All PASS | Recommend `/verify` or PR merge. |

> [!IMPORTANT]
> **Script Verification Gate**:
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}\brain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
