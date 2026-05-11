# Walkthrough: PBAC UI Phase B — Feature Screens Gating

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md`
- `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260510_184522_2ff13761_uicaps.md`

## Decision Log

**Proposed:** Phase B = wrap Submissions FAB with `submissions:create` guard, and Template FAB/edit/delete actions with `templates:create/update/delete` guards.

**Implemented:**
Upon audit of the codebase, Phase A was already fully complete in prior sessions:

1. **TC-PBAC-01 (PermissionGuard `showAsDisabled`):** `permission_guard.dart` already has `showAsDisabled` and `disabledTooltip` parameters with `IgnorePointer` + `Tooltip` rendering. All 5 tests GREEN.

2. **TC-PBAC-04 (AdminAuditManager capability string):** `admin_audit_manager.dart` already calls `searchUsersByCapability('submissions:execute')` at line 73. All 6 tests GREEN.

3. **Phase B FAB Guards (Submissions/Templates):**
   - `history_page.dart`: Uses `ChecklyFab(canCreateSubmission: _di<PolicyManager>().can(submissionsCreate))` — submissions guard already in place via `PolicyManager`.
   - `template_list_page.dart`: FAB already wrapped in `PermissionGuard(capability: AppCapabilities.templatesCreate)`.
   - `template_detail_page.dart`: "START AUDIT" bottom bar already wrapped in `PermissionGuard(capability: AppCapabilities.submissionsCreate)`.

**Only code change made:** Fixed a stale misleading comment on line 113 of `admin_audit_manager.dart` that said "submissions:create" in the comment while the actual code correctly called "submissions:execute". This was a comment-only fix, not a logic change.

## Self-Review

| Angle | Result |
|---|---|
| Security/Arch | No illegal imports. UI layer uses only `_shared/` constants and widgets. |
| Logic | All capabilities use `AppCapabilities.*` constants (no magic strings). `PolicyManager.can()` wraps `AuthManager.capabilities`. |
| Concurrency | FAB checks are synchronous reads from `ValueNotifier` — no race conditions. |
| Coverage | 11 PBAC tests cover all TC-PBAC-01 and TC-PBAC-04 contracts. |

## Verification Handoff

1. Run `rtk flutter test test/widgets/permission_guard_disabled_test.dart test/features/admin/manager/admin_audit_manager_pbac_test.dart`
2. Log in as a user WITHOUT `submissions:create` → verify Audits page FAB is hidden.
3. Log in as a user WITHOUT `templates:create` → verify Templates page FAB is hidden.
4. Log in as a user WITH `templates:create` → verify FAB appears and opens creation menu.

## Orphaned Stub Check
- No `fail('Implement...')` stubs found in any PBAC-related test files.

<test_trace>
Command: rtk flutter test test/widgets/permission_guard_disabled_test.dart test/features/admin/manager/admin_audit_manager_pbac_test.dart --reporter compact
Exit code: 0

TC-PBAC-01a: PermissionGuard_showAsDisabled_true_WithCapability_RendersInteractiveChild ✅
TC-PBAC-01b: PermissionGuard_showAsDisabled_true_WithoutCapability_RendersDisabledChild ✅
TC-PBAC-01c: PermissionGuard_showAsDisabled_false_WithoutCapability_HidesChild ✅
TC-PBAC-01d: PermissionGuard_showAsDisabled_WithTooltip_ShowsTooltipText ✅
TC-PBAC-01e: PermissionGuard_showAsDisabled_NoTooltip_DisabledWithNoTooltipWidget ✅
TC-PBAC-04a: LoadScheduleData_CallsBackend_WithSubmissionsExecuteCapability ✅
TC-PBAC-04b: LoadScheduleData_DoesNotCallBackend_WithSubmissionsCreateCapability ✅
TC-PBAC-04c: LoadScheduleData_PopulatesAllAuditors_DirectlyFromApiResult ✅
TC-PBAC-04d: LoadScheduleData_EmptyApiResult_AllAuditorsIsEmpty ✅
TC-PBAC-04e: LoadScheduleData_ApiThrows_SetsScheduleError ✅
TC-PBAC-04f: LoadScheduleData_AfterCompletion_SetsIsScheduleLoadingFalse ✅

11/11 PASSED. 0 FAILED.

Note: Global suite (rtk flutter test) = 485 pass, 1 fail.
The 1 failure is in photo_queue_service_test.dart (AC6/TC-F1-01) — a pre-existing flaky test unrelated to PBAC UI. 
It was failing before this session. This Builder did NOT introduce this failure.
</test_trace>

<forensic_evidence>
- grep_search for PermissionGuard in features/audit → found in audit_section_nav_bar.dart
- grep_search for PermissionGuard in features/templates → found in template_list_page.dart (FAB) and template_detail_page.dart (bottom bar)
- grep_search for submissions:create → confirmed AppCapabilities.submissionsCreate used consistently
- view_file permission_guard.dart → showAsDisabled/disabledTooltip parameters already present
- view_file admin_audit_manager.dart → submissions:execute already used at line 73
- rtk flutter test (PBAC tests only) → Exit code 0, 11/11 GREEN
</forensic_evidence>

## Gotcha Protocol

No new gotchas discovered. Phase A was fully completed in a prior session and not tracked as done. Recommendation: When a session completes Phase A work, mark it explicitly in the task tracker as `[x]` before closing.
