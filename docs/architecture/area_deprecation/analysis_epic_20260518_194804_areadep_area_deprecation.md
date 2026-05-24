<latent_space_scratchpad>
This epic is a full-stack demolition and reconstruction. The Area grouping mechanism is deeply embedded in DB schema, PBAC (ResourceAccessGuard), notification escalations (ReminderService), and Analytics (GetAreaLeaderboard).
The chosen path is Option A with OwnedEntities.
Slicing must be perfectly ordered. We cannot drop Area until Analytics and ReminderService are rebuilt. We cannot rebuild Analytics until the Store table has the Province column backfilled.
The sequence is rigid:
SL-1: Add structured fields + Backfill Province from Area.Name. (Non-destructive).
SL-2: Cutover Analytics to Province. (Replaces dependencies).
SL-3: Cutover ReminderService to ProfileStoreAssignment. (Replaces dependencies).
SL-4: Cutover ResourceAccessGuard & SyncSubmissions. (Replaces dependencies).
SL-5: Delete Area entirely. (Destructive).
</latent_space_scratchpad>

## Input Lineage
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260518_172535_areadep_area_deprecation.md`

## Executive Summary
This epic architects the safe removal of the `Area` entity in favor of a structured, Vietnam-specific `Address` Value Object (Province, District, Ward, Street) inside the `Store` entity. This transition eliminates an arbitrary geographical bucket and shifts analytical grouping and PBAC entirely to structured provinces and explicit store assignments (`ProfileStoreAssignment`), improving data integrity and security posture.

## Decision Matrix
| Option | Pros | Cons | Verdict |
|---|---|---|---|
| **(A) Flat DB columns via C# OwnedEntities (builder.OwnsOne)** | Clean DDD in C#, simple flat columns in DB. Avoids EF Core 8 `ComplexProperty` quirks. Prevents string fragmentation. | Requires maintaining a static Province list on both Frontend and Backend. | **Winner** |
| **(B) EF Complex Type** | Clean DDD. | EF Core complex type migrations can be tricky (nullable columns). | **Reject** |
| **(C) Standalone Location Tables** | Highest data integrity. | Massive migration (3 new tables, 8000 rows). Overkill. | **Reject** |

## Risk Assessment
| Risk | Severity | Mitigation |
|---|---|---|
| **Analytics Fragmentation** | High | Backend exposes a new `GET /api/reference/locations` endpoint (official GSO hierarchy) to feed frontend cascading dropdowns, preventing app bloat and ensuring 100% sync. Backend strictly validates against this. |
| **Historical Data Loss (Blank Dashboards)** | High | The initial DB migration MUST derive and backfill the new `Province` column from the store's current `Area.Name`. If abstract (e.g. "Northern Region"), fallback to "Uncategorized" so `ProvinceBenchmarkSnapshot` doesn't crash on null. |
| **Escalation Notification Failure** | High | `ReminderService` must stop querying `Profile.AreaId` and instead lookup Area Managers via the `ProfileStoreAssignment` join table. |

## Visual & Functional Context
- **StoreFormSheet**: Replace the single `Area` dropdown with 3 cascading dropdowns (Province, District, Ward) and 1 free-text input (Street).
- **UserEditSheet**: Remove the `Area` assignment field entirely. Managers are assigned explicitly via stores.
- **AnalyticsDashboard**: Leaderboards and benchmarks pivot from "Area" to "Province".
- **AreaManagementPage**: Completely deleted. Route `/admin/areas` removed.

## System Context
- **Security (PBAC)**: `ResourceAccessGuard` strictly enforces access via `ProfileStoreAssignment`. The legacy fallback path that checks `AreaId` will be purged.
- **Sync Logic**: `SyncSubmissions` will drop its `AreaId` fallback query path, relying purely on the explicit store assignment.

## Lifecycle Context
- **Deployment Safety**: This is an in-place structural migration. The destructive phase (SL-5) is explicitly isolated at the very end to ensure rollback capability if SL-1 through SL-4 expose unhandled edge cases.

## Data Context
- **Table Alterations**: `stores` gets `province`, `district`, `ward`, `street` (explicitly mapped via EF `HasColumnName` inside `OwnsOne` to avoid `Address_` prefixes). `area_benchmark_snapshots` is replaced by `province_benchmark_snapshots`.
- **Table Deletions**: `areas` is dropped. `AreaId` foreign keys on `stores` and `profiles` are dropped.

## Architecture Flow
1. **Frontend**: Submits Store creation/updates with structured Address fields selected from strict static lists.
2. **Backend**: Validates Province against a static array. Persists to flat DB columns via EF Core OwnedEntity.
3. **Analytics**: Background workers calculate benchmarks grouped by the `Address_Province` column.
4. **PBAC / Escalations**: Resolves authorization and notification recipients exclusively through the `ProfileStoreAssignment` entity.

## Risk Review & Security
- **IDOR Protection**: Eradicating `AreaId` hardens IDOR defenses. Area Managers can only access data for stores explicitly mapped to them in the junction table, preventing lateral access to unassigned stores that happened to share the same `AreaId`.

## Logs & Audits
- The migration backfill script must default to "Uncategorized" or "Other" for any abstract `Area.Name` strings that cannot be mapped, and log these conversions to preserve visibility.

## Testing Expectations
- Integration tests for PBAC (`SubmissionDelegationAuthTests`, `StoreAuthorizationTests`) must be rewritten to assert against `ProfileStoreAssignment` instead of `AreaId`.
- Analytics integration tests must verify grouping by Province string.

<forensic_evidence>
Executed `grep_search` to verify full system coverage of `AreaId` references:
- Verified `ResourceAccessGuard.IsUserAreaAsync` fallback path.
- Verified `GetAnalytics` benchmark dependencies.
- Verified `ReminderService.SendOverdueEscalations` AM lookup.
</forensic_evidence>

---

## Handoff Block

### 1. Final Epic Decision
Proceed with Epic execution using **Option A (OwnedEntities + Static Taxonomy)**.
Plan file: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260518_194804_areadep_area_deprecation.md`

