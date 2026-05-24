# /
Workflow: /analyze-feature | Track: B2

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260505_162000_b7c2d9f1_am_store_synthesis.md`

## Executive Summary & Out of Scope
Implement Option B from the ADR: Enforce a strict 1-to-Many relationship between Area Managers and Stores (a store can have at most one AM). 
- Add a unique index on `profile_store_assignments.store_id`.
- Add a backend guard (`FindExistingAreaManagerForStore`) and 409 Conflict flow for transfers.
- Update UI to default to vacant stores, with a transfer path (confirm dialog).

**Out of Scope**: 
- Modifying the Store Manager (SM) assignment rules.
- Modifying the Admin dashboard or other disconnected modules.

## System Context
- **APIs**: `POST /api/admin/users`, `PUT /api/admin/users/{id}`, `GET /api/stores`
- **RBAC**: Requires `UsersManage` capability (Admin role).
- **Data Integrity**: Database unique index prevents silent overrides or race conditions.

## Lifecycle Context
- **Success**: Unique index ensures data integrity. 409 Conflict cleanly prompts the UI for transfer confirmation.
- **Error**: 400 Bad Request if stores don't exist; 409 Conflict if store is already assigned to another AM (without `forceReassign`).
- **Loading**: UI shows a spinner while checking assignments and loading stores.
- **Empty**: If no vacant stores exist, the UI shows "No active stores found."

## Test Contracts

| ID | Test Scenario | Matrix State | Expected Failure / Rule |
|---|---|---|---|
| TC1 | EF Core Unique Index | DB Layer | Assigning 2 AMs to the same store without removing the first throws `DbUpdateException`. |
| TC2 | Create AM - Vacant | Success | 201 Created. `ProfileStoreAssignment` created. |
| TC3 | Create AM - Taken | Error | 409 Conflict returned with `existingManagerId`. |
| TC4 | Update AM - Taken | Error | 409 Conflict returned with `existingManagerName`. |
| TC5 | Update AM - Force | Success | 200 OK. Previous AM's assignment deleted, new assignment created, SystemLog recorded. |
| TC6 | ListStores Filter | Success | `assignable_as=area_manager` excludes stores that already have an AM. |

## Test Fixture & Payloads
**Setup**: Admin client, 2 active Stores, 1 existing Area Manager assigned to Store 1.
**Request**: `PUT /api/admin/users/{new_am_id}`
```json
{
  "role": "area_manager",
  "assignedStoreIds": ["<store_1_id>"],
  "forceReassign": false
}
```
**Response (409 Conflict)**:
```json
{
  "error": "Store already has an area manager assigned",
  "existingManagerId": "<existing_am_id>",
  "existingManagerName": "John Doe",
  "storeName": "Store 1"
}
```

## Tools & Commands
- **EF Core Migration**: `cmd /c "rtk dotnet ef migrations add EnforceUniqueAMStore -p Common/Common.csproj -s Api/Api.csproj"`
- **Backend Tests**: `cmd /c "rtk dotnet test tests/Checkly.Api.Tests"`
- **Frontend Analysis**: `cmd /c "rtk flutter analyze"`

## Proposed Changes
- `[MOD]` `server/Common/Persistence/Configurations/ProfileStoreAssignmentConfiguration.cs`: Add `HasIndex(x => x.StoreId).IsUnique()`.
- `[NEW]` `server/Common/Persistence/Migrations/...`: Generate EF Core migration.
- `[MOD]` `server/Common/Auth/RoleAssignmentGuard.cs`: Add `FindExistingAreaManagerForStore`.
- `[MOD]` `server/Features/Admin/CreateUser.cs` & `UpdateUser.cs`: Add 409 Conflict and `ForceReassign` logic for AMs.
- `[MOD]` `server/Features/Stores/ListStores.cs`: Support `assignableAs=area_manager`.
- `[MOD]` `lib/features/admin/widgets/user_create_sheet.dart` & `user_edit_sheet.dart`: Add "Show assigned stores" toggle. Handle 409 Conflict for AM transfers using existing dialog logic.

## Concept Diagram
`[Admin UX]` --(Checks store)--> `[ListStores?assignableAs=area_manager]` 
`[Admin UX]` --(Toggle "Show Assigned")--> `[ListStores]`
`[Admin UX]` --(Selects Taken Store)--> `[PUT /users/{id}]` --> `[409 Conflict]`
`[Admin UX]` --(Confirms Transfer)--> `[PUT /users/{id} forceReassign=true]` --> `[DB Transaction + Log]`

## Execution Slices

### Phase 1: Database & Backend Guards (Data Integrity)
- **Complexity**: High
- **Reason**: Modifies EF Core schema and adds complex 409 transaction logic in `UpdateUser.cs` and `CreateUser.cs`.
- **Pros & Cons**: 
  - *Pro*: Guarantees data integrity at the database level.
  - *Con*: Requires a database migration.

### Phase 2: UI Implementation (Admin Screens)
- **Complexity**: Medium
- **Reason**: Requires adding a toggle switch to the sheets and updating the dropdown/checkbox logic to handle the new AM transfer payload.
- **Pros & Cons**: 
  - *Pro*: Seamless UX reusing the existing `TransferConflictException` flow.

## Risk Assessment
- **Risk Level**: Medium
- **Impact**: Database schema migration adds an invariant that could block existing duplicate data if any slipped through. Backend guard enforces a strict state.
- **Mitigation**: EF Core migration ensures existing DB states are verified. If duplicates exist in the dev DB, the migration will fail, prompting manual cleanup.

## Verification Plan
1. Apply the database migration and verify that assigning two AMs to the same store manually via SQL throws a unique constraint error.
2. Run backend integration tests to assert 409 Conflict is returned when attempting to overwrite an AM without `forceReassign`.
3. In the UI, verify the toggle successfully loads assigned stores, warns on conflict, and processes the transfer successfully on confirmation.

## Handoff Block
> **Route 3: Network/Auth/DB (Acceptance Tests First)**
> @[/atdd] Execute specs for Phase 1: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260505_165000_am_store_strict_1_to_m.md
