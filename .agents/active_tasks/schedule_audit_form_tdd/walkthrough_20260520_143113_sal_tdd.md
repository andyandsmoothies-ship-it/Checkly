# TDD Walkthrough: ScheduleAuditFormLogic

## Input Lineage
- **Source File**: `C:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\widgets\schedule_audit_form_logic.dart`
- **Test File**: `C:\Users\HP\Documents\GitHub\Checkly\test\features\admin\widgets\schedule_audit_form_logic_test.dart`
- **Log File**: `C:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\executed_tests_20260520_143113_sal_tdd.md`

## Flow

```
[schedule_audit_form_logic.dart]
  filterAuditors() -- pure static logic, no deps
  filterStores()   -- pure static logic, no deps
        |
        v
[schedule_audit_form_logic_test.dart]
  filterAuditors group (FA-01 to FA-08)
  filterStores group   (FS-01 to FS-08)
        |
        v
[flutter test] → 16/16 PASS
```

## What Was Tested

### filterAuditors()
| Code | Scenario | Assertion |
|---|---|---|
| FA-01 | `selectedStoreId == null` | All 3 auditors returned |
| FA-02 | area_manager IN store | Included in result |
| FA-03 | area_manager NOT in store | Excluded from result |
| FA-04 | auditor role (non-AM) | Always passes through |
| FA-05 | Empty `allAuditors` | Returns `[]` |
| FA-06 | area_manager, `assignedStoreIds` key missing | Excluded (treated as empty) |
| FA-07 | area_manager, `assignedStoreIds` is `[]` | Excluded |
| FA-08 | Mixed list (auditor + 2 AM) with store-A filter | auditor + AM-A pass, AM-B excluded |

### filterStores()
| Code | Scenario | Assertion |
|---|---|---|
| FS-01 | `selectedAuditorId == null` | All 3 stores returned |
| FS-02 | area_manager auditor | Only their assignedStoreIds returned |
| FS-03 | auditor role | All stores returned |
| FS-04 | Auditor ID not found → `{}` map → null role → admin fallback | All stores returned |
| FS-05 | Empty `allStores` | Returns `[]` |
| FS-06 | area_manager, `assignedStoreIds` key missing | Returns `[]` |
| FS-07 | area_manager, `assignedStoreIds` is `[]` | Returns `[]` |
| FS-08 | area_manager with ghost store IDs (not in allStores) | Returns `[]` |

## Why Tests Pass Immediately (Legacy Code Path)
The production code already existed and was correct — these are **characterization tests**.
Per the TDD skill: *"When you encounter existing code that lacks tests, write Characterization Tests — capture the current behavior as a safety net."*

This is the correct outcome. The tests are NOT testing pre-built stubs.

## Run Command for Builder

```bash
# Run only this test file
flutter test test/features/admin/widgets/schedule_audit_form_logic_test.dart --reporter expanded

# Run full suite to verify no regressions
flutter test
```

## Gotcha: UserPersona.fromRole() Not Raw String
The production code uses `UserPersona.fromRole(role) == UserPersona.areaManager` (fixed in Issue #7).
Test data still passes `'area_manager'` as the `role` string — this is correct because `UserPersona.fromRole('area_manager')` returns `UserPersona.areaManager`.
If `fromRole()` mapping ever changes, FA-02 and FS-02 will immediately catch the regression.