### 2. Slices & Phasing
This epic MUST be executed sequentially in this exact order to prevent database breaking changes:

- **Slice 1 (SL-1)** `[BLOCKING]`
  - **Intent**: Add structured address fields to Store, configure `builder.OwnsOne` with `HasColumnName` for clean DB columns. Add new `GET /api/reference/locations` endpoint for GSO hierarchy. Run DB Migration with SQL backfill mapping `Area.Name` to `Province` (falling back to "Uncategorized"). Update Store UI to use new reference endpoint.
- **Slice 2 (SL-2)** `[SEQUENTIAL]`
  - **Intent**: Replace `AreaBenchmarkSnapshot` with `ProvinceBenchmarkSnapshot` and update Analytics endpoints/workers to use Province.
- **Slice 3 (SL-3)** `[SEQUENTIAL]`
  - **Intent**: Migrate `ReminderService` to resolve Area Managers via `ProfileStoreAssignment` instead of `Profile.AreaId`.
- **Slice 4 (SL-4)** `[SEQUENTIAL]`
  - **Intent**: Purge `areaId` fallback logic from `ResourceAccessGuard` and `SyncSubmissions`.
- **Slice 5 (SL-5)** `[SEQUENTIAL]`
  - **Intent**: Destructive cleanup. Drop `areas` table, remove `AreaId` columns, delete all Area endpoints, Flutter pages, and routes.

### 3. Next Steps
Handing off to the Architect / Builder to begin SL-1.

### 4. Handoff Roadmap
Each slice requires a specific sequence of workflows based on its risk profile:

- **SL-1 (New Address API & DB)**: `/analyze-feature` → `/atdd` (to lock the API contract) → `/implement`
- **SL-2 (Analytics Worker Rebuild)**: `/analyze-feature` → `/tdd` (to verify snapshot grouping) → `/implement`
- **SL-3 (Reminder Escalations)**: `/analyze-feature` → `/tdd` (to verify AM lookup logic) → `/implement`
- **SL-4 (PBAC & Security Purge)**: `/analyze-feature` → `/tdd` (to verify IDOR guards) → `/implement`
- **SL-5 (Destructive Cleanup)**: `/analyze-feature` → `/implement` (No new logic, just deleting code and running migration)

*(Do NOT execute SL-2 until SL-1 is fully merged and verified.)*
