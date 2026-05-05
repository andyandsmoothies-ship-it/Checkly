# Test Contracts: Enforce Strict 1-to-Many Area Manager to Store Assignment

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260505_165000_am_store_strict_1_to_m.md`

## Smoke Gate Report

| Test Name | Status | Type | Error Summary |
|-----------|--------|------|---------------|
| TC1_DbLayer_UniqueIndex_ThrowsOnDuplicateStoreAssignment | RED | ✅ Business | Expected DbUpdateException but no exception was thrown (index missing) |
| TC2_CreateAM_VacantStore_ReturnsCreated | GREEN | ✅ Business | Happy path naturally passes as baseline |
| TC3_CreateAM_TakenStore_ReturnsConflict | RED | ✅ Business | Expected 409 Conflict but got 201 Created (guard missing) |
| TC4_UpdateAM_TakenStore_ReturnsConflict | RED | ✅ Business | Expected 409 Conflict but got 200 OK (guard missing) |
| TC5_UpdateAM_TakenStore_ForceReassign_ReturnsOk | GREEN | ✅ Business | Happy path passes (acts as normal assignment without the guard) |
| Gap1_UpdateNonAMRole_WithForceReassign_DoesNotConflict | GREEN | ✅ Business | Happy path passes (ensure new logic doesn't break SMs) |
| Gap2_BulkAssignment_AtomicFailure | RED | ✅ Business | Expected 409 Conflict but got 201 Created |

### Verdict
- ✅ All failures are `Business` (RED for the right reason). The tests successfully assert the absence of the unique constraint and the 409 conflict guards. Proceeding to handoff.

---

## Test Cases (Gherkin)

### TC1: Database Unique Index
**Given** an Area Manager is assigned to Store 1
**When** a second Area Manager is assigned to Store 1 via the database directly
**Then** the database throws a `DbUpdateException` due to a unique constraint violation on `store_id`

### TC2: Create Area Manager (Vacant Store)
**Given** Store 1 has no assigned Area Manager
**When** the Admin creates a new Area Manager and assigns them to Store 1
**Then** the API returns 201 Created and the assignment is successful

### TC3: Create Area Manager (Taken Store)
**Given** Area Manager A is assigned to Store 1
**When** the Admin creates Area Manager B and assigns them to Store 1
**Then** the API returns 409 Conflict with `existingManagerId` and an error message

### TC4: Update Area Manager (Taken Store)
**Given** Area Manager A is assigned to Store 1
**And** Area Manager B exists but is not assigned to Store 1
**When** the Admin updates Area Manager B to be assigned to Store 1
**Then** the API returns 409 Conflict with `existingManagerName`

### TC5: Update Area Manager with Force Reassign
**Given** Area Manager A is assigned to Store 1
**When** the Admin updates Area Manager B to be assigned to Store 1 with `forceReassign=true`
**Then** the API returns 200 OK and Area Manager A is unassigned from Store 1

### Gap 1: Update Non-AM Role (Ignore Force Reassign)
**Given** Store Manager A is assigned to Store 1
**When** the Admin assigns Store Manager B to Store 1 with `forceReassign=true`
**Then** the API returns 200 OK without removing Store Manager A (as 1-to-M only applies to AMs)

### Gap 2: Bulk Assignment Atomic Failure
**Given** Store 1 is vacant and Store 2 is assigned to Area Manager A
**When** the Admin creates Area Manager B and assigns them to Store 1 AND Store 2
**Then** the API returns 409 Conflict
**And** Area Manager B is NOT created
**And** Store 1 remains vacant

---

## Test Infrastructure Map

### Helper Methods
| Method | Signature | Behavior |
|--------|-----------|----------|
| `LoginBootstrapAdminAsync` | `(HttpClient)` | Logs in as seed admin, returns JWT token |
| `CreateAuthenticatedClient` | `(adminToken)` | Returns HttpClient with Bearer token for given role |
| `RegisterUserAsync` | `(HttpClient, email, pass, name, role, adminToken)` | Creates a user via POST /api/auth/register using admin token |
| `CreateStoreAsync` | `(string name)` | Custom test method using `IServiceScope` to create a `Store` directly in the database |

### Auth Tokens
| Role | How to Get | Permissions |
|------|-----------|-------------|
| Admin | `LoginBootstrapAdminAsync()` | Full CRUD on all entities |

### Expected Response Shapes
```json
// POST /api/admin/users & PUT /api/admin/users/{id} (Conflict) → 409 Conflict
{
  "error": "Store already has an area manager assigned",
  "existingManagerId": "<guid>",
  "existingManagerName": "John Doe",
  "storeName": "Store 1"
}
```

### Known Limitations
- None. Database is wiped via `EnsureDatabaseCreated()` per test class context using `checkly_test`.
