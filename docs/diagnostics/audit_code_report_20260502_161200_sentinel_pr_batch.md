# Audit Code Report — Sentinel QA Scan

| Field | Value |
|---|---|
| **Date** | 2026-05-02 16:12:00 UTC+7 |
| **Persona** | Sentinel (Senior QA & Platform Auditor) |
| **Scope** | 27 files (26 found, 1 missing) from PR changeset |
| **Workflow** | `/audit-code` |

---

## Phase 2: Code Quality Scan

### Secrets Scan
**Result: CLEAN** - No hardcoded `sk_live`, `Bearer <token>`, `password=`, or `.env` references found in any scoped file.

### Dead Code & Ghost Imports

| # | Severity | File | Line | Finding | Fix |
|---|---|---|---|---|---|
| DC-1 | `🟢 Optimization` | `lib\_shared\services\sync_engine.dart` | 3 (blank line) | File contains excessive blank lines (lines 2-3, 131-132, 139-141). Minor dead whitespace. | Remove consecutive blank lines. **Complexity: Low** — cosmetic. |
| DC-2 | `🟡 Warning` | `lib\features\audit\manager\audit_manager.dart` | 40 | `_api` field is declared `unused_field` via suppress comment. The field is injected but NEVER called in the class body (submit goes to outbox). This is a **test seam** per the comment, but it means the field exists only for DI verification. | If the test seam is no longer needed (verify with test suite), remove `_api` and the `SubmissionApiService` import. If still needed, document in GEMINI.md. **Complexity: Low** — single field removal. |
| DC-3 | `🟡 Warning` | `lib\_shared\services\service_adapters.dart` | 179-185 | `OutboxAdapter.pending` always returns `[]`. `OutboxAdapter.add()` is a no-op with a comment "Entries are added directly via OutboxDao in AuditManager". Both methods satisfy the `Outbox` interface but do nothing. | Verify if the `Outbox` interface itself is still needed. If `SyncEngine` no longer reads from `Outbox.pending`, the entire `Outbox` interface + `OutboxAdapter` can be deleted. **Complexity: Medium** — requires tracing all `Outbox` interface consumers. |

**Trade-offs (DC-3):** Removing the dead adapter simplifies DI, but if a future feature plans to use the `Outbox` interface abstractly, you lose the seam. **Recommendation:** Check if any test mocks `Outbox`. If not, delete.

### Architectural Drift

| # | Severity | File | Line | Finding | Fix |
|---|---|---|---|---|---|
| AD-1 | `🔴 Critical` | `lib\_shared\services\sync_engine_drains.dart` | N/A | **GHOST FILE**: This file is listed in the PR changeset but **does not exist on disk**. Additionally, `core_audit_sync_module.dart:47` contains a comment referencing it: `"_pullGlobalRisks was merged into _pullDeltas in the original code, as seen in sync_engine_drains.dart"`. The file was likely deleted during a refactor but: (a) the PR still lists it as changed, and (b) a stale comment references it. | Remove the stale comment in `core_audit_sync_module.dart:47`. Verify the PR changeset is not carrying a deleted-file diff. **Complexity: Low** — comment deletion. |
| AD-2 | `🟡 Warning` | `lib\features\audit\manager\history_manager.dart` | 242, 293 | `_applyLocalOverrides` directly accesses `DatabaseService().db` (the raw Drift database) via `_di<DatabaseService>().db`, performing raw `SELECT` queries on `cachedTemplates`, `cachedStores`, and `draftAnswers` tables. This is a **layer boundary violation**: a Manager is bypassing DAOs to do direct table queries. | Extract these queries into a dedicated DAO method (e.g., `SubmissionDao.getTemplateTitle(id)`, `SubmissionDao.getStoreName(id)`) or a `LocalOverrideDao`. The manager should not touch raw DB tables. **Complexity: Medium** — 4 direct DB queries to extract into DAO methods. |

**Trade-offs (AD-2):** Extracting into DAOs adds ~30-40 lines across files, but cleanly enforces the Data Layer boundary. Leaving it risks other managers copying the pattern (drift creep).

