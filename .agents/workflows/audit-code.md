---
description: Code quality audit — dead code, drift, conventions, and documentation freshness.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /audit-code

> [!NOTE]
> Read-Only analysis. Role: **Sentinel**. Target: "AI Slop", tech debt, formatting drift. 

## Phase 1: Scope & Skills

| Step | Execution Contract |
|---|---|
| **Trigger** | Execute weekly or on-demand. (Use `/audit-infra` for DB/architecture health). |
| **Task Tracking** | MANDATORY: Create `task_[ConversationID].md` using the strict schema below BEFORE proceeding. |
| **Skill Load** | Extract 2-3 keywords (e.g., "health", "refactoring") -> Search `.agents/skills/` -> Load Top 2. Explicitly output list. |

## Phase 2: Code Quality Scan

| Audit Vector | Execution Contract |
|---|---|
| **Dead Code (`🔴`)** | Scan for unreachable branches, abandoned functions, commented logic. Flag for immediate deletion. |
| **Arch. Drift (`🔴`)** | Verify layer boundaries (e.g. Page direct DB import). Flag Circular dependencies. |
| **Exposed Secrets (`🔴`)**| MANDATORY: Scan codebase for hardcoded `sk_live`, `Bearer`, `password=`, or `.env` files. Flag for immediate secret rotation. |
| **Docs & Formats (`🟡`)**| Compare docs vs actual code. Detect naming convention violations. |

> **@@SCAN**: (1) Dead code found? (2) Architectural drift detected? (3) Secrets leaked? (4) Docs updated?

## Phase 3: Structural Health 

| Smell Vector | Execution Contract & Thresholds |
|---|---|
| **File Sizing** | `>500 lines` -> `🟡 Warning`. `>1000 lines` -> `🔴 Critical` (Mandatory Split). |
| **Class Density** | `>3 Classes/Widgets per file` -> `🟡 Warning` (SRP Violation). |
| **Private Isolation**| IF file == entirely private components THEN `🟡 Warning` (untestable). |
| **Method Size** | `>150 lines` -> `🔴 Critical`. |
| **Decomposition**| MANDATORY: Propose structural breakdown for every flagged entity. |

## Phase 4: Coverage & Hygiene

| Sector | Execution Contract |
|---|---|
| **Coverage Gaps**| Flag features with zero behavioral tests (compile-gate tests != coverage). |
| **Dependencies** | Scan `pubspec.yaml`, `*.csproj` for stale/unused packages. |
| **Stale Markers**| Scan `TODO`/`FIXME`. IF (older than 30 days OR lacks owner) THEN Flag. |
| **Duplication** | Detect copy-pasted validation/API logic. Flag for shared extraction. |

> **@@SCAN**: (1) Files breaking 500/1000 thresholds? (2) Coverage gaps found? (3) Stale markers count?

## Phase 5: Assessment Payload

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `audit_code_report_[date-time]_[ConversationID].md` in `brain/` folder. IF zero issues -> create `audit_code_pass_[date]_[ConversationID].md`. |
| **Severity Matrix**| `🔴 Critical` (Breaks build/Untestable) | `🟡 Warning` (Convention fail/Stale TODO) | `🟢 Optimization` (Dead code/Redundant). |
| **Actionable Fix** | MANDATORY: Provide exact fix command or refactor snippet for EVERY finding. |

## Phase 6: Deliverable Handoff

| Step | Execution Contract |
|---|---|
| **Verification** | Execute `list_dir` on brain directory -> Confirm report written securely. |
| **Routing** | Output message: *"Pass audit report to Builder agent (@Forge) for /implement (Track B)."* -> YIELD. |

> [!IMPORTANT]
> **Script Verification Gate (MANDATORY)**:
> You MUST use the `run_command` tool to execute this script before considering the task complete.
> // turbo
> `cmd /c python .agents/scripts/verify_workflow.py "{App Data Directory}rain\{Conversation ID}"`
> - `Code 0`: *"Handoff complete."*
> - `Code 1`: Fix errors and retry. (Fail twice = Write Handoff).