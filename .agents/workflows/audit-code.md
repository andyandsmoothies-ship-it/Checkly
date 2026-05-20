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
| **Task Tracking** | MANDATORY: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` using the strict schema below BEFORE proceeding. List ONLY the audit artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation phase. |
| **Skill Load** | Extract 2-3 keywords (e.g., "health", "refactoring") -> Search `.agents/skills/` -> Load Top 2. Explicitly output list. |

## Phase 2: Code Quality Scan

> [!TIP]
> **Script-First Mandate**: Do NOT manually hunt for dead code or formatting issues. First, check if a script like `.agents/scripts/audit_dead_code.py` exists. If yes: execute it via `run_command`, `view_file` the output, and record the results instantly.
| Audit Vector | Execution Contract |
|---|---|
| **Dead Code (`🔴`)** | Scan for unreachable branches, abandoned functions, commented logic. Flag for immediate deletion. |
| **Arch. Drift (`🔴`)** | Verify layer boundaries (e.g. Page direct DB import). Flag Circular dependencies. |
| **Exposed Secrets (`🔴`)**| MANDATORY: Scan codebase for hardcoded `sk_live`, `Bearer`, `password=`, or `.env` files. Flag for immediate secret rotation. |
| **Docs & Formats (`🟡`)**| Compare docs vs actual code. Detect naming convention violations. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Dead code found? (2) Architectural drift detected? (3) Secrets leaked? (4) Docs updated?

## Phase 3: Structural Health 

| Smell Vector | Execution Contract & Thresholds |
|---|---|
| **File Sizing** | `>250 lines` -> `🟡 Warning` (Suggest splitting). `>400 lines` -> `🔴 Critical` (Mandatory Split). |
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

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Files breaking 250/400 thresholds? (2) Coverage gaps found? (3) Stale markers count?

## Phase 5: Assessment Payload

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `audit_code_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` in `docs/diagnostics/` folder. IF zero issues -> create `audit_code_pass_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md`. |
| **Severity Matrix**| `🔴 Critical` (Breaks build/Untestable) | `🟡 Warning` (Convention fail/Stale TODO) | `🟢 Optimization` (Dead code/Redundant). |
| **Actionable Fix & Trade-offs** | MANDATORY: Provide exact fix command or refactor snippet for EVERY finding.<br><br>**CRITICAL:** For each refactor, add a **Complexity** bullet point (Low, Medium, or High) with a short, concise, plain-English explanation of EXACTLY why it is rated that way.<br><br>**CRITICAL:** You MUST present the **Trade-offs / Pros & Cons** of the solution. Yield to the user to make the final executive decision before jumping to implementation. |

## Phase 6: Deliverable Handoff

| Step | Execution Contract |
|---|---|
| **Verification** | Execute `list_dir` on brain directory -> Confirm report written securely. |
| **Routing** | Output message: *"Pass audit report to Builder agent (@Forge) for implementation (Track B)."* -> YIELD. |

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
