---
description: Infrastructure & architecture audit — database health, security posture, API completeness, and scalability.
---

@[.agents/rules/orchestration-standards.md]

# Workflow: /audit-infra

> [!NOTE]
> Read-Only structural analysis. Role: **Sentinel**. Target: Missing indexes, Auth gaps, Unbounded queries, CRUD surface.

## Phase 1: Scope & Skills

| Step | Execution Contract |
|---|---|
| **Trigger** | Execute post-major feature release or pre-scaling. |
| **Task Tracking** | MANDATORY: Create `.agents/active_tasks/[topic]/task_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` using the strict schema below BEFORE proceeding. List ONLY the audit artifact in the Artifact Inventory. Reserve target source code files for the subsequent implementation phase. |
| **Skill Load** | Extract 2-3 keywords (e.g., "database", "security", "api-design") -> Search `.agents/skills/` -> Load Top 2. Explicitly output list. |

## Phase 2: Database & Query Audit

| Audit Vector | Execution Contract |
|---|---|
| **Scalability (`🔴`)** | Scan `ToListAsync()` / `.get()`. IF missing Pagination OR Limit THEN Flag Unbounded OOM risk. |
| **Indexes (`🟡`)** | Cross-check high-frequency `WHERE`/`OrderBy` clauses vs actual SQL/EF Config indexes. Flag gaps. |
| **Delete Rules (`🔴`)**| Verify `OnDelete` matches delete strategy. Flag dangerous DB Cascades or hard-deletes on reference entities. |
| **N+1 Loops (`🔴`)**| Scan for query execution blocks nested inside iteration arrays. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Unbounded queries count? (2) Missing indexes on high-frequency arrays? (3) Delete strategy aligned?

## Phase 3: Security & Data Integrity 

| Audit Vector | Execution Contract |
|---|---|
| **Auth Guards (`🔴`)**| Verify Explicit Role guard on EVERY mutation endpoint. |
| **Leakage (`🔴`)** | Verify list endpoints scope to Role context. IF admin data accessible to user THEN FLAG. |
| **Soft-Delete (`🟡`)**| Verify read queries filter by `IsActive == true`. Flag deactivated loads. |
| **Validations (`🟡`)**| Verify `POST`/`PUT` endpoints do NOT blindly trust client inputs. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Endpoints missing auth guards? (2) Deactivated entities loaded? (3) Data leakage risks detected?

## Phase 4: API Completeness

| Audit Vector | Execution Contract |
|---|---|
| **CRUD Parity** | DbContext Entities MUST have corresponding backend endpoints. |
| **Client Parity** | Backend endpoints MUST have corresponding Flutter API Services. |
| **Wiring** | Flutter Pages MUST call API Services (no mock dead-ends). |
| **PRD Parity**| Endpoints MUST map to PRD definitions. Flag omissisons. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Missing DB operations? (2) Missing Flutter API methods? (3) Features lacking endpoints?

## Phase 4.5: Telemetry & NFR Check

| Audit Vector | Execution Contract |
|---|---|
| **Logging (`🔴`)** | Scan mutation endpoints (`POST/PUT/DELETE`). IF endpoint modifies data blindly WITHOUT `_logger.LogInformation` or `AuditLogger` THEN Flag. |
| **Circuit Breakers (`🟡`)** | Verify external API calls use resilience handlers. |

> **MANDATORY @@SCAN**: You MUST print this checklist directly into your chat response before proceeding. (1) Missing logs on mutations? (2) Missing resilience handlers?

## Phase 5: Assessment Payload

| Step | Execution Contract |
|---|---|
| **Artifact Gen** | Create `audit_infra_report_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md` in `docs/diagnostics/` folder. IF zero issues -> create `audit_infra_pass_[YYYYMMDD_HHMMSS]_[ShortID]_[topic].md`. |
| **Severity Matrix**| `🔴 Critical` (Data loss/Security breach/Unbounded rows) | `🟡 Warning` (Performance drag/Leakage) | `🟢 Optimization` (Cleanups). |
| **Actionable Fix & Trade-offs** | MANDATORY: Provide exact fix snippet or EF migration plan for EVERY finding.<br><br>**CRITICAL:** For each fix or refactor, add a **Complexity** bullet point (Low, Medium, or High) with a short, concise, plain-English explanation of EXACTLY why it is rated that way.<br><br>**CRITICAL:** When proposing a fix, you MUST explicitly present the **Trade-offs / Pros & Cons** of the solution. Yield to the user to make the final executive decision before jumping to implementation. |

## Phase 6: Deliverable Handoff

| Step | Execution Contract |
|---|---|
| **Verification** | Execute `list_dir` on brain directory -> Confirm report written securely. |
| **Routing Map** | `🔴 Critical` -> route to `/analyze-epic` or `/analyze-feature` (Arch change). |
| **Routing Map** | `🟡 Warning` -> route to `/implement` directly. |
| **Routing Map** | `🟢 Optimization` -> batch -> `/implement`. |

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
