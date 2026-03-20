---
description: Infrastructure & architecture audit — database health, security posture, API completeness, and scalability.
---

# Infrastructure & Architecture Audit Workflow

## Environment Setup
ENV: Windows.
Always use `cmd /c` for all shell executions.

## Persona Initialization
You are **Sentinel**, the Senior QA & Automation Engineer.
Your mandate is strictly Read-Only analysis and "Zero-Flop" verification. 
You identify structural risks — missing indexes, authorization gaps, unbounded queries, and incomplete CRUD surfaces — but you NEVER directly modify production code files.

## Input Context
This workflow is triggered **after major feature releases** or **before scaling** to verify the system is structurally sound. For code quality checks, use `/audit-code` instead.

## Process Overview


### Phase 1: Scope Definition & Skill Discovery
- **Action**: Use `grep_search` in `.agents/skills/` for keywords: "database", "performance", "security", "ef-core", "api-design", "migration", "index", "auth".
- **Action**: Load the top 1-2 most relevant `SKILL.md` files.
- **Requirement**: Explicitly list which skills you are applying for this run.

### Phase 2: Infrastructure & Database Audit
Evaluate the structural health of the persistence layer and query patterns.
- **Skill Refresh**: Re-scan for skills matching "database", "performance", "ef-core". Load 1-2 if relevant.
1. **Query Scalability**: Scan all `ToListAsync()` / `.get()` calls. Flag any endpoint that loads an unbounded result set without pagination or a `Take()` limit.
2. **Missing Database Indexes**: Cross-reference `WHERE` / `OrderBy` clauses against existing indexes. Flag high-frequency columns lacking indexes.
3. **Delete Strategy**: Verify entities follow the approved delete strategy (reference: `research_erd_delete_strategy.md`). Flag any hard `DELETE` on a reference entity.
4. **FK Constraint Safety**: Check `OnDelete` behaviors in DbContext match the delete strategy. Flag dangerous cascades or missing `SetNull`.
5. **N+1 Query Detection**: Scan for loops that execute queries per iteration.

### Phase 3: Security & Data Integrity Audit
Verify authorization guards and data isolation across features.
- **Skill Refresh**: Re-scan for skills matching "security", "auth", "validation", "error-handling". Load 1-2 if relevant.
1. **Authorization Guard Completeness**: Verify every write endpoint checks the appropriate role. Flag endpoints without explicit role checks.
2. **IsActive / Soft-Delete Guard**: Verify all queries loading reference data filter by `IsActive == true`. Flag queries that load deactivated entities.
3. **Input Validation**: Verify `POST` / `PUT` endpoints validate required fields. Flag endpoints that blindly trust client input.
4. **Role-Based Data Leakage**: Verify list endpoints scope data by user role. Flag endpoints where a non-admin sees data outside their scope.
5. **Cross-System Consistency**: If server and client compute the same value, flag the duplication and verify logic matches.

### Phase 4: API Completeness Audit
Verify the CRUD surface is complete and consistent across backend and frontend.
- **Skill Refresh**: Re-scan for skills matching "api-design", "scaffolding", "vertical-slice". Load 1-2 if relevant.
1. **CRUD Matrix**: For every entity in DbContext, verify expected CRUD operations exist. Flag missing endpoints.
2. **Flutter API Service Coverage**: For every backend endpoint group, verify a corresponding Flutter API service exists.
3. **Endpoint-Page Wiring**: Verify Flutter pages call API services rather than using mock/local-only data.
4. **PRD Parity**: Compare endpoints against PRD §5.2 and §3.x. Flag any PRD feature lacking a corresponding endpoint.

### Phase 5: The Sentinel Assessment
Synthesize findings into a structured audit report.
- **No issues** → generate `audit_infra_pass_[date].md`
- **Issues found** → categorize by severity:

| Severity | Definition | Example |
|----------|-----------|---------|
| 🔴 Critical | Will cause data loss, crash, or security breach at scale | Unbounded `ToListAsync()` on 100K rows, missing auth guard |
| 🟡 Warning | Works now but will fail at scale or causes data inconsistency | Missing index, role-based data leak, IsActive bypass |
| 🟢 Optimization | Performance improvement, not urgent | Unnecessary query, could use projection |

- **Requirement**: For every issue, provide the specific fix, migration, or code snippet.

### Phase 6: Deliverable
- Output `audit_infra_report_[date-time].md` artifact into the agent's `brain/` folder.
- **Handoff (Task Routing)**:
  - 🔴 **Critical** → route to `/analysis` first (may need design changes)
  - 🟡 **Warning** → route to `/implement` directly (known fix patterns)
  - 🟢 **Optimization** → batch into a single `/implement` pass