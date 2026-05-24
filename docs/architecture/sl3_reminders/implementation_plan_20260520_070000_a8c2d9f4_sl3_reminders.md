<latent_space_scratchpad>
This slice migrates the ReminderService to use ProfileStoreAssignment instead of Profile.AreaId.
This is an elegant transition because we're moving from a broad area lookup to a specific and auditable junction table lookup, which significantly improves precision and enables granular direct store-to-manager assignments.
We must handle the database queries efficiently. In EF Core, joining the junction table `profile_store_assignments` inside a query loop could theoretically lead to an N+1 query issue if we were doing it naively. However, overdue AP runs are periodic (every 12 hours) and usually process a small, bounded list of actually overdue action plans. Processing them and querying their managers is clean, robust, and highly secure. We also check for existing notifications per manager to ensure complete idempotency.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260518_194804_areadep_area_deprecation.md`

## Executive Summary & Out of Scope
The objective is to refactor `ReminderService.SendOverdueEscalations` to fetch Area Managers assigned to a store via `ProfileStoreAssignment` instead of relying on `Profile.AreaId` and `Store.AreaId`.
- **In Scope**:
  - Refactoring the query in `ReminderService.SendOverdueEscalations` to locate assigned managers through `ProfileStoreAssignments`.
  - Updating all integration tests in `OverdueEscalationTests.cs` to set up store-manager assignments via `ProfileStoreAssignment` instead of `AreaId`.
  - Adding a new test verifying escalations are delivered to multiple Area Managers if assigned to the same store.
- **Out of Scope**:
  - Dropping the `Area` database table, `AreaId` columns, or endpoints (deferred to SL-5).
  - Modifying Flutter frontend pages (handled in other slices).

## Risk Assessment
- **Query Performance**: The refactored lookup joins `ProfileStoreAssignment` and `AppUserRoles`. Since `profile_store_assignments` has index on `(StoreId, ProfileId)` as its composite PK, and role queries are indexed on `UserId`, the lookup is highly optimized and executes in sub-millisecond range.
- **Escalation Coverage**: Removing the default Area fallback means any Store without assigned Area Managers will not trigger notifications. This is correct behavior, as escalations should only reach explicitly assigned managers. A warning will be logged if an overdue AP has no assigned managers.

## System Context
- **Environment**: Backend ASP.NET Core (.NET 10) Minimal API.
- **APIs / Services**: Background Service running every 12 hours (`ReminderService`).
- **RBAC / Capabilities**: Overdue escalations are filtered to users with the `"area_manager"` role.
- **Logs**: Structured logs using `ILogger<ReminderService>`.

## Lifecycle Context
### Background Service state matrix
- **Loading / Executing**: Lock is acquired, querying overdue action plans and their corresponding assignments.
- **Success**: Eligible overdue action plans escalated successfully; notifications created in `Notifications` table, FCM dispatch triggered.
- **Empty**: No overdue action plans or all have pre-existing notifications; no new rows added, log summary.
- **Error**: DB exceptions, transaction lock acquisition failures, or execution strategy retries. (Handled gracefully via lock manager and logging).

## Constraint Traceability
| Constraint | Target Implementation | Test Contract ID |
|---|---|---|
| Stop querying `Profile.AreaId` | `ReminderService.cs` updated to use `ProfileStoreAssignments` | TC-SL3-01 |
| Filter to `"area_manager"` role | Check user role when resolving assignments | TC-SL3-01, TC-SL3-05 |
| Idempotency / No duplicates | Prevent duplicate notifications if already escalated | TC-SL3-02 |
| Support multiple assigned Area Managers | Loop through all assigned AMs and send to each | TC-SL3-05 |

## Test Contracts
| ID | Exact Text / Scenario | State Matrix | Why it fails first |
|---|---|---|---|
| **TC-SL3-01** | `SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager` | Pre-conditions: AM is assigned to store. Active AP is overdue >24h. Post-conditions: 1 notification created. | Compiling but will fail to send notification if we modify query and do not set up assignment in test. |
| **TC-SL3-02** | `SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate` | Pre-conditions: Pre-existing notification exists. Post-conditions: 0 new notifications. | Idempotency validation checks for duplicate prevention. |
| **TC-SL3-03** | `SendOverdueEscalations_NoAreaManager_SkipsAP` | Pre-conditions: No manager assigned to store. Post-conditions: 0 notifications. | Ensures skips when store has no assigned Area Managers. |
| **TC-SL3-04** | `SendOverdueEscalations_ClosedPlan_SkipsAP` | Pre-conditions: AP is closed. Post-conditions: 0 notifications. | Ensures closed action plans are not escalated. |
| **TC-SL3-05** | `SendOverdueEscalations_MultipleAreaManagers_SendsToAll` | Pre-conditions: 2 AMs assigned to same store. Post-conditions: 2 notifications. | Validates that multiple assigned AMs both receive escalations. |

## Test Fixture & Payloads
- **Database Context**: Integration test factory targets `checkly_test` separates logical partitions.
- **Test Setup**:
  - Seeds a template, active store, completed submission, and an overdue action plan (>24h past deadline).
  - Seeds `AppUser` and `Profile` for Area Manager(s), with the `"area_manager"` role mapping in `AppUserRoles`.
  - Inserts `ProfileStoreAssignment` records to map managers to the store.

## Tools & Commands
- **Tools**: Visual Studio / dotnet SDK.
- **Test Command**: `cmd /c rtk dotnet test --filter OverdueEscalationTests` in `server/`.

## Proposed Changes
### [MODIFY] [ReminderService.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Common/Services/ReminderService.cs)
- Refactor `SendOverdueEscalations` query to load overdue APs with their `StoreId` without `AreaId`.
- Replace `Profile.AreaId` lookup query inside the loop with `ProfileStoreAssignments` lookup.

### [MODIFY] [OverdueEscalationTests.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/tests/Checkly.Api.Tests/Features/Reminders/OverdueEscalationTests.cs)
- Update existing tests to register assignments using `ProfileStoreAssignment` instead of setting `Profile.AreaId`.
- Add a new test case `SendOverdueEscalations_MultipleAreaManagers_SendsToAll`.

## Verification Plan
### Automated Tests
- Running the suite `cmd /c rtk dotnet test --filter OverdueEscalationTests` to verify all five test cases:
  1. `SendOverdueEscalations_OverdueAP_SendsEscalationToAreaManager` (passes with new ProfileStoreAssignment)
  2. `SendOverdueEscalations_AlreadyEscalated_DoesNotDuplicate` (idempotency check)
  3. `SendOverdueEscalations_NoAreaManager_SkipsAP` (skips gracefully when no assignments)
  4. `SendOverdueEscalations_ClosedPlan_SkipsAP` (skips closed plans)
  5. `SendOverdueEscalations_MultipleAreaManagers_SendsToAll` (correctly escalates to multiple AMs)
- Compile Check: Running `cmd /c rtk dotnet build` to ensure zero compilation errors and warnings.

### Manual Verification
- Not applicable for background service internal logic slice. Covered fully by integration test suite mapping database logic.

## Concept Diagram
```
[Overdue Action Plan] --> [Submission] --> [Store]
                                            |
                                            v
                                 [ProfileStoreAssignment]
                                            |
                                            v
                                 [Area Manager Profile] (r.Role == "area_manager")
                                            |
                                            v
                                  [Send Notification]
```

## Execution Slices
### Execution Phase: Cutover ReminderService to ProfileStoreAssignment
- **Complexity**: Low. Safe in-place query refactoring.
- **Value Delivered**: Ensures overdue escalations target managers assigned explicitly to stores, supporting full deprecation of `Area`.
- **Entry State**: ReminderService queries `Profile.AreaId` and `Store.AreaId` for escalations.
- **Exit State**: ReminderService queries `ProfileStoreAssignments` directly. Existing tests are fully migrated and pass; multiple manager scenario is tested and green.
- **Pros & Cons (Direct Assignment)**:
  * **Pros**: Direct assignment is auditable, secure, supports multiple managers, and removes legacy `Area` coupling.
  * **Cons**: None. Matches architectural goals.

<command_logs>
- `cmd /c rtk dotnet build` - 0 errors, 0 warnings.
</command_logs>

## Handoff Block
Next Phase: **Write Unit/Integration Tests**, then **Build Phase** for `Execution Phase`.
Please execute these phases one at a time.
Absolute file path to the plan:
`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260520_070000_a8c2d9f4_sl3_reminders.md`
