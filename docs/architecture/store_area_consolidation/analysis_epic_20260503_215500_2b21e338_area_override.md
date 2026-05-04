<latent_space_scratchpad>
The core architectural insight: the user wants to abandon the `AreaId` foreign key for Area Managers entirely (Pure Direct Assignment) but keep the `Area` table in the database so old data and reports don't break.

Key decisions confirmed by user instruction:

1. `ResourceAccessGuard.IsUserAreaAsync`: currently does `AnyAsync(s => s.Id == storeId && s.AreaId == profile.AreaId)`. We must change this to ONLY check the new junction table: `EXISTS(ProfileStoreAssignment WHERE ProfileId == userId AND StoreId == storeId)`. The `AreaId` check is completely removed for Area Managers.

2. `OwnershipScopeFilter`: currently builds `WHERE s.AreaId == amProfile.AreaId`. New: `WHERE s.Id IN (SELECT StoreId FROM ProfileStoreAssignments WHERE ProfileId == userId)`. 

3. `UpdateUser.cs` (S10 rule): Currently enforces "1 AM per area". Since AMs are no longer assigned to Areas, **S10 must be deleted**. AMs are assigned to specific Stores directly.

4. Flutter Admin UI ("Virtual Area Assignment"): To prevent admins from having to click 500 checkboxes to assign an AM to a district, the UI will still show the "Assign to Area" dropdown. However, when the admin selects "Area 1", the backend will automatically find all 500 stores in Area 1 and silently create 500 `ProfileStoreAssignment` rows. 

5. No new Drift table — override stores will be stored as a comma-separated `assignedStoreIds` text column on the Profile record in Flutter. The Profile sync endpoint will send the FULL list of assigned store IDs for the AM.

6. Data migration: Since we are ignoring `AreaId` for AMs, we MUST migrate existing data. When deploying, a migration must read every AM's current `AreaId`, find all stores in that Area, and insert rows into `ProfileStoreAssignment` so existing AMs don't lose access to their stores.
</latent_space_scratchpad>

