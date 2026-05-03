# Consolidated Flutter Refactoring Plan
**Date**: 2026-05-03
**Source Reports**: 
- `docs/diagnostics/audit_code_report_20260503_060311_70e13ccc_lib_shared.md`
- `docs/diagnostics/audit_code_report_20260503_060742_70e13ccc_lib_features.md`

This document outlines the strict execution order for resolving architectural drift, hygiene issues, and test debt across the Checkly Flutter codebase.

---

## Execution Order

### Phase 1: Architecture Boundaries (Critical)
*Goal: Stop all UI layers from directly communicating with Data Access Objects (DAOs).*

| Step | ID | File(s) | Action |
| :--- | :--- | :--- | :--- |
| **1** | CS-2 | `sync_engine.dart`, `main_shell.dart` | **Delegate Outbox:** Add `watchExhaustedCount`, `discardExhausted`, and `requeueExhausted` to `SyncEngine`. Remove `OutboxDao` from `main_shell.dart`. |
| **2** | CF-2 | `sign_out_tile.dart` | **Tile Fix:** Replace `OutboxDao` calls with the new `SyncEngine` methods created in Step 1. |
| **3** | CF-1 | `dashboard_manager.dart`, `action_required_widget.dart` | **Widget Fix:** Add `watchPendingAssignments()` to `DashboardManager`. Remove `ProgramOutboxDao` from the widget. |

### Phase 2: Code Hygiene (Quick Wins)
*Goal: Remove dead code, duplicates, and clarify misleading stubs.*

| Step | ID | File(s) | Action |
| :--- | :--- | :--- | :--- |
| **4** | CS-1 | `main_shell.dart` | **Deduplicate:** Delete private `_shellIndexFromLocation`, import public version from `app_router.dart`. |
| **5** | CF-6 | `template_builder_page_logic.dart` | **Dead Code:** Delete empty `addPostFrameCallback` block. |
| **6** | CS-3 | `sync_api_adapter.dart` | **Documentation:** Add explicit documentation to `pullDeltas()` explaining it is a synthetic stub. |

### Phase 3: SRP & Complexity Reduction (Refactoring)
*Goal: Prevent files from exceeding the 400-line hard cap and flatten complex logic.*

| Step | ID | File(s) | Action |
| :--- | :--- | :--- | :--- |
| **7** | CF-3 | `schedule_audit_page.dart` | **Extract Widget:** Extract the 374-line `ScheduleAuditForm` into a new file `widgets/schedule_audit_form.dart`. |
| **8** | CF-4 | `template_builder_page_logic.dart` | **Flatten Logic:** Extract the nested recursive `validateGroups` closure out of `_validate()` into a testable private extension method. |

### Phase 4: Test Coverage (TDD)
*Goal: Add behavioral safety nets to critical state math and workflows.*

| Step | ID | File(s) | Action |
| :--- | :--- | :--- | :--- |
| **9** | CS-4 | `app_lifecycle_manager.dart` | **Lifecycle Tests:** Unit test the 4 C2 recovery tiers (`<5m`, `5m-12h`, `12h-7d`, `>7d`). |
| **10** | CF-5 | `action_plan_manager_transitions.dart` | **State Tests:** Unit test finite state transitions. |
| **11** | CF-5 | `audit_manager_submit.dart` | **Pipeline Tests:** Unit test submission outbox inserts and error recovery. |
| **12** | CF-5 | `audit_manager_draft.dart` | **Draft Tests:** Unit test draft key generation and restore logic. |

---

### Backlog / Deferred
| Step | ID | File(s) | Action |
| :--- | :--- | :--- | :--- |
| **Deferred** | CS-5 | `tables.dart` | Split into `cache_tables.dart` and `outbox_tables.dart` before DB Schema v30. |
