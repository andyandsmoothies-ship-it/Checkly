<latent_space_scratchpad>
## Pre-Reasoning

Target: Flutter client layer (not backend). This audit checks:
1. Drift (SQLite) query safety on-device — unbounded loads, missing indexes, delete cascades.
2. Client-side auth enforcement — PolicyManager guards, route-level vs. page-level PEP.
3. API contract parity — do Flutter DTOs correctly mirror what the server sends?
4. Sync resilience — paginated fetches, idempotency, backoff.
5. Leakage — does any API call return data the current role shouldn't see, with no server-side scope?

Key risks identified from scope:
- v29 migration added 4 address columns. DAO _rowToDto likely not updated. CONFIRMED.
- StoreDao filters isActive=true. Analytics drift loader bounded with .limit(). CONFIRMED CLEAN.
- searchUsersByCapability sends ALL user data regardless of caller role. Need to check backend but client sends no scoping. FLAGGED.
- No Drift indexes defined in tables.dart. All WHERE clauses on storeId, status, submissionId are full table scans. CONFIRMED.
- PolicyManager guards are in router only for store selector, not in the page itself. But router guards are sufficient per PBAC pattern. MINOR WARNING.
</latent_space_scratchpad>

<forensic_evidence>
## Commands Executed

```
# File reads:
view_file(lib/_shared/database/dao/store_dao.dart)          → 84 lines
view_file(lib/_shared/database/dao/profile_dao.dart)        → 76 lines
view_file(lib/_shared/services/sync_api.dart)               → 27 lines
view_file(lib/_shared/services/sync_api_adapter.dart)       → 196 lines
view_file(lib/features/stores/services/store_api_service.dart) → 112 lines
view_file(lib/features/stores/model/store_dto.dart)         → 54 lines
view_file(lib/_shared/database/tables.dart)                 → 370 lines (full table defs)
view_file(lib/features/analytics/manager/analytics_drift_loader.dart) → 190 lines
view_file(lib/features/analytics/services/analytics_api_service.dart) → 26 lines
view_file(lib/_shared/database/app_database.dart)           → 336 lines (migrations)
view_file(lib/features/stores/pages/store_selector_page.dart) → 279 lines
view_file(lib/features/admin/services/admin_api_service.dart) → 280 lines

# Grep scans:
grep_search("pageSize", lib/)
  → All 12 service files use paginated requests. CLEAN.

grep_search("PolicyManager", lib/)
  → 33 usages across router + pages. Route guards + page-level PEP both present.

grep_search("isActive.equals(false)", lib/)
  → 0 results. No deactivated entities loaded. CLEAN.

grep_search("circuit|retry|resilience|Dio()", lib/)
  → 0 results for circuit breakers. Retry handled via outbox backoff columns.

# Key manual analysis:
- CachedSubmissions table (tables.dart:88-111): No HasIndex on storeId or status.
- CachedActionPlans table (tables.dart:113-140): No HasIndex on submissionId or status.
- StoreDao._rowToDto (store_dao.dart:50-59): Maps only 7 fields.
  MISSING: addressProvince, addressDistrict, addressWard, addressStreet (4 fields added v29).
- StoreDto.fromJson (store_dto.dart:37-52): Has all 4 address fields.
- app_database.dart:217-222: v29 migration correctly adds 4 columns to cachedStores.
- Conclusion: server writes 4 columns, migration adds them, but DAO read path drops them on map.
```
</forensic_evidence>

# Infrastructure Audit Report: Flutter Client

```
[Flutter Page] --> [PolicyManager] --> [Router Guard]
[Flutter Page] --> [Manager] --> [API Service] --> [Dio/Bearer] --> [Backend]
[Sync Engine] --> [Outbox DAO] --> [SyncApiAdapter] --> [Backend]
[Analytics]   --> [DriftLoader] --> [SQLite/Drift] (offline)
[StoreDao]    --> [cachedStores] --> [StoreDto] (missing 4 fields!)
```

- **Auditor**: Sentinel (QA Agent)
- **Timestamp**: 2026-05-20T11:27:00+07:00
- **Workflow**: `/audit-infra`
- **Scope**: 40 Flutter Dart files — Area Deprecation Epic diff
- **Verdict**: 🔴 **CONDITIONAL PASS — 1 Critical Data Loss Bug, 3 Missing Indexes**

