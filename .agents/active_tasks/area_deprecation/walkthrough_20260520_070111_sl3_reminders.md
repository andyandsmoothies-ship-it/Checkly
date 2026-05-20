# Walkthrough: SL-3 ReminderService ProfileStoreAssignment Cutover
- **Date**: 2026-05-20
- **Authors**: Antigravity
- **Target Implementation Plan**: `docs\architecture\implementation_plan_20260520_070000_a8c2d9f4_sl3_reminders.md`

## Overview
This walkthrough outlines the successful migration of overdue action plan notifications within the `ReminderService` backend background worker. Previously, overdue alerts mapped to legacy Area levels (`Profile.AreaId` and `Store.AreaId`). We have successfully transitioned the query logic to resolve direct assignments via the new `ProfileStoreAssignment` junction table, supporting multiple granular manager-to-store mappings.

## Technical Walkthrough

### 1. Database Integration (`ReminderService.cs`)
We refactored `SendOverdueEscalations` to fetch Area Managers dynamically from `ProfileStoreAssignments` and `AppUserRoles` using an optimized join.
```csharp
var assignments = await db.ProfileStoreAssignments
    .Where(x => storeIds.Contains(x.StoreId))
    .Join(db.UserRoles.Where(ur => ur.Role.Name == "area_manager"),
        assignment => assignment.ProfileId,
        userRole => userRole.UserId,
        (assignment, userRole) => new { assignment.StoreId, assignment.ProfileId })
    .ToListAsync(cancellationToken);
```
- **N+1 Prevention**: We perform exactly 1 database query to fetch all assignments matching the collection of overdue `storeIds`.
- **Granular Routing**: If an action plan is overdue, we resolve its store's assigned managers, check if they already received an escalation notification (ensuring idempotency), and write new notifications if missing.

### 2. Integration Tests Migration (`OverdueEscalationTests.cs`)
We updated all integration tests to seed `ProfileStoreAssignment` records instead of the deprecated `AreaId` properties:
- `SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager`
- `SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate`
- `SendOverdueEscalations_NoAreaManager_SkipsAP`
- `SendOverdueEscalations_ClosedPlan_SkipsAP`
- `SendOverdueEscalations_MultipleStores_SendsToRespectiveManagers` (Complies with DB uniqueness checks by using separate stores).

## Verification Results
- All integration tests are green.
- Compilation is completely warning-free.
- Validated via `dotnet test` showing 5 passed tests under `OverdueEscalationTests`.
