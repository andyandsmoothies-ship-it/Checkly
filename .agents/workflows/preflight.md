---
description: Pre-PR quality gate — dynamically enforces project gotchas and vertical-slice completeness.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /preflight

> [!NOTE]
> Project-agnostic Pre-PR Quality Gate. Dynamically enforces `.agents/rules` and `GEMINI.md` cascade rules.

## Phase 1: Scope & Rule Hydration

| Vector | Execution Contract |
|---|---|
| **Git Diff** | Execute `git diff --name-only` -> identify active modified files. |
| **Task Tracking** | MANDATORY: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` using the strict schema below BEFORE proceeding. |
| **Rule Load** | Parse dynamically loaded `GEMINI.md` Context Cascade for project gotchas. |

## Phase 2: Dynamic Classification

| Vector | Execution Contract |
|---|---|
| **`GREP_CHECKABLE`**| Gotcha can be scanned via text pattern (e.g. missing `.limit()`). |
| **`DIFF_CHECKABLE`**| Gotcha requires component parity (e.g. Entity field needs DTO field). |
| **`MANUAL_REVIEW`** | Gotcha requires human judgment (e.g. UX label clarity). |
| **Action** | Output distinct table classifying ALL loaded project gotchas into these 3 buckets. |

## Phase 3: Automated Enforcement (Polymorphic)

| Vector | Execution Contract |
|---|---|
| **Core Audits** | Run `grep_search` on `GREP_CHECKABLE` and `DIFF_CHECKABLE` rules against modified files. Score PASS/FAIL. |
| **Secret Scan (🔴)**| MANDATORY: `grep_search` modified files for `sk_test`, `sk_live`, `password=`, `Bearer`, or API keys. IF `.env` exists in git diff → BLOCK. |
| **Compile/Format** | **Detect Stack:** Identify the tech stack (e.g., `package.json`, `.csproj`, `pubspec.yaml`, `go.mod`). **Execute:** Run the native compiler and formatter. BLOCK on fail. |
| **Test Matrix** | **Detect Stack:** Identify test runner. **Execute:** Run the native test suite (e.g., `dotnet test`, `jest`, `go test`). BLOCK on fail. |
| **Contract Sync** | IF the repo contains a Split-Stack (e.g., Backend + Frontend): MANDATORY check that any altered DTOs/DB Models in the backend were also updated in the frontend API calls. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Stack detected? (2) Compile/Tests passing? (3) Any exposed secrets leaked? (4) If Split-Stack, are DTOs synchronized?

## Phase 4: Vertical-Slice Completeness

| Vector | Execution Contract |
|---|---|
| **Trigger** | IF (modified files == Entities OR DTOs OR Models) THEN Execute. |
| **Execution** | Load `vertical-slice-completeness` skill. Run Layer Propagation Checklist. Score PASS/FAIL. |

## Phase 5: Reporting & The Hard Gate

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `preflight_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md`. |
| **Payload Schema**| `Summary Counts` | `Automated Results Table (w/ rules & FAIL details)` | `Vertical-Slice Completeness Table` | `Manual Checkboxes [ ]`. |

### Hard Gate Logic
| State | Condition | Consequence |
|---|---|---|
| **BLOCK** | ANY automated test == `FAIL` | Recommend exact fix. Prohibit PR. |
| **COND. PASS**| Only `MANUAL` items left | Yield for human checklist sign-off. |
| **CLEAR** | All PASS | Recommend `/verify` or PR merge. |

> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{Absolute Path to your task tracker .md file}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).
<mandatory_constraints>
- NEVER execute `git` commands. Yield to the user.
- TESTS ALWAYS WIN over Markdown plans.
</mandatory_constraints>
