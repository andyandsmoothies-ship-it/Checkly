<latent_space_scratchpad>
Slice 4 assumes an existing sync endpoint, but codebase currently has only `/api/sync/templates` and `/api/sync/submissions` mapped from `TemplateEndpoints.cs`; no `/api/sync/profile` exists. Flutter also lacks `CachedProfiles` table entirely; the epic line "no new Drift table" conflicts with this state unless we serialize into existing auth storage (`UserSession`) instead. Since epic acceptance explicitly calls for `CachedProfiles` override text column, plan should preserve that contract and add one table.

Current `Login.Response` only returns userId/email/role/token/fullName. If sync profile endpoint is introduced, we must define which caller uses it: AuthManager on login/auto-login refresh vs SyncEngine pull module. Keep blast radius small by adding a dedicated lightweight profile sync module or a direct AuthManager fetch call.

UpdateUser already returns `assignedStoreIds` for area_manager after Slice 3; this is useful but not sufficient for offline-first because login may happen before assignment changes and app restarts need persisted store scope. We should avoid coupling store visibility to admin pages and persist profile assignment list in local DB.
</latent_space_scratchpad>

## Input Lineage
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\store_area_consolidation\analysis_epic_20260503_215500_2b21e338_area_override.md` (Slice 4)
- `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_173100_q4m7s3k1_slice3_admin_api.md` (preceding slice context)

## Executive Summary & Out of Scope
Implement Slice 4 by adding a profile sync contract that returns AM direct assignments and persisting them in Flutter for offline behavior:
- Add backend endpoint `GET /api/sync/profile` returning profile identity + `assignedStoreIds`.
- Add Flutter persistence for synced profile with serialized assigned stores string.
- Update store lookup path to consume this override string for AM scope decisions.

Out of scope:
- Admin UI changes for virtual area/store picker messaging (Slice 5).
- Additional auth perimeter rewrites (completed in Slice 2).
- Reworking SyncEngine architecture beyond minimal profile pull integration.
- Any further role-rule changes in admin API (completed in Slice 3).

## System Context
- **Runtime Model:** Hybrid online/offline mobile app (Flutter + Drift) with ASP.NET Core backend.
- **APIs:** Existing sync group under `/api/sync` currently includes templates/submissions only.
- **RBAC:** Profile sync endpoint requires authenticated caller; role impacts payload (`assignedStoreIds` meaningful for `area_manager`, empty for others).
- **Logs/Audit:** No new admin mutation log required; read-only endpoint should keep standard request logging.

## Lifecycle Context
| State | Slice 4 behavior |
|---|---|
| Success | `/api/sync/profile` returns profile + `assignedStoreIds`; Flutter persists and store filtering honors serialized overrides. |
| Error | Endpoint unavailable/500 -> app should continue using existing cached profile, no crash; sync cycle marks error. |
| Empty | AM with no assignments yields empty array/string and no stores shown for assignment-dependent views. |
| Loading | Auth bootstrap or sync pull can fetch profile; UI should remain responsive with stale cache until refresh completes. |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-4.1 | `GET /api/sync/profile` returns `assignedStoreIds` equal to `ProfileStoreAssignments` for AM | Success/Boundary | Endpoint does not exist yet |
| TC-4.2 | Same endpoint for non-AM returns empty `assignedStoreIds` while preserving core identity fields | Success/Boundary | Contract not implemented |
| TC-4.3 | Flutter profile cache persists assigned store IDs as serialized text and can roundtrip parse | Success | No `CachedProfiles` table/DAO path exists |
| TC-4.4 | Store lookup for AM uses profile-assigned store override when present | Success/Boundary | `store_dao.dart` currently ignores profile assignment overrides |
| TC-4.5 | Invalid/empty serialized override string falls back safely without crash | Error/Empty | No parser/fallback branch exists |

## Test Fixture & Payloads
- **Server fixture requirements:**
  - Seeded user profile + role row.
  - For AM tests: at least 2 rows in `profile_store_assignments`.
- **Flutter fixture requirements:**
  - In-memory Drift DB.
  - Seeded `CachedProfiles` row with serialized assigned stores.

Example response payload:
```json
{
  "userId": "7f8f5e88-16fb-45ef-8bb0-3f0a6e6d0b27",
  "email": "am@test.com",
  "role": "area_manager",
  "fullName": "Area Manager",
  "assignedStoreIds": [
    "92f9dd5a-5d5a-4cdf-84af-95ea4b702c35",
    "ca7cc950-6de8-40e8-842b-d2a0995f0921"
  ]
}
```

## Tools & Commands
- **Skills:**  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\testing-strategy\SKILL.md`  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\ef-core\SKILL.md`  
  - `c:\Users\HP\Documents\GitHub\Checkly\.agents\skills\tdd\SKILL.md`
- **Validation commands:**
  - `rtk dotnet test c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Checkly.Api.Tests.csproj --filter "FullyQualifiedName~SyncProfile|FullyQualifiedName~AuthTests"`
  - `flutter test lib/_shared/database`
  - `flutter test lib/features/stores`

## Proposed Changes
| Status | File Path | Type |
|---|---|---|
| [NEW] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Auth\SyncProfile.cs` | backend endpoint handler |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Templates\TemplateEndpoints.cs` | map `/api/sync/profile` route in sync group |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\...` (new sync profile tests) | API contract tests |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\tables.dart` | add `CachedProfiles` table with serialized assigned store text column |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\app_database.dart` | Drift schemaVersion bump + migration for cached profile table |
| [NEW] | `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\dao\profile_dao.dart` | read/write profile cache + serialization helpers |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\_shared\database\dao\store_dao.dart` | consume profile override store IDs for AM selection |
| [MOD] | `c:\Users\HP\Documents\GitHub\Checkly\lib\features\auth\services\auth_api_service.dart` / `AuthManager` / sync adapter | call new sync profile endpoint and persist profile cache |

## Concept Diagram
`[Login/Sync] --> [GET /api/sync/profile] --> [assignedStoreIds[]] --> [serialize to cached_profiles.assigned_store_overrides] --> [StoreDao parses overrides] --> [offline store scope for AM]`

## Execution Slices
### Phase A: Backend sync profile endpoint (Complexity: Medium)
- Add endpoint + DTO projection from `Profiles` + `ProfileStoreAssignments`.
- Add API tests (happy + empty + role boundary).
- **Pros:** establishes clear contract first.
- **Cons:** requires route placement decision under existing sync group.

### Phase B: Flutter DB schema + DAO (Complexity: Medium)
- Add `CachedProfiles` table and migration.
- Add `ProfileDao` serialization (`List<String> <-> comma string`) with safe parser.
- **Pros:** isolates persistence logic.
- **Cons:** Drift migration touches global DB schema and generated code.

### Phase C: Consumer wiring (`AuthManager` / `StoreDao`) (Complexity: Medium)
- Fetch/store synced profile data on login and refresh path.
- Use cached override ids in store selection logic.
- **Pros:** delivers end-to-end behavior.
- **Cons:** requires careful fallback to avoid startup regressions offline.

**Pros & Cons Decision Needed Before Build**
- **Choice 1 (recommended):** Add dedicated `/api/sync/profile` endpoint + new `CachedProfiles` table (aligns with epic AC exactly).  
  - Pro: explicit contract and resilient offline cache.  
  - Con: broader schema/API surface.
- **Choice 2 (minimal):** Extend login payload only, avoid new endpoint/table.  
  - Pro: fewer files now.  
  - Con: diverges from epic and weak on stale/offline refresh.

## Risk Assessment
> **Risk Warning:** Slice 4 crosses backend sync API + local DB schema + store filtering logic. A mismatch can silently hide stores for AM users offline.

| Risk | Severity | Mitigation |
|---|---|---|
| Missing `/api/sync/profile` currently | High | Build endpoint and tests first (Phase A) before Flutter changes |
| Drift migration breakage on existing installs | High | Add deterministic migration step and verify schema upgrade path |
| Serialized override parsing errors | Medium | Implement robust parser + TC-4.5 fallback tests |
| Duplicate source of truth (`UserSession` vs `CachedProfiles`) | Medium | Define one precedence rule in manager/DAO (cached profile override first for store scope) |

## Verification Plan
1. Add/execute backend tests for `GET /api/sync/profile` (AM populated, non-AM empty, unauthorized path).
2. Run `rtk dotnet test` filtered to new sync-profile tests, then broader auth/sync regression set.
3. Run Flutter DB tests covering migration to new schema version and `ProfileDao` serialization roundtrip.
4. Run Flutter store-selection tests validating override parsing and fallback behavior.
5. Execute `flutter analyze` or equivalent lint gate on modified Dart files.

## Handoff Block
Slice 4 analysis complete. This slice is network/auth/database integration and should start with acceptance/integration tests first.

Run one command at a time:
`@[/atdd] Execute specs for Slice 4 (Profile Sync — Flatten Payload): c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260504_190800_q4m7s4p1_slice4_profile_sync.md`

Concurrency:
- Slice 5 UI depends on Slice 4 payload persistence and should wait until Slice 4 backend+offline contract is green.

<command_logs>
- ReadFile `.agents/workflows/analyze-feature.md`
- ReadFile epic analysis doc for slice definitions
- ReadFile `GEMINI.md`, `server/GEMINI.md`, `lib/GEMINI.md`
- rg server for `sync/profile`, `assignedStoreIds`, sync routes
- ReadFile `server/Features/Templates/TemplateEndpoints.cs`
- ReadFile `server/Features/Auth/Login.cs`
- ReadFile `lib/_shared/database/tables.dart`, `app_database.dart`, `store_dao.dart`
- ReadFile `lib/features/auth/manager/auth_manager.dart`, `auth_api_service.dart`
- ReadFile `lib/_shared/services/sync_api.dart`, `sync_api_adapter.dart`, `core_audit_sync_module.dart`
</command_logs>

<forensic_evidence>
- Verified backend currently has sync routes only for templates and submissions (`TemplateEndpoints.cs` maps `/api/sync/templates` and `/api/sync/submissions`), no `/api/sync/profile`.
- Verified login/auth payload does not include assigned stores (`Login.Response` and `UserSession` contain only userId/email/role/token/fullName).
- Verified Flutter local DB has no `CachedProfiles` table in `tables.dart`; `store_dao.dart` currently filters by active cached stores only and ignores AM assignment overrides.
- Verified SyncEngine modules (`CoreAuditSyncModule`, `ProgramSyncModule`) have no profile pull contract in `SyncApi`/`SyncApiAdapter`.
- Verified Slice 3 has server-side `assignedStoreIds` in admin update response but no mobile sync persistence path.
</forensic_evidence>