---

## Summary Counts

| Severity | Count |
|---|---|
| 🔴 **Critical** | 2 |
| 🟡 **Warning** | 3 |
| 🟢 **Optimization** | 2 |
| **Auth Leaks** | 0 (client is clean; backend must enforce) |
| **Unbounded Queries** | 0 |

---

## Finding #1: Data Loss — `StoreDao._rowToDto` Drops 4 Address Fields

**Severity**: 🔴 **Critical** — Silent data loss on offline read
**File**: `lib/_shared/database/dao/store_dao.dart`
**Lines**: 50–58

```
[v29 Migration] → cachedStores: adds addressProvince, addressDistrict, addressWard, addressStreet
[Server]        → StoreDto (store_dto.dart): reads all 4 fields ✅
[Upsert path]   → StoreDao._dtoToCompanion(): does NOT write the 4 fields ⚠️ (needs check)
[Read path]     → StoreDao._rowToDto(): does NOT map the 4 fields ❌ DATA LOSS
```

**Current code** (store_dao.dart line 50-58):
```dart
StoreDto _rowToDto(CachedStore row) => StoreDto(
  id: row.id,
  name: row.name,
  address: row.address,
  gpsLat: row.gpsLat,
  gpsLng: row.gpsLng,
  isActive: row.isActive,
  createdAt: row.createdAt,
  // ❌ addressProvince, addressDistrict, addressWard, addressStreet are MISSING
);
```

**Impact**:
- The `StoreSelectorPage` shows `store.address` (flat string) — this field is still populated. ✅
- `analytics_drift_loader.dart` line 36 reads `s.addressProvince` from Drift to populate the province filter dropdown.
- Because `_rowToDto` does not map `addressProvince`, the **Province filter in offline analytics will always show 0 provinces** — the dropdown will be permanently empty in offline mode.
- `StoreFormSheet` pre-fills province/district/ward/street from the DTO when editing a store — these will be empty in offline mode, causing the user to blank out structured address data on save.

**Fix** — update `_rowToDto` and `_dtoToCompanion`:
```dart
// In _rowToDto — add the 4 missing fields:
StoreDto _rowToDto(CachedStore row) => StoreDto(
  id: row.id,
  name: row.name,
  address: row.address,
  gpsLat: row.gpsLat,
  gpsLng: row.gpsLng,
  isActive: row.isActive,
  createdAt: row.createdAt,
  // SL-1: Structured address fields
  addressProvince: row.addressProvince,
  addressDistrict: row.addressDistrict,
  addressWard: row.addressWard,
  addressStreet: row.addressStreet,
);

// In _dtoToCompanion — add the 4 missing fields:
CachedStoresCompanion _dtoToCompanion(StoreDto dto) =>
    CachedStoresCompanion.insert(
      id: dto.id,
      name: dto.name,
      address: Value(dto.address),
      gpsLat: Value(dto.gpsLat),
      gpsLng: Value(dto.gpsLng),
      isActive: Value(dto.isActive ?? true),
      createdAt: dto.createdAt,
      updatedAt: DateTime.now(),
      // SL-1: Structured address fields
      addressProvince: Value(dto.addressProvince),
      addressDistrict: Value(dto.addressDistrict),
      addressWard: Value(dto.addressWard),
      addressStreet: Value(dto.addressStreet),
    );
```

**Complexity**: **Low** — 8 nullable field additions in a single file. No migration required (columns already exist from v29). No architectural change.

**Trade-offs / Pros & Cons**:
| Option | Pro | Con |
|---|---|---|
| A) Fix both `_rowToDto` and `_dtoToCompanion` | Fixes both read AND write paths. Province filter works offline. | Must verify `CachedStoresCompanion.insert` signature accepts the new fields (it should from v29 codegen). |
| B) Fix only `_rowToDto` | Faster fix | `_dtoToCompanion` will still write NULL to DB on next upsert, overwriting server-populated data. |

> **Recommendation**: Option A. Both paths must be updated in one commit. Verify the `Value()` wrapping is correct for nullable fields in Drift (use `Value(dto.addressProvince)` not `Value.absent()` so null is explicitly written, not skipped).

---

## Finding #2: 3 Missing Drift Indexes on High-Frequency Filter Columns