### Docs Drift

| # | Severity | File | Line | Finding |
|---|---|---|---|---|
| DD-1 | `🟡 Warning` | `lib\features\audit\services\core_audit_sync_module.dart` | 47 | Comment references `sync_engine_drains.dart` which no longer exists. Stale documentation. |

---

## Phase 3: Structural Health

### File Sizing

| File | Lines | Verdict |
|---|---|---|
| `lib\_shared\database\tables.dart` | 382 | `🟡 Warning` (>250, <400) |
| `lib\features\audit\manager\audit_manager.dart` | 361 | `🟡 Warning` (>250, <400) |
| `lib\features\audit\manager\history_manager.dart` | 342 | `🟡 Warning` (>250, <400) |
| `lib\_shared\router\app_router.dart` | 323 | `🟡 Warning` (>250, <400) |
| `lib\features\audit\widgets\read_only_criterion_row.dart` | 323 | `🟡 Warning` (>250, <400) |
| `lib\_shared\database\app_database.dart` | 290 | `🟡 Warning` (>250, <400) |
| `lib\_shared\database\dao\outbox_dao.dart` | 291 | `🟡 Warning` (>250, <400) |
| `lib\features\audit\widgets\dynamic_section_summary.dart` | 276 | `🟡 Warning` (>250, <400) |
| `lib\locator.dart` | 281 | `🟡 Warning` (>250, <400) |

> **Decomposition Suggestions:**

| File | Proposed Split | Complexity |
|---|---|---|
| `tables.dart` (382 lines) | Split into `cache_tables.dart`, `outbox_tables.dart`, `metadata_tables.dart`, `program_tables.dart`. Re-export from `tables.dart` barrel. | **Medium** — Drift codegen must reference all tables in one `@DriftDatabase` annotation. The split only separates definitions; the DB annotation still imports all. |
| `history_manager.dart` (342 lines) | Extract `_applyLocalOverrides` (~140 lines) into a `local_override_hydrator.dart` helper class. | **Low** — pure function extraction. |
| `app_router.dart` (323 lines) | Extract admin routes and detail routes into separate `_adminRoutes` and `_detailRoutes` lists. Compose in `appRouter`. | **Low** — list extraction. |
| `locator.dart` (281 lines) | Split registrations by feature module: `_registerShared()`, `_registerAuth()`, `_registerAudit()`, `_registerAdmin()`, etc. Keep `configureDependencies()` as the orchestrator. | **Low** — function extraction within the same file. |

### Class Density

| File | Classes/Widgets | Verdict |
|---|---|---|
| `lib\_shared\services\service_adapters.dart` | 4 classes (`SyncApiAdapter`, `OutboxAdapter`, `AuthCheckAdapter`, `UserRoleAdapter`) | `🟡 Warning` (>3 classes — SRP violation) |
| `lib\features\audit\widgets\read_only_criterion_row.dart` | 2 classes (`ReadOnlyCriterionRow`, `_ValueChip`) | `🟢 OK` |

> **Decomposition:** `service_adapters.dart` should be split: each adapter into its own file (`sync_api_adapter.dart`, `outbox_adapter.dart`, `auth_check_adapter.dart`, `user_role_adapter.dart`). **Complexity: Low** — move + re-export from barrel.

### Method Size

All methods are within the 150-line threshold. The largest is `_applyLocalOverrides` in `history_manager.dart` at ~139 lines — borderline but within bounds.

### Private Isolation

No file consists entirely of private components. `🟢 OK`

---

## Phase 4: Coverage & Hygiene

### Stale Markers
**Result: 0 TODO/FIXME/HACK/XXX markers found across all 26 files.** `🟢 OK`

### Duplication Patterns

