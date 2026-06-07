---
description: Code quality audit — dead code, drift, conventions, and documentation freshness.
---
# Workflow: /audit-code
> [!NOTE]
> Read-Only analysis. Role: **Sentinel**. Target: "AI Slop", tech debt, formatting drift.
## Step 1: Scope & Skills
- **Trigger**: Execute weekly or on-demand. (Use `/audit-infra` for DB/architecture health).
- **Task Tracking**: MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema below BEFORE proceeding. List ONLY the audit artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation step.
- **Skill Load**: Extract 2-3 keywords (e.g., "health", "refactoring") -> Search `.agents/skills/` -> Load Top 2. Explicitly output list.
```markdown
# Task: [Code Audit Topic Name]
Workflow: /audit-code | Track: B1
## Input Lineage
- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`
## Steps
- [ ] Step 2: Scope & Skills
- [ ] Step 3: Code Quality Scan
- [ ] Step 4: Structural Health
- [ ] Step 5: Coverage & Hygiene
- [ ] Step 6: Assessment Payload
- [ ] Step 7: Deliverable Handoff
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/reports/diagnostics/audit_code_report_[YYYYMMDD_HHMMSS].md | Report |
```
## Step 2: Code Quality Scan
> [!TIP]
> **Script-First Mandate**: Do NOT manually hunt for dead code or formatting issues. First, check if a script like `.agents/scripts/audit_dead_code.py` exists. If yes: execute it via `run_command`, `view_file` the output, and record the results instantly.
- **Dead Code (`🔴`)**: Scan for unreachable branches, abandoned functions, commented logic. Flag for immediate deletion.
- **Arch. Drift (`🔴`)**: Verify layer boundaries (e.g. Page direct DB import). Flag Circular dependencies.
- **Exposed Secrets (`🔴`)**: MANDATORY: Scan codebase for hardcoded `sk_live`, `Bearer`, `password=`, or `.env` files. Flag for immediate secret rotation.
- **Docs & Formats (`🟡`)**: Compare docs vs actual code. Detect naming convention violations.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Dead code found? (2) Architectural drift detected? (3) Secrets leaked? (4) Docs updated?
## Step 3: Structural Health
- **File Sizing**: `>250 lines` -> `🟡 Warning` (Suggest splitting). `>400 lines` -> `🔴 Critical` (Mandatory Split).
- **Class Density**: `>3 Classes/Widgets per file` -> `🟡 Warning` (SRP Violation).
- **Private Isolation**: IF file == entirely private components THEN `🟡 Warning` (untestable).
- **Method Size**: `>150 lines` -> `🔴 Critical`.
- **Decomposition**: MANDATORY: Propose structural breakdown for every flagged entity.
## Step 4: Coverage & Hygiene
- **Coverage Gaps**: Flag features with zero behavioral tests (compile-gate tests != coverage).
- **Dependencies**: Scan `pubspec.yaml`, `*.csproj` for stale/unused packages.
- **Stale Markers**: Scan `TODO`/`FIXME`. IF (older than 30 days OR lacks owner) THEN Flag.
- **Duplication**: Detect copy-pasted validation/API logic. Flag for shared extraction.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Files breaking 250/400 thresholds? (2) Coverage gaps found? (3) Stale markers count?
## Step 5: Assessment Payload
- **Artifact Gen**: Create `audit_code_report_[YYYYMMDD_HHMMSS].md` in `docs/reports/diagnostics/` folder. IF zero issues -> create `audit_code_pass_[YYYYMMDD_HHMMSS].md`.
- **Severity Matrix**: `🔴 Critical` (Breaks build/Untestable) | `🟡 Warning` (Convention fail/Stale TODO) | `🟢 Optimization` (Dead code/Redundant).
- **Actionable Fix & Trade-offs**: MANDATORY: Provide exact fix command or refactor snippet for EVERY finding.
  - **Complexity**: For each refactor, add a **Complexity** bullet point (Low, Medium, or High) with a short, concise, plain-English explanation of EXACTLY why it is rated that way.
  - **Trade-offs / Pros & Cons**: You MUST present the **Trade-offs / Pros & Cons** of the solution. Yield to the user to make the final executive decision before jumping to implementation.
## Step 6: Deliverable Handoff
- **Verification**: Execute `list_dir` on `docs/reports/diagnostics/` -> Confirm report written securely.
- **Routing**: Output message: *"Pass audit report to Builder agent (@Forge) for implementation (Track B)."* -> YIELD.
### Final Generation Mandate (Suffix)
> [!IMPORTANT]
<output_schema>
> **Analysis Trace**: If requested, record the step-by-step trace of all analyzing activities from start to end in `docs/reports/diagnostics/traces/trace_analysis_[YYYYMMDD_HHMMSS].md` (short and concise).
>
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
</output_schema>