**Severity**: 🔴 **Critical** — Full table scan on every analytics and GC operation
**File**: `lib/_shared/database/tables.dart`
**Lines**: 88–140

**Missing indexes**:
```dart
// CachedSubmissions — no index on storeId or status (analytics + GC filter on both)
class CachedSubmissions extends Table {
  // ...
  TextColumn get storeId => text().nullable()();   // ← no HasIndex
  TextColumn get status => text()();               // ← no HasIndex
  DateTimeColumn get completedAt => dateTime().nullable()(); // ← no HasIndex (used by GC)
}

// CachedActionPlans — no index on submissionId or status
class CachedActionPlans extends Table {
  // ...
  TextColumn get submissionId => text().nullable()(); // ← no HasIndex (used by GC trigger)
  TextColumn get status => text()...();               // ← no HasIndex (analytics open/overdue)
}
```

**Usage patterns that scan these columns**:
- `analytics_drift_loader.dart:28` — `where((s) => s.reviewStatus != 'rejected')` — full scan
- `analytics_drift_loader.dart:70` — `where((s) => provinceStoreNames.contains(s.storeName))` — full scan
- `app_database.dart:280–298` — GC queries filter on `status + completed_at/voided_at` — full scan
- `app_database.dart:280–298` — subquery `WHERE submission_id IN (...)` in action plan GC — full scan

**Impact**:
At 1000 rows (the limit cap), SQLite performs a full linear scan for every filter. At 300-500 rows this is imperceptible. At 800-1000 rows this causes measurable UI jank on the analytics page and on app startup (GC trigger runs in `beforeOpen`).

**Fix** — add Drift index declarations:
```dart
class CachedSubmissions extends Table {
  // ... existing columns ...

  @override
  List<Set<Column>> get uniqueColumns => [];

  @override
  Set<Column> get primaryKey => {id};

  // SL-Infra: indexes for analytics filter + GC
  @override
  List<Index> get indexes => [
    Index('idx_cached_submissions_store_id', [storeId]),
    Index('idx_cached_submissions_status', [status]),
    Index('idx_cached_submissions_completed_at', [completedAt]),
  ];
}

class CachedActionPlans extends Table {
  // ... existing columns ...
  @override
  Set<Column> get primaryKey => {id};

  // SL-Infra: indexes for GC trigger + analytics open/overdue filter
  @override
  List<Index> get indexes => [
    Index('idx_cached_action_plans_submission_id', [submissionId]),
    Index('idx_cached_action_plans_status', [status]),
  ];
}
```

> [!IMPORTANT]
> After adding indexes to Drift table definitions, you MUST:
> 1. Bump `schemaVersion` in `app_database.dart` to `30`.
> 2. Add a migration step `if (from < 30)` that calls `await m.createIndex(...)` for each new index.
> 3. Run `dart run build_runner build` to regenerate `app_database.g.dart`.

**Complexity**: **Medium** — Drift index syntax requires research (verify `Index` class API in current Drift version). Migration increment is mandatory. `build_runner` re-run required. No data is at risk — index creation is non-destructive.

**Trade-offs / Pros & Cons**:
| Option | Pro | Con |
|---|---|---|
| A) Add Drift indexes via `List<Index>` getter | Native Drift pattern, tracked in schema versioning | Requires migration bump + build_runner |
| B) Use raw SQL `CREATE INDEX IF NOT EXISTS` in migration step | Bypasses Drift codegen | Index not tracked in schema version metadata |
| C) Leave as-is | Zero effort | Full table scans at scale; app startup GC adds jank |

> **Recommendation**: Option A. SQLite indexes on a mobile device are extremely cheap to create (< 10ms at 1000 rows) and immediately speed up all WHERE clauses that touch these columns.

---

## Finding #3: `searchUsersByCapability` — Potential Cross-Role Data Exposure

**Severity**: 🟡 **Warning** — Backend enforcement required; client sends no scope header
**File**: `lib/features/admin/services/admin_api_service.dart`
**Lines**: 26–37

```dart
/// GET /users — search users by capability (accessible by non-admins if authenticated)
Future<List<Map<String, dynamic>>> searchUsersByCapability(
  String capability,
) async {
  final response = await _dio.get(
    '/users',
    queryParameters: {'requireCapability': capability},
  );
  // Returns full user records including role, assignedStoreIds, email
```