# Epic Analysis: Pure Direct Store Assignment (Virtual Areas)

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_214850_synth_store_area_consolidation.md`

## Executive Summary
This epic upgrades the Area Manager (AM) access model from a rigid "1 AM → 1 Area" hierarchy to a fully flexible **Pure Direct Assignment** model, while preserving the legacy `Area` table purely for historical reporting.

- **Direct Connection:** The system completely stops checking `Profile.AreaId` to determine what stores an AM can access. Instead, it relies 100% on a new `ProfileStoreAssignment` junction table.
- **Rule Deletion:** The S10 rule ("Only 1 AM per Area") is deleted. Multiple AMs can now be assigned to the same stores.
- **Virtual Area Assignment (UX Magic):** To prevent Admins from manually checking hundreds of boxes, the Admin UI still provides an "Assign to Area" button. The backend intercepts this and automatically translates it into hundreds of direct store assignments.
- **Flutter Sync:** Assigned store IDs are flattened into an `assignedStoreIds` text array on the Profile sync payload. No new Drift table is needed.

**Business impact:** Total flexibility. AMs can be assigned to 1 store, 500 stores, or stores across 3 different districts, with zero structural limitations.

---

## Decision Matrix (Fit Check)

| Requirement | Option 3.5 (Base+Override) | Option 3 (Pure Direct with Legacy Area) |
|---|:---:|:---:|
| AM can cover stores from a different district | ✅ | ✅ |
| Area-based historical reporting preserved | ✅ | ✅ |
| Simplest Backend Logic (No `OR` statements) | ❌ | ✅ |
| S10 Rule completely eliminated | ❌ | ✅ |
| Zero reliance on AreaId for security | ❌ | ✅ |

**Winner: Option 3 (Pure Direct with Legacy Area)**

---

## Risk Assessment

| Risk | Severity | Mitigation |
|---|---|---|
| Data Loss on Deployment | 🔴 HIGH | A data migration MUST run to convert all existing AM `AreaId` links into `ProfileStoreAssignment` rows before the new code goes live. |
| DB load on large `IN` clauses | 🟡 MEDIUM | `OwnershipScopeFilter` will use a subquery `WHERE s.Id IN (SELECT StoreId FROM ProfileStoreAssignment)`. With proper indexing, this is performant for < 10,000 stores per AM. |
| Flutter sync payload size | 🟡 MEDIUM | If an AM has 1,000 stores, sending 1,000 GUIDs takes ~36KB. This is perfectly acceptable for the background sync payload. |
| Syncing without a Drift table | 🟢 LOW | The store IDs will be serialized as a comma-separated string in the local `CachedProfile` table to avoid complex SQLite schema migrations. |

> [!CAUTION]
> **[BLAST_RADIUS]:** This change rewrites the core security perimeter (`ResourceAccessGuard.cs`, `OwnershipScopeFilter.cs`). If the data migration fails, AMs will log in and see 0 stores.

---

## Visual & Functional Context

### Admin Screens Affected
| Screen | Current Behavior | New Behavior |
|---|---|---|
| `user_edit_sheet.dart` | Area picker (assigns AreaId) | "Virtual Area" picker + Specific Store picker. |
| `schedule_audit_form.dart` | Filters AMs by `areaId == store.areaId` | Filters AMs by checking if their Profile contains the store ID. |

### Backend Endpoints Affected
| Endpoint | Change |
|---|---|
| `PUT /api/admin/users/{id}` (UpdateUser) | Deletes S10 rule. Intercepts `AreaId` requests and converts them into batch inserts into `ProfileStoreAssignment`. |
| `GET /api/stores` (ListStores) | AM scope: completely drops `AreaId` filter, relies only on `ProfileStoreAssignment` subquery. |
| `GET /api/sync/profile` | Profile DTO adds `assignedStoreIds: Guid[]`. |
| `ResourceAccessGuard.IsUserAreaAsync` | Drops `AreaId` check. Uses `AnyAsync` on junction table. |

---

## System Context

- **Auth:** The security perimeter strictly queries the junction table. The `AreaId` property on the AM's profile is dead logic.
- **Offline-First:** Flutter app receives an array of `assignedStoreIds` and saves them directly to the `CachedProfile` SQLite row as a serialized string.
- **RBAC:** S10 rule is fully deleted from the codebase.

---

## Data Context

### New Entity: `ProfileStoreAssignment`
```
ProfileId  (Guid, FK → Profiles.Id, NOT NULL)
StoreId    (Guid, FK → Stores.Id, NOT NULL)
CreatedAt  (DateTimeOffset, NOT NULL)
PRIMARY KEY (ProfileId, StoreId)  — composite clustered index
```

### Migration Strategy (CRITICAL)
1. Add `ProfileStoreAssignment` entity.
2. Create EF Core Migration:
   - Create Table.
   - **Data Seed:** Write a raw SQL `Sql("INSERT INTO ProfileStoreAssignments (ProfileId, StoreId, CreatedAt) SELECT p.Id, s.Id, GETUTCDATE() FROM Profiles p JOIN AppUserRoles r ON p.Id = r.UserId JOIN Stores s ON p.AreaId = s.AreaId WHERE r.Role = 'area_manager' AND p.AreaId IS NOT NULL");`

---

## Architecture Flow

```
[Admin clicks "Assign to Area 1"]
    → PUT /api/admin/users/{id} { virtualAreaId: "Area1" }
    → Backend finds 500 stores in Area 1
    → Backend creates 500 rows in ProfileStoreAssignment

[Admin adds specific extra store]
    → PUT /api/admin/users/{id} { assignedStoreIds: ["StoreX"] }
    → Backend upserts StoreX into ProfileStoreAssignment

