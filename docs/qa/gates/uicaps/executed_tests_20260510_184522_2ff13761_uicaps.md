# Executed Tests — Phase A PBAC UI Gating (RED Phase)

## Input Lineage
**Source Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\uicaps\implementation_plan_20260510_180034_uicaps.md`

## Test Files Created

```
test/widgets/permission_guard_disabled_test.dart         ← TC-PBAC-01 (5 tests)
test/features/admin/manager/admin_audit_manager_pbac_test.dart  ← TC-PBAC-04 (6 tests)
```

## Failure Evidence (Confirmed RED Phase)

```
00:01 +0 -1: loading permission_guard_disabled_test.dart [E]
  Compilation failed: No named parameter with the name 'showAsDisabled'.
  ^^^^^^^^^^^^^^
  lib/_shared/widgets/permission_guard.dart:25:9: Context: Found this candidate, but the arguments don't match.

00:03 +0 -2: TC-PBAC-04a [E]
  No matching calls. All calls: MockAdminApiService.searchUsersByCapability(submissions:create)

00:03 +0 -3: TC-PBAC-04b [E]
  Unexpected calls: MockAdminApiService.searchUsersByCapability(submissions:create)

00:03 +0 -4: TC-PBAC-04c [E]
  Expected: not null
    Actual: <null>   [scheduleData is null because wrong capability stub threw]

00:03 +0 -5: TC-PBAC-04d [E]
  Expected: not null
    Actual: <null>   [same root cause as TC-PBAC-04c]

+2 -5: Some tests failed.
```

## Failure Classification

| Test | Failure Reason | Classification |
|---|---|---|
| `permission_guard_disabled_test.dart` (all 5) | Compile error: `showAsDisabled` param missing from `PermissionGuard` | ✅ GOOD — feature missing |
| `TC-PBAC-04a` | `searchUsersByCapability` called with `submissions:create` not `submissions:execute` | ✅ GOOD — wrong capability string |
| `TC-PBAC-04b` | `searchUsersByCapability('submissions:create')` called — verifyNever() fires | ✅ GOOD — wrong capability string |
| `TC-PBAC-04c` | `scheduleData` is null because the stub for wrong capability was not set up | ✅ GOOD — root cause is wrong capability |
| `TC-PBAC-04d` | Same as TC-PBAC-04c | ✅ GOOD — same root cause |
| `TC-PBAC-04e` | ✅ PASSES — error path works correctly | N/A |
| `TC-PBAC-04f` | ✅ PASSES — loading flag cleared in `finally` block | N/A |

## Summary
- **5 tests fail for TC-PBAC-01**: `PermissionGuard` has no `showAsDisabled` or `disabledTooltip` parameter. The Builder must add these parameters and render an `IgnorePointer` + optional `Tooltip` when `showAsDisabled=true` and capability is absent.
- **4 tests fail for TC-PBAC-04**: `AdminAuditManager.loadScheduleData()` at line 73 calls `searchUsersByCapability('submissions:create')`. The Builder must change this to `searchUsersByCapability('submissions:execute')`.
- **2 tests pass** for TC-PBAC-04 (error & loading state) — the builder must NOT break them.
