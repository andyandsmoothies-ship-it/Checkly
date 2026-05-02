# Walkthrough: SyncEngine Transactional Fracture Fix

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260502_112521_5badbf76_fix_sync_transactional_fracture.md`

## Strict Implementation Constraints & Human Reminders
- Do not wrap HTTP pushes inside a Drift transaction; the checkpoint must remain a fast local write after the network success.
- Only `_drainSubmissions()` gets the checkpoint hook. `_drainRisks()`, `_drainProgramEvidence()`, and `_drainProgramPhotos()` keep their existing semantics.
- Startup sweep must delete orphaned `submission_synced` rows without re-pushing them.
- Existing retry/fatal/conflict behavior from `test/shared/services/sync_engine_backoff_test.dart` remains the source of truth.

## Decision Log
- **Proposed:** add a two-phase checkpoint around successful submission pushes and clean up orphaned `submission_synced` rows at the start of each sync cycle.
- **Implemented:** added `markSynced()` and `sweepSyncedSubmissions()` to `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\dao\outbox_dao.dart`, invoked the sweep at the top of `SyncEngine._requestSyncInternal()` in `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\sync_engine.dart`, and added an optional `onPushSucceeded` hook to `_processQueue<T>()` in `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services\sync_engine_drains.dart` that `_drainSubmissions()` uses to write the checkpoint before delete.
- **Behavior preserved:** transient failures still back off and stop the active queue, fatal submission errors still exhaust immediately, and risk `409` remains a success path.
- **Supportability:** all modified files remain under 400 lines; `outbox_dao.dart` is 291 lines, `sync_engine.dart` is 226 lines, and `sync_engine_drains.dart` is 282 lines.

## Verification Handoff
- Run `flutter analyze lib/_shared/services/sync_engine.dart lib/_shared/services/sync_engine_drains.dart lib/_shared/database/dao/outbox_dao.dart`.
- Run `flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded`.
- Run `flutter test test --reporter=expanded`.
- Recheck the checkpoint path before changing `_processQueue<T>()`; moving `onPushSucceeded` after delete would reopen the crash window.

<test_trace>
```text
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart
00:00 +0: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S1: SM submits evidence → status = pending_verify
00:00 +1: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S2: Auditor closes plan → status = closed
00:00 +2: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S3: Auditor rejects evidence → status = open
00:00 +3: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S4: SM cannot close plan — throws RoleGuardException
00:00 +4: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S5: Auditor cannot submit evidence — throws RoleGuardException
00:00 +5: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S6: Closed is terminal — any transition throws
00:00 +6: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S7: Open plan past deadline is overdue
00:00 +7: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S7b: Closed plan past deadline is NOT overdue
00:00 +8: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: S8: Allowed transitions per status
00:00 +9: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads
00:00 +10: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads
00:00 +11: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads
00:00 +12: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads
00:00 +13: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_01: Manager_LoadActionPlans_WhenOnline_FetchesAndStoresAndReads
00:00 +14: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_02: Manager_LoadActionPlans_WhenOffline_ReadsFromCacheOnly
00:00 +15: C:/Users/HP/Documents/GitHub/Checkly/test/action_plan_manager_test.dart: Pull Engine AP_PULL_03: Manager_LoadActionPlans_WhenNetworkFails_GracefullyReadsCache
00:00 +16: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/action_plan_outbox_dao_stale_test.dart: ActionPlanOutboxDao Stale Conflict Tests (Slice 3) FL-DAO-SC-01: ActionPlanOutboxDao_markStaleConflict_UpdatesSyncStatusToStaleConflict
00:00 +17: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/action_plan_outbox_dao_stale_test.dart: ActionPlanOutboxDao Stale Conflict Tests (Slice 3) FL-DAO-SC-02: ActionPlanOutboxDao_getStaleConflictForPlan_ReturnsRowWhenStatusIsStaleConflict
00:00 +18: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/action_plan_outbox_dao_stale_test.dart: ActionPlanOutboxDao Stale Conflict Tests (Slice 3) FL-DAO-SC-03: ActionPlanOutboxDao_getStaleConflictForPlan_ReturnsNullWhenNoPendingRow
00:00 +19: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: (setUpAll)
00:00 +19: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — submitEvidence (store_manager) S1: succeeds online and updates status to pending_verify
00:00 +20: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — submitEvidence (store_manager) S2: enqueues to outbox when offline without calling API
00:00 +21: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — submitEvidence (store_manager) S3: throws RoleGuardException if role is not store_manager
00:00 +22: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — submitEvidence (store_manager) S4: throws InvalidTransitionException if plan is not open
00:00 +23: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — closePlan (auditor/admin) S5: succeeds for auditor when pending_verify
00:00 +24: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — closePlan (auditor/admin) S6: throws RoleGuardException if role is store_manager
00:00 +25: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — rejectEvidence (auditor/admin) S7: succeeds for admin when pending_verify
00:00 +26: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — isOverdue S8: returns true if open and past deadline
00:00 +27: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: ActionPlanManager State Machine & Rules — isOverdue returns false if not open even if past deadline
00:00 +28: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/manager/action_plan_manager_test.dart: (tearDownAll)
00:00 +28: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/sync_engine_action_plan_stale_state_test.dart: SyncEngine ActionPlan Stale State Tests (Slice 2) FE-SYNC-AP-409-01: SyncEngine_WhenActionPlanApiThrowsActionPlanAlreadyClosedException_RemovesOutboxEntry_AndContinuesBatch
00:01 +29: C:/Users/HP/Documents/GitHub/Checkly/test/features/action_plans/sync_engine_action_plan_stale_state_test.dart: SyncEngine ActionPlan Stale State Tests (Slice 2) FL-SYNC-SC-01: SyncEngine_WhenActionPlanAlreadyClosed_MarksStaleConflict_AndContinuesBatch
00:01 +30: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_capability_meta_test.dart: RoleManager — PBAC Slice 2: Catalog Metadata loadCatalog populates both catalog and catalogMeta from getCapabilityCatalogFull
00:01 +31: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_capability_meta_test.dart: RoleManager — PBAC Slice 2: Catalog Metadata loadCatalog populates both catalog and catalogMeta from getCapabilityCatalogFull
00:01 +32: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_capability_meta_test.dart: RoleManager — PBAC Slice 2: Catalog Metadata loadCatalog populates both catalog and catalogMeta from getCapabilityCatalogFull
00:01 +33: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_test.dart: RoleManager State & Commands — loadRoles updates roles on success
00:01 +34: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_test.dart: RoleManager State & Commands — loadRoles sets error and clears roles on failure
00:01 +35: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_test.dart: RoleManager State & Commands — loadCatalog updates catalog quietly
00:01 +36: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_test.dart: RoleManager State & Commands — grantCommand executes grant and reloads roles
00:01 +37: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/manager/role_manager_test.dart: RoleManager State & Commands — revokeCommand executes revoke and reloads roles
00:01 +38: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/admin_dashboard_page_test.dart: AdminDashboard — Load Counts AdminDashboard_LoadCounts_ShowsSnackBarOnApiFailure — SnackBar visible when API throws
00:02 +39: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/admin_dashboard_page_test.dart: AdminDashboard — Load Counts AdminDashboard_LoadCounts_ShowsSnackBarOnApiFailure — SnackBar visible when API throws
00:02 +40: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/admin_dashboard_page_test.dart: AdminDashboard — Load Counts AdminDashboard_LoadCounts_ShowsSnackBarOnApiFailure — SnackBar visible when API throws
00:03 +41: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/audit_approval_page_test.dart: AuditApprovalPage — Loading State AuditApproval_Loading_ShowsProgressIndicator — CircularProgressIndicator visible while manager is loading
00:03 +42: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/audit_approval_page_test.dart: AuditApprovalPage — Loading State AuditApproval_Loading_ShowsProgressIndicator — CircularProgressIndicator visible while manager is loading
00:03 +43: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/audit_approval_page_test.dart: AuditApprovalPage — Loading State AuditApproval_Loading_ShowsProgressIndicator — CircularProgressIndicator visible while manager is loading
00:03 +44: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_detail_page_self_modification_test.dart: Self-modification guard disables admin:access toggle for admin role
00:03 +45: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_detail_page_self_modification_test.dart: Self-modification guard disables admin:access toggle for admin role
00:03 +46: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_detail_page_self_modification_test.dart: Self-modification guard disables admin:access toggle for admin role
00:03 +47: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_detail_page_self_modification_test.dart: Self-modification guard disables admin:access toggle for admin role
00:03 +48: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-01: RoleListPage_WhenOffline_ShowsOfflineLock
00:03 +49: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-01: RoleListPage_WhenOffline_ShowsOfflineLock
00:03 +50: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/admin_dashboard_page_test.dart: AdminDashboard — Terminology AdminDashboard_StatLabel_ShowsOpenPlans — OPEN PLANS visible, PENDING absent
00:03 +51: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +52: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +53: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +54: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +55: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +56: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +57: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +58: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +59: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +60: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +61: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +62: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +63: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +64: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: AuditCriterionRow displays F:X in red for numeric input in accumulation mode
00:04 +65: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_manager_scoring_mode_test.dart: AuditManager.scoringMode returns accumulation when template is configured for maturity assessment
00:04 +66: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-05: RoleDetailPage_AtomicFailure_SnackBar
00:04 +67: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-05: RoleDetailPage_AtomicFailure_SnackBar
00:04 +68: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-05: RoleDetailPage_AtomicFailure_SnackBar
00:04 +69: C:/Users/HP/Documents/GitHub/Checkly/test/features/admin/pages/role_management_atdd_test.dart: ATDD — PBAC Admin Dashboard Flow AT-05: RoleDetailPage_AtomicFailure_SnackBar
00:04 +70: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays count for multi_choice INSIDE badge
00:04 +71: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays full text for text type without badge and without truncation
00:04 +72: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_manager_test.dart: (setUpAll)
00:04 +72: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays PASS/FAIL for pass_fail type INSIDE badge
00:04 +73: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays PASS/FAIL for pass_fail type INSIDE badge
00:04 +74: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays PASS/FAIL for pass_fail type INSIDE badge
00:04 +75: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_manager_test.dart: startAudit calls DraftService.loadDraft once
00:04 +76: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays selected label for scale type without badge
00:04 +77: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays selected label for scale type without badge
00:04 +78: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays selected label for scale type without badge
00:04 +79: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays selected label for scale type without badge
00:04 +80: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays selected label for scale type without badge
00:04 +81: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_manager_test.dart: restoreDraft discardDraft clears the pending draft and hasDraft → false
00:04 +82: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays scale label AND points badge in accumulation mode
00:04 +83: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays scale label AND points badge in accumulation mode
00:04 +84: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_criterion_row_rendering_test.dart: Non-Scored Criteria Badges displays scale label AND points badge in accumulation mode
00:05 +85: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_gc_test.dart: HistoryManager - searchCloudArchive (AC5) AC5a — SearchCloudArchive_ReturnsResults_SetsHasArchivedRecordsTrue: API returns old submissions → hasArchivedRecords becomes true
00:05 +86: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_gc_test.dart: HistoryManager - searchCloudArchive (AC5) AC5b — SearchCloudArchive_ReturnsEmpty_SetsHasArchivedRecordsFalse: API returns empty list → hasArchivedRecords is false
00:05 +87: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/manager/history_manager_gc_test.dart: HistoryManager - searchCloudArchive (AC5) AC5c — SearchCloudArchive_NetworkFailure_SetsErrorButBannerPersists: API throws → error state is set, hasArchivedRecords unchanged
00:05 +88: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/model/submission_dto_test.dart: SubmissionDto Void Status SubmissionDto parses voidReason and voidedAt correctly
00:05 +89: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: (setUpAll)
00:05 +89: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:05 +90: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +91: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +92: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +93: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +94: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +95: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +96: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +97: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +98: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +99: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +100: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +101: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +102: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +103: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +104: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +105: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +106: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +107: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +108: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +109: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +110: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +110: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_capability_sync_test.dart: AuthManager — Capability Sync (ATDD Slice 4) AT-04: login() succeeds even if capability fetch fails (fail-open)
[PBAC] Capability sync failed (non-fatal): Exception: Server down
00:06 +111: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: AuditFormPage._onSubmit calculates missingRequired based on individual and global config
00:06 +112: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_refresh_capabilities_test.dart: AuthManager — PBAC Slice 1: Capability Refresh — refreshCapabilities fetches fresh caps and updates cache when authenticated
00:06 +113: C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/pages/audit_form_page_required_test.dart: (tearDownAll)
00:06 +113: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_refresh_capabilities_test.dart: AuthManager — PBAC Slice 1: Capability Refresh — refreshCapabilities is blocked by 5-minute cooldown guard
00:06 +114: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_refresh_capabilities_test.dart: AuthManager — PBAC Slice 1: Capability Refresh — refreshCapabilities ignores call if unauthenticated
00:06 +115: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_refresh_capabilities_test.dart: (tearDownAll)
00:07 +115: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_test.dart: (setUpAll)
00:07 +115: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_test.dart: AuthManager — login succeeds and sets authenticated state
00:07 +116: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_test.dart: AuthManager — login fails and sets unauthenticated state
00:07 +117: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_test.dart: AuthManager — logout clears everything
00:07 +118: C:/Users/HP/Documents/GitHub/Checkly/test/features/auth/manager/auth_manager_test.dart: (tearDownAll)
00:07 +118: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-02: Should return ManagerDashboardState when stores are empty
00:07 +119: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-03 & TC-04: Should set storeName to "Syncing..." and storeId to null when empty
00:07 +120: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_manager_test.dart: DashboardManager IA Overhaul (TC-01...TC-04) TC-05: Should pull personal metrics despite empty store cache
00:07 +121: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:07 +122: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:07 +123: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:07 +124: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +125: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +126: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +127: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +128: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +129: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +130: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-01 & VC-02: Greeting should have overline and correct style
00:08 +131: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-03: DeadlineBanner border should be removed
00:08 +132: C:/Users/HP/Documents/GitHub/Checkly/test/features/dashboard/dashboard_widgets_test.dart: Dashboard Visual Contracts (VC-01...VC-05) VC-04 & VC-05: SubmissionRow score circle and font
00:08 +133: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/manager/notification_wiring_test.dart: TC_Wiring_1: App lifecycle resume triggers NotificationSyncManager.onTickle
00:09 +134: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/manager/notification_wiring_test.dart: TC_Wiring_1: App lifecycle resume triggers NotificationSyncManager.onTickle
00:09 +135: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/manager/notification_wiring_test.dart: TC_Wiring_1: App lifecycle resume triggers NotificationSyncManager.onTickle
00:09 +136: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/manager/notification_wiring_test.dart: TC_Wiring_1: App lifecycle resume triggers NotificationSyncManager.onTickle
00:09 +137: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage — Tab Filtering TC1.2b: All tab shows all notifications (read + unread)
00:10 +138: C:/Users/HP/Documents/GitHub/Checkly/test/features/notifications/pages/inbox_page_test.dart: InboxPage — Tab Filtering TC1.2b: All tab shows all notifications (read + unread)
00:10 +139: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +140: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +141: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +142: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +143: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +144: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +145: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +146: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +147: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +148: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +149: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +150: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +151: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +152: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +153: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +154: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +155: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +156: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +157: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +158: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +159: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +160: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +161: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +162: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +163: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +164: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +165: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +166: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +167: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +168: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +169: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +170: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +171: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +172: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +173: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +174: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:10 +175: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +176: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +177: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +178: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +179: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +180: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +181: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +182: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +183: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +184: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +185: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +186: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +187: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +188: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +189: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +190: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Stats Row Removal profilePage_StatsRow_IsAbsent — stats labels must not render after refactor
00:11 +191: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +192: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +193: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +194: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +195: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +196: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +197: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +198: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +199: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +200: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +201: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +202: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +203: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +204: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +205: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +206: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +207: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +208: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +209: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +210: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +211: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +212: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +213: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +214: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +215: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +216: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +217: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +218: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +219: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +220: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +221: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +222: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +223: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +224: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +225: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +226: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +227: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +227: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Identity Header Layout profilePage_IdentityHeader_IsHorizontalRow — CircleAvatar and email must share a Row ancestor
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
00:11 +228: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +228: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Identity Header Layout profilePage_IdentityHeader_IsHorizontalRow — CircleAvatar and email must share a Row ancestor
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:172:9)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:11 +229: C:/Users/HP/Documents/GitHub/Checkly/test/features/programs/program_execution_needs_revision_test.dart: ProgramExecutionPage shows Needs Revision banner when status is needs_revision
00:11 +230: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Sign Out Confirmation profilePage_SignOut_TriggersConfirmationDialog — AlertDialog shown before logout is called
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:209:26)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:11 +231: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Sign Out Confirmation profilePage_SignOut_ConfirmCallsLogout — confirming the dialog calls logout exactly once
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:237:26)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:11 +232: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:11 +232: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Settings Card Grouping profilePage_Settings_RenderInCards — at least 2 Card widgets must wrap menu items
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:275:9)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:11 +233: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +233: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Dark Mode Compatibility ProfilePage_EmailText_UsesOnSurfaceColor — email text color must adapt to theme brightness
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:297:9)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:12 +234: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +235: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +236: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +237: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +238: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +239: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +240: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +241: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +242: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +243: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +244: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +245: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +246: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +247: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +248: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +249: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +250: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +250: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Real Name Display ProfilePage_DisplayName_ShowsFullName — header must prefer fullName over email
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:353:9)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:12 +251: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +251: C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart: ProfilePage — Real Name Display ProfilePage_DisplayName_FallsBackToEmail — header must show email when fullName is null
WARNING (drift): It looks like you've created the database class AppDatabase multiple times. When these two databases use the same QueryExecutor, race conditions will occur and might corrupt the database. 
Try to follow the advice at https://drift.simonbinder.eu/faq/#using-the-database or, if you know what you're doing, set driftRuntimeOptions.dontWarnAboutMultipleDatabases = true
Here is the stacktrace from when the database was opened a second time:
#0      GeneratedDatabase._handleInstantiated (package:drift/src/runtime/api/db_base.dart:96:30)
#1      GeneratedDatabase._whenConstructed (package:drift/src/runtime/api/db_base.dart:73:12)
#2      new GeneratedDatabase (package:drift/src/runtime/api/db_base.dart:64:5)
#3      new _$AppDatabase (package:checkly/_shared/database/app_database.g.dart:11761:36)
#4      new AppDatabase.forTesting (package:checkly/_shared/database/app_database.dart)
#5      _registerDi (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:93:30)
#6      main.<anonymous closure>.<anonymous closure> (file:///C:/Users/HP/Documents/GitHub/Checkly/test/features/profile/pages/profile_page_test.dart:381:9)
#7      testWidgets.<anonymous closure>.<anonymous closure> (package:flutter_test/src/widget_tester.dart:192:29)
<asynchronous suspension>
#8      TestWidgetsFlutterBinding._runTestBody (package:flutter_test/src/binding.dart:1682:5)
<asynchronous suspension>
#9      StackZoneSpecification._registerCallback.<anonymous closure> (package:stack_trace/src/stack_zone_specification.dart:114:42)
<asynchronous suspension>
This warning will only appear on debug builds.
00:12 +252: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +253: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +254: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +255: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +256: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +257: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +258: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +259: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +260: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +261: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +262: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +263: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +264: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +265: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +266: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +267: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +268: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +269: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +270: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +271: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:12 +272: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-06a: FAB is hidden for auditor role
00:13 +273: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +274: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +275: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +276: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +277: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +278: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +279: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +280: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/widgets/advanced_settings_card_test.dart: AdvancedSettingsCard - Require Confirmation UI Tests Renders "Require Confirmation" toggle and triggers callback
00:13 +281: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +282: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +283: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +284: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +285: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +286: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +287: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +288: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +289: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +290: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-07: Context menu admin sees all 4 items
00:13 +291: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-08: Context menu auditor sees only Quick Start
00:14 +292: C:/Users/HP/Documents/GitHub/Checkly/test/features/templates/template_list_page_rbac_test.dart: TemplateListPage RBAC Tests TC-08: Context menu auditor sees only Quick Start
00:14 +293: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/drift_migration_void_cascade_test.dart: SQLite cascade trigger closes action plans on AFTER INSERT
00:14 +294: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/gc_pruning_test.dart: AC1a â€” GC_PruneStaleCompletedAudits: completed record > 90 days is deleted on db open
00:14 +295: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/gc_pruning_test.dart: AC1b â€” GC_PruneStaleVoidedAudits: voided record > 90 days is deleted on db open
00:14 +296: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/gc_pruning_test.dart: AC2 â€” GC_PreservesRecentAudits: completed record < 90 days is NOT deleted
00:14 +297: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/gc_pruning_test.dart: AC3 â€” GC_NullCompletedAt_NoDelete: completed record with NULL completedAt is NOT pruned
00:14 +298: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/outbox_dao_backoff_test.dart: AC1: OutboxDao_NewSubmission_HasDefaultBackoffState
00:14 +299: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/outbox_dao_backoff_test.dart: AC1: OutboxDao_NewSubmission_HasDefaultBackoffState
00:14 +300: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/outbox_dao_backoff_test.dart: AC2: OutboxDao_GetEligiblePending_ExcludesFutureRetry
00:14 +301: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/outbox_dao_backoff_test.dart: AC3: OutboxDao_GetEligiblePending_IncludesPastRetry
00:14 +302: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/outbox_dao_backoff_test.dart: AC7: OutboxDao_WatchExhaustedCount_EmitsPositiveSum
00:14 +303: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:14 +304: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:14 +305: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/pending_photos_migration_test.dart: AC7: PendingPhotos_Schema_AnswerIdColumnIsNullable - Optional answerId saves correctly
00:14 +306: C:/Users/HP/Documents/GitHub/Checkly/test/shared/database/pending_photos_migration_test.dart: AC8: PendingPhotos_Migration_ExistingRowsPreserved - AnswerId preserves backwards compatibility returning null
00:14 +307: C:/Users/HP/Documents/GitHub/Checkly/test/shared/router/app_router_test.dart: Router — shellIndexFromLocation _indexFromLocation_AdminRoute_ReturnsProfileIndex — /admin/dashboard maps to tab 4
00:14 +308: C:/Users/HP/Documents/GitHub/Checkly/test/shared/router/app_router_test.dart: Router — shellIndexFromLocation _indexFromLocation_AdminSubRoute_ReturnsProfileIndex — /admin/users maps to tab 4
00:14 +309: C:/Users/HP/Documents/GitHub/Checkly/test/shared/router/app_router_test.dart: Router — shellIndexFromLocation _indexFromLocation_ProfileRoute_ReturnsProfileIndex — /profile maps to tab 4
00:14 +310: C:/Users/HP/Documents/GitHub/Checkly/test/shared/router/app_router_test.dart: Router — shellIndexFromLocation _indexFromLocation_HomeRoute_ReturnsZero — /home maps to tab 0
00:14 +311: C:/Users/HP/Documents/GitHub/Checkly/test/shared/router/app_router_test.dart: Router — shellIndexFromLocation _inbox_Route_ExistsInShell — /inbox maps to tab 5
00:15 +312: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +313: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +314: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +315: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +316: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +317: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +318: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +319: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +320: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +321: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +322: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +323: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +324: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +325: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +326: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +327: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +328: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +329: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +330: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +331: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +332: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:15 +333: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +334: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +335: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +336: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +337: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +338: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +339: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +340: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +341: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +342: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +343: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +344: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +345: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +346: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +347: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +348: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +349: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +350: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +351: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +352: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +353: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +354: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +355: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +356: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +357: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +358: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +359: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +360: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +361: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +362: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +363: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +364: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +365: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +366: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +367: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +368: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +369: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:16 +370: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +371: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +372: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +373: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +374: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +375: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +376: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:17 +377: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +378: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +379: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +380: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +381: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +382: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +383: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +384: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:18 +385: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:23 +386: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:27 +387: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_backoff_test.dart: AC9: PhotoQueue_MissingLocalFile_SkipsBackoff
00:28 +388: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:35 +389: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:36 +390: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: AC6: NetworkFailure_MarksErrorBlocksBatch - Network crash prevents subsequent uploads
00:41 +391: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: TC-F1-01: AC_429_ReturnsRetryScheduled_NoDelay
00:48 +392: C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/photo_queue_service_test.dart: (tearDownAll)
00:48 +392: All tests passed!
```
</test_trace>

<forensic_evidence>
```text
flutter analyze lib/_shared/services/sync_engine.dart lib/_shared/services/sync_engine_drains.dart lib/_shared/database/dao/outbox_dao.dart
Analyzing 3 items...                                            
No issues found! (ran in 25.6s)