[AM checks access to a store]
    → ResourceAccessGuard.IsUserAreaAsync
    → Check: EXISTS ProfileStoreAssignment (ProfileId=userId, StoreId=storeId)
    → True/False

[AM syncs profile]
    → GET /api/sync/profile
    → Response: { ...profile, assignedStoreIds: ["Store1", "Store2", ...] }
    → Flutter saves array as string in local DB
```

---

## Testing Expectations

| Test Class | New Test Cases Required |
|---|---|
| `SubmissionAccessGuardUnitTests.cs` | Validate AM access is granted strictly based on `ProfileStoreAssignment`. Tests using `AreaId` should be removed or updated. |
| `AreaEndpointMigrationTests.cs` | Validate `ListStores` relies on junction table. |
| `UpdateUser` | Verify that submitting `virtualAreaId` creates the correct number of junction rows, and S10 rule logic is removed. |

<forensic_evidence>
- grep_search "AreaId" server → 346+ results across SubmissionAccessGuardUnitTests, AreaMigrationTests, AreaEndpointMigrationTests, SyncSubmissionsEndpointTests, SubmissionDelegationAuthTests, ListActionPlansTests, OverdueEscalationTests
- grep_search "ResourceAccessGuard" server → 12 call-sites in Submissions (Review, Sync, Get, Finalize, Create), Photos (Upload, Get), GlobalRisks, ActionPlans
- view_file server/Common/Auth/OwnershipScopeFilter.cs → Confirmed area_manager uses WHERE s.AreaId == amProfile.AreaId (line 59)
- view_file server/Common/ResourceAccessGuard.cs → Confirmed IsUserAreaAsync uses single AnyAsync (line 51-52). CanDelegateAsync also calls IsUserAreaAsync (line 85)
- view_file server/Features/Admin/UpdateUser.cs → S10 rule enforced at line 84-109 via RoleAssignmentGuard.FindExistingAreaManager
- view_file server/Features/Stores/ListStores.cs → Area scoping at line 85-86: WHERE s.AreaId == profile.AreaId.Value
- grep_search "area" lib/features/admin → user_edit_sheet.dart (lines 6,14,31,43,57,70,172,173,187-190,223-243,260), user_create_sheet.dart (lines 17,33,39,55,126,271,272,286-289,320-339), schedule_audit_form.dart (lines 89,94,96,98,108,113,115,117,120,261)
- grep_search "areaId" lib → tables.dart line 71 (Drift column definition), store_dao.dart lines 39,53, app_database.g.dart (auto-generated, 50+ references)
- list_dir server/Features/Admin → UpdateUser.cs, CreateUser.cs, BanUser.cs, ListUsers.cs, TransferStoreManager.cs confirmed
- list_dir server/Features/Stores → CreateStore, DeleteStore, GetStore, GetStoreDashboard, ListStores, UpdateStore confirmed
- list_dir server/Common/Auth → OwnershipScopeFilter.cs, ResourceAccessGuard.cs (in Common/), RoleAssignmentGuard.cs confirmed
</forensic_evidence>

---

## Handoff Block

**Final Epic:** Pure Direct AM Store Assignment (Virtual Areas)
**Plan File:** `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md`

---

### Slices

**Slice 1: DB Foundation & Data Migration** `[BLOCKING]`
- **Plain English:** Build the new junction table and migrate all existing Area Managers to use it automatically.
- **Value Delivered:** Database supports direct assignment without losing existing user access.
- **Entry State Required:** `AppDbContext` compiles.
- **Exit State Guaranteed:** `ProfileStoreAssignment` table exists. Raw SQL migration successfully seeds data based on old `AreaId` links.
- **Architectural Scope:** `server/Common/Persistence/Entities/ProfileStoreAssignment.cs` [NEW], `server/Common/Persistence/AppDbContext.cs` [MOD], EF Core migration with `.Sql()` command [NEW].
- **Acceptance Criteria:**
  - Table `ProfileStoreAssignments` has composite PK `(ProfileId, StoreId)`.
  - Migration includes SQL to copy existing AM-to-Area links into direct store assignments.

---

**Slice 2: Auth Guard Rewrite** `[SEQUENTIAL after Slice 1]`
- **Plain English:** Change the security gates so they completely ignore `AreaId` and only look at the new junction table.
- **Value Delivered:** Security model shifted to Direct Assignment.
- **Exit State Guaranteed:** `ResourceAccessGuard` and `OwnershipScopeFilter` use subqueries against `ProfileStoreAssignments`. `ListStores` uses the subquery.
- **Architectural Scope:** `server/Common/ResourceAccessGuard.cs` [MOD], `server/Common/Auth/OwnershipScopeFilter.cs` [MOD], `server/Features/Stores/ListStores.cs` [MOD].
- **Acceptance Criteria:**
  - `IsUserAreaAsync` checks `EXISTS(ProfileStoreAssignment)`.
  - `OwnershipScopeFilter` uses `WHERE s.Id IN (SELECT StoreId...)`.

---

**Slice 3: Admin API — Virtual Area Assignment & S10 Deletion** `[SEQUENTIAL after Slice 2]`
- **Plain English:** Delete the "1 AM per Area" rule. Update the Admin API so assigning an AM to an Area automatically assigns them to all stores in that Area instead.
- **Value Delivered:** Admin API supports flexible assignment.
- **Exit State Guaranteed:** `UpdateUser.cs` deletes S10 rule. Accepts `virtualAreaId` or `assignedStoreIds` arrays.
- **Architectural Scope:** `server/Features/Admin/UpdateUser.cs` [MOD], `server/Features/Admin/Dtos.cs` [MOD].
- **Acceptance Criteria:**
  - Sending `virtualAreaId=X` causes the backend to query all stores in `X` and insert them into the junction table.
  - S10 rule logic deleted.

---

**Slice 4: Profile Sync — Flatten Payload** `[SEQUENTIAL after Slice 3]`
- **Plain English:** Send the massive list of assigned stores to the Flutter app during login/sync so offline mode works.
- **Value Delivered:** Flutter app receives direct store assignments.
- **Exit State Guaranteed:** Profile sync endpoint returns `assignedStoreIds`. Flutter stores it as a serialized string.
- **Architectural Scope:** Profile sync endpoint DTO [MOD]. Flutter: `lib/_shared/database/tables.dart` [MOD], `lib/_shared/database/dao/store_dao.dart` [MOD].
- **Acceptance Criteria:**
  - `CachedProfiles` gets nullable `assignedStoreOverrides` text column.
  - Flutter `store_dao.dart` looks up stores using this string.

---

**Slice 5: Admin UI — Virtual Area Picker** `[PARALLEL with Slice 4]`
- **Plain English:** Update the Admin UI to clearly communicate that Areas are just a shortcut to select multiple stores.
- **Value Delivered:** Admins can manage direct assignments cleanly.
- **Exit State Guaranteed:** `user_edit_sheet` sends `virtualAreaId` or specific store arrays.
- **Architectural Scope:** `lib/features/admin/widgets/user_edit_sheet.dart` [MOD], `lib/features/admin/widgets/schedule_audit_form.dart` [MOD].
- **Acceptance Criteria:**
  - `schedule_audit_form` checks if the AM's store list contains the selected store.

---

### Slice Execution Order
```
Slice 1 (DB Foundation & Migration) [BLOCKING]
    └── Slice 2 (Auth Guards)       [SEQUENTIAL]
        └── Slice 3 (API)           [SEQUENTIAL]
            ├── Slice 4 (Sync)      [SEQUENTIAL]
            └── Slice 5 (UI)        [PARALLEL]
```

### Next Steps
The Epic is complete. Awaiting user approval to begin **Slice 1 (DB Foundation & Data Migration)**.