| # | Severity | Pattern | Files | Fix |
|---|---|---|---|---|
| DUP-1 | `🟡 Warning` | **Backoff retry logic** — `updateRetry()` + `markExhausted()` + `getEligiblePending()` pattern is duplicated across 3 DAOs: `outbox_dao.dart`, `submission_risk_outbox_dao.dart`, `program_outbox_dao.dart`. Each implements nearly identical retry state management. | 3 files | Extract a `RetryableOutboxMixin` or shared utility. **Complexity: Medium** — the Drift Companion types differ per table, but the logic pattern is identical. |
| DUP-2 | `🟢 Optimization` | **Pagination aggregation loop** — `SyncApiAdapter.pullGlobalRisks()` and `SyncApiAdapter.pullProgramAssignments()` both implement a `while` loop with page+pageSize pagination. Identical pattern. | `service_adapters.dart` lines 83-108, 119-145 | Extract a generic `_paginatedFetch()` helper. **Complexity: Low** — pure function extraction. |

**Trade-offs (DUP-1):** A mixin reduces ~60 lines of duplication but introduces generics complexity with Drift Companion types. If future DAOs follow the same pattern, ROI increases. If the 3 DAOs are stable, the duplication is tolerable.

### Coverage Gaps

| # | Severity | Module | Finding |
|---|---|---|---|
| COV-1 | `🟡 Warning` | `ProgramSyncModule` | No behavioral tests visible in scope for `_pullProgramAssignments`, `_drainProgramEvidence`, `_drainProgramPhotos`. These are core sync paths with offline implications. |
| COV-2 | `🟡 Warning` | `ActionPlanSyncModule` | Uses manual `for` loop + `try/catch` instead of `processQueue()` from `BaseSyncModule`. This means it does NOT get exponential backoff behavior. First transient failure rethrows and halts the entire sync cycle. |
| COV-3 | `🟡 Warning` | `SignOutTile` | No widget test for the 3-case outbox-aware dialog logic. Critical UX path (data loss prevention). |

### Notable Design Issue

| # | Severity | File | Line | Finding | Fix |
|---|---|---|---|---|---|
| BUG-1 | `🔴 Critical` | `lib\features\action_plans\services\action_plan_sync_module.dart` | 50-52 | `executePush()` catches all non-`ActionPlanAlreadyClosedException` errors with `markExhausted()` then **rethrows**. This means a single transient 500 error immediately exhausts the row AND crashes the sync cycle (rethrow propagates to `SyncEngine._runModuleSyncCycle`). Unlike `CoreAuditSyncModule` and `ProgramSyncModule` which use `processQueue()` with proper backoff, this module has zero retry resilience. | Migrate `ActionPlanSyncModule.executePush()` to use `BaseSyncModule.processQueue()` like the other modules. Remove the manual `for` loop + `rethrow`. **Complexity: Medium** — requires adapting the photo upload + API call into the `push` callback of `processQueue`. |

**Trade-offs (BUG-1):** Migrating to `processQueue()` gives automatic exponential backoff (2s, 4s, 8s, 60s) and exhaustion after 4 failures. Current behavior: first failure = permanent data loss + sync crash. **Strong recommendation to fix.**

---

## Severity Matrix Summary

| Severity | Count | IDs |
|---|---|---|
| `🔴 Critical` | 2 | AD-1 (ghost file), BUG-1 (action plan sync crash) |
| `🟡 Warning` | 11 | DC-2, DC-3, AD-2, DD-1, 7x file sizing, DUP-1, COV-1, COV-2, COV-3, class density |
| `🟢 Optimization` | 2 | DC-1, DUP-2 |

---

## Strict Implementation Constraints & Human Reminders

1. **BUG-1 is a data-loss risk.** Action plan evidence submitted offline can be permanently lost on first transient network error. This should be prioritized for `/implement`.
2. **AD-1 ghost file:** Verify `sync_engine_drains.dart` is not referenced anywhere else in the codebase or test suite before closing.
3. **AD-2 layer violation:** `history_manager.dart` directly queries the Drift DB. If any other PR touches this file, the DAO extraction should be bundled in.
4. All file sizing warnings are in the `🟡` band (250-400). None are `🔴 Critical` (>400).
5. No secrets detected. No TODO/FIXME markers. No ghost imports.

---

> **Routing:** Pass audit report to Builder agent (@Forge) for `/implement` (Track B).
> Priority items: **BUG-1** (action plan sync resilience) and **AD-1** (stale reference cleanup).
