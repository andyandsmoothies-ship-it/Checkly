---
description: Infrastructure & architecture audit — database health, security posture, API completeness, and scalability.
---
# Workflow: /audit-infra
> [!NOTE]
> Read-Only structural analysis. Role: **Sentinel**. Target: Missing indexes, Auth gaps, Unbounded queries, CRUD surface.
## Step 1: Scope & Skills
- **Trigger**: Execute post-major feature release or pre-scaling.
- **Task Tracking**: MANDATORY: Create `docs/features/[topic]/task_[topic]_[YYYYMMDD_HHMMSS].md` using the strict schema below BEFORE proceeding. List ONLY the audit artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation step.
- **Skill Load**: Extract 2-3 keywords (e.g., "database", "security", "api-design") -> Search `.agents/skills/` -> Load Top 2. Explicitly output list.
```markdown
# Task: [Infrastructure Audit Topic Name]
Workflow: /audit-infra | Track: B2
## Input Lineage
- **Source Input**: `[Absolute_Path_to_Source_File_or_Input]`
## Steps
- [ ] Step 2: Scope & Skills
- [ ] Step 3: Database & Query Audit
- [ ] Step 4: Security & Data Integrity
- [ ] Step 5: API Completeness
- [ ] Step 6: Telemetry & NFR Check
- [ ] Step 7: Assessment Payload
- [ ] Step 8: Deliverable Handoff
## Artifact Inventory
| Status | File Path | Type |
| [NEW]  | docs/reports/diagnostics/audit_infra_report_[YYYYMMDD_HHMMSS].md | Report |
```
## Step 2: Database & Query Audit
- **Scalability (`🔴`)**: Scan `ToListAsync()` / `.get()`. IF missing Pagination OR Limit THEN Flag Unbounded OOM risk.
- **Indexes (`🟡`)**: Cross-check high-frequency `WHERE`/`OrderBy` clauses vs actual SQL/EF Config indexes. Flag gaps.
- **Delete Rules (`🔴`)**: Verify `OnDelete` matches delete strategy. Flag dangerous DB Cascades or hard-deletes on reference entities.
- **N+1 Loops (`🔴`)**: Scan for query execution blocks nested inside iteration arrays.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Unbounded queries count? (2) Missing indexes on high-frequency arrays? (3) Delete strategy aligned?
## Step 3: Security & Data Integrity
- **Auth Guards (`🔴`)**: Verify Explicit Role guard on EVERY mutation endpoint.
- **Leakage (`🔴`)**: Verify list endpoints scope to Role context. IF admin data accessible to user THEN FLAG.
- **Soft-Delete (`🟡`)**: Verify read queries filter by `IsActive == true`. Flag deactivated loads.
- **Validations (`🟡`)**: Verify `POST`/`PUT` endpoints do NOT blindly trust client inputs.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Endpoints missing auth guards? (2) Deactivated entities loaded? (3) Data leakage risks detected?
## Step 4: API Completeness
- **CRUD Parity**: DbContext Entities MUST have corresponding backend endpoints.
- **Client Parity**: Backend endpoints MUST have corresponding Flutter API Services.
- **Wiring**: Flutter Pages MUST call API Services (no mock dead-ends).
- **PRD Parity**: Endpoints MUST map to PRD definitions. Flag omissions.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Missing DB operations? (2) Missing Flutter API methods? (3) Features lacking endpoints?
## Step 4.5: Telemetry & NFR Check
- **Logging (`🔴`)**: Scan mutation endpoints (`POST/PUT/DELETE`). IF endpoint modifies data blindly WITHOUT `_logger.LogInformation` or `AuditLogger` THEN Flag.
- **Circuit Breakers (`🟡`)**: Verify external API calls use resilience handlers.
- **@@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Missing logs on mutations? (2) Missing resilience handlers?
## Step 5: Assessment Payload
- **Artifact Gen**: Create `audit_infra_report_[YYYYMMDD_HHMMSS].md` in `docs/reports/diagnostics/` folder. IF zero issues -> create `audit_infra_pass_[YYYYMMDD_HHMMSS].md`.
- **Severity Matrix**: `🔴 Critical` (Data loss/Security breach/Unbounded rows) | `🟡 Warning` (Performance drag/Leakage) | `🟢 Optimization` (Cleanups).
- **Actionable Fix & Trade-offs**: MANDATORY: Provide exact fix snippet or EF migration plan for EVERY finding.
  - **Complexity**: For each fix or refactor, add a **Complexity** bullet point (Low, Medium, or High) with a short, concise, plain-English explanation of EXACTLY why it is rated that way.
  - **Trade-offs / Pros & Cons**: When proposing a fix, you MUST explicitly present the **Trade-offs / Pros & Cons** of the solution. Yield to the user to make the final executive decision before jumping to implementation.
## Step 6: Deliverable Handoff
- **Verification**: Execute `list_dir` on brain directory -> Confirm report written securely.
- **Routing Map**:
  - `🔴 Critical` -> route to `/analyze-epic` or `/analyze-feature` (Arch change).
  - `🟡 Warning` -> route to `/implement` directly.
  - `🟢 Optimization` -> batch -> `/implement`.
### Final Generation Mandate (Suffix)
> [!IMPORTANT]
<output_schema>
> **Document Cleanup (Required)**:
> Automatically clean up and organize newly created markdown plans into their correct topic folders:
> // turbo

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