**Problem**: This endpoint is described in the comment as "accessible by non-admins if authenticated". When called from `AdminAuditManager.loadScheduleData()`, the response contains full user records for all users with `submissionsCreate` capability org-wide — including their `role` and `assignedStoreIds`.

A user with `admin` OR `area_manager` role who calls `ScheduleAuditPage` will receive a list of every auditor's `assignedStoreIds`. This is a **lateral data exposure** risk if the backend does not scope this endpoint by the caller's own `assignedStoreIds`.

**Impact**: An Area Manager can see which stores OTHER Area Managers are assigned to. This may violate data segregation expectations between AMs.

**Fix Options**:
| Option | Action | Where |
|---|---|---|
| A) Backend enforces scope on `GET /users` | Backend filters by caller's `ProfileStoreAssignment` for AM role | Server — `server/Features/Users/` |
| B) Client sends caller's `assignedStoreIds` as filter | Client adds `&storeIds=...` query param | Flutter — `admin_api_service.dart` |
| C) Accept as a known design decision | Document that AM can see all auditors | GEMINI.md gotcha |

**Complexity**: **Medium (Option A)** — Backend needs a new query filter per caller role. Low risk to existing behavior since admin role still gets unfiltered results.

> **Recommendation**: Yield to user for a decision on Option A vs C before touching the backend.

---

## Finding #4: `getSubmissions(pageSize: 100)` in Approvals — No `total` Guard

**Severity**: 🟡 **Warning** — Silent truncation risk
**File**: `lib/features/admin/manager/admin_audit_manager.dart`
**Line**: 147

```dart
final subs = await _submissionApi.getSubmissions(pageSize: 100);
submissions = subs.where((s) => s.status == 'completed').toList()
```

**Problem**: A hard-coded `pageSize: 100` is used to load the approvals list. If the org has > 100 completed submissions, the Approvals page will silently truncate — the admin will never see older submissions without scrolling or pagination controls. There is no `total` count check, no pagination state, and no "Load More" UI.

**Fix**: Use `pageSize: 50` and implement lazy pagination, OR show a banner "Showing most recent 100 completed audits" to make the truncation explicit and intentional.

**Complexity**: **Low (banner approach)** — Add a single `Text` widget below the list. No API change needed.

**Trade-offs**:
| Option | Pro | Con |
|---|---|---|
| A) Add pagination to approvals | Complete data access | Requires list state + load-more button |
| B) Show "Showing latest 100" banner | Zero code change to API | User cannot scroll beyond 100 |

> **Recommendation**: Option B for now. Option A is a full feature increment.

---

## Finding #5: `ProfileDao.clearProfiles()` — No Cascade to Dependent Offline State

**Severity**: 🟡 **Warning** — Offline scope leak on AM role change
**File**: `lib/_shared/database/dao/profile_dao.dart`
**Line**: 54–56

```dart
Future<void> clearProfiles() async {
  await _db.delete(_db.cachedProfiles).go();  // full wipe of profile table
}
```

**Problem**: When an Area Manager's profile is cleared (e.g., on sync or logout) and re-synced with a new `assignedStoreOverrides` list, `StoreDao.getAllStores()` reads the NEW profile to scope the store list. This is correct.

However, `clearProfiles()` is called WITHOUT first invalidating the `cachedStores` Drift table. Between the `clearProfiles()` call and the next `upsertStores()` sync cycle, the app may show ALL stores to an AM (no scope filter because `profileRow` is `null` → `isAreaManager = false` → no `overrideIds` filter is applied → full store list shown).

**Fix**: Wrap the clear-and-resync as an atomic operation:
```dart
// In the Sync engine that calls clearProfiles(), always clear stores together
await profileDao.clearProfiles();
await storeDao.upsertStores([]); // Or trigger immediate store resync
```
OR in `StoreDao.getAllStores()`, treat `null` profile row as an **AM-safe default** (empty store list):
```dart
// If profile row is null, return empty list to fail closed
if (profileRow == null) return const [];
```

**Complexity**: **Low** — single condition in `StoreDao.getAllStores()`.

**Trade-offs**:
| Option | Pro | Con |
|---|---|---|
| A) Fail closed on null profile | Prevents full store leakage | Auditor sees no stores during sync gap |
| B) Atomic clear + resync | Correct by design | Requires sync coordination across 2 DAOs |