flutter test test/shared/services/sync_engine_backoff_test.dart --reporter=expanded
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/shared/services/sync_engine_backoff_test.dart
00:00 +0: AC4: SyncEngine_FirstFailure_SetsRetryCountOneAndNextRetryAt2s
00:00 +1: AC5: SyncEngine_ThirdFailure_SetsNextRetryAt60s
00:00 +2: AC6: SyncEngine_FourthFailure_SetsStatusExhausted
00:00 +3: AC-409: _drainRisks_409Conflict_TreatedAsSuccess_RecordRemoved
00:00 +4: AC-FATAL: _drainSubmissions_400FatalError_MarkedExhausted_NoRetry
00:00 +5: AC-CHECKPOINT: drainSubmissions_PushSucceeds_WritesCheckpointBeforeDelete
00:00 +6: AC-SWEEP: requestSync_StartupSweep_DeletesOrphanedSyncedSubmissions
00:00 +7: AC-SWEEP-NOPUSH: startupSweep_DoesNotPushAlreadySyncedRows
00:00 +8: All tests passed!
```
</forensic_evidence>

## Gotcha Protocol
- No new product rule was discovered that warrants a `GEMINI.md` change under `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\services` or `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database`.
- Environment-only note: Flutter verification required elevated execution because the SDK writes to `C:\Users\HP\flutter\bin\cache\lockfile` during analyze and test runs.