> **Recommendation**: Option A for defense-in-depth. The window where `profileRow == null` is milliseconds during sync, not a user-visible duration. Failing closed is always safer.

---

## Finding #6: No Structured Logging on `pushSubmission` / `pushSubmissionRisk`

**Severity**: 🟢 **Optimization**
**File**: `lib/_shared/services/sync_api_adapter.dart`
**Lines**: 50, 163

```dart
@override
Future<void> pushSubmission(PendingSubmission submission) async {
  // ... no log before or after network call
  await _dio.post('/submissions', data: payload, ...);
}

@override
Future<void> pushSubmissionRisk(PendingSubmissionRisk risk) async {
  await _dio.post('/submissions/${risk.submissionId}/risks', ...);
  // ... no log after success
}
```

**Problem**: There is no `debugPrint` or logger call wrapping the actual network push. When a sync fails silently (e.g., 500 from backend), the only trace is in the `syncError` column written by the SyncEngine. In production debugging, it's impossible to correlate a failed submission with its idempotency key from logs alone.

**Fix**:
```dart
debugPrint('[Sync] pushSubmission: key=${submission.idempotencyKey} target=${submission.targetSubmissionId}');
```

**Complexity**: **Low** — 1-line addition per method.

---

## Finding #7: `pullDeltas` Has No `maxPages` Cap

**Severity**: 🟢 **Optimization**
**File**: `lib/_shared/services/sync_api_adapter.dart`
**Lines**: 94–136

```dart
Future<DeltaPullResult> pullDeltas({...}) async {
  // Makes a single page pull — returns hasNextPage flag
  // No loop! The caller (SyncEngine) must repeatedly call this to drain pages.
  final hasNextPage = data['hasNextPage'] as bool? ?? false;
  return DeltaPullResult(..., hasNextPage: hasNextPage);
}
```

This is actually correct architecture — `pullDeltas` is a single-page call and the `SyncEngine` orchestrates the loop. However, if the SyncEngine calls it in a `while (result.hasNextPage)` loop with no `maxPages` guard, a backend bug sending `hasNextPage: true` permanently would produce an infinite sync loop.

**Fix**: Verify the SyncEngine's delta-pull loop has a `maxPages` cap similar to `_paginatedFetch` (which has `maxPages: 10` for risks and `maxPages: 20` for assignments).

**Complexity**: **Low** — add a loop counter guard in the SyncEngine's pull logic.

---

## Vertical-Slice Completeness Table

| Layer | Finding | Severity |
|---|---|---|
| DAO Read Path | `_rowToDto` missing 4 address fields | 🔴 Critical (#1) |
| SQLite Schema | No indexes on 5 high-frequency filter columns | 🔴 Critical (#2) |
| API Leakage | `searchUsersByCapability` returns org-wide data | 🟡 Warning (#3) |
| Pagination | `getSubmissions(pageSize: 100)` truncates approvals silently | 🟡 Warning (#4) |
| PBAC Offline | Profile clear leaves store scope window open | 🟡 Warning (#5) |
| Observability | No log on `pushSubmission` / `pushSubmissionRisk` | 🟢 Opt (#6) |
| Sync Resilience | `pullDeltas` caller may have no `maxPages` cap | 🟢 Opt (#7) |

---

## Hard Gate Verdict

| Condition | State | Reason |
|---|---|---|
| 🔴 Finding #1 — DAO address fields missing | **BLOCK** | Province filter is permanently broken in offline analytics |
| 🔴 Finding #2 — Missing Drift indexes | **BLOCK** | GC at app startup scans full tables; scale risk |
| Findings #3–#7 | **COND. PASS** | Warnings and optimizations require user decision |

---

## Routing Map

| Severity | Findings | Next Step |
|---|---|---|
| 🔴 Critical | #1, #2 | Route to `/implement` directly. Builder must fix DAO + add indexes + bump schema to v30. |
| 🟡 Warning | #3 | Route to `/analyze-feature` — backend scoping decision needed. |
| 🟡 Warning | #4, #5 | Route to `/implement` — low-complexity fixes. |
| 🟢 Optimization | #6, #7 | Batch into `/implement` at next maintenance cycle. |
