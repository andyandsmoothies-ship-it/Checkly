<latent_space_scratchpad>
## Pattern Label: Filter Extension (State Machine + Query Parameter Propagation)

## Key Constraints Found in Codebase:
1. GetAnalytics.cs L22: already reads `scoringMode` query param (LEGACY — must be REPLACED with `categoryTag`)
2. GetAnalytics.cs L139-140: filters on `s.ScoringMode == scoringModeFilter` (LEGACY — target for replacement)
3. GetAnalytics.cs L152: "scored submissions" check: `s.ScoringMode != "survey"` (MUST change to `s.ScoreDirection != "none"`)
4. GetAnalytics.cs L159: survey count check: `s.ScoringMode == "survey"` (MUST change to `s.ScoreDirection == "none"`)
5. The `AnalyticsResponse` has no `categoryTags` list for the UI dropdowns — we need to add it.
6. Analytics manager has `selectedType` but NO `selectedCategoryTag` — must add.
7. `AnalyticsFilterSheet` has no category tag dropdown — must add.
8. `AnalyticsFilterChips` has no category tag chip — must add.
9. `analytics_api_service.dart` `getAnalytics()` has no `categoryTag` param — must add.
10. `analytics_drift_loader.dart` has no `selectedCategoryTag` filter — must add.
11. `AnalyticsData` has no `categoryTagNames` list — must add.
12. `CachedTemplates` will have `categoryTag` after Slice 4B (prerequisite).
13. `CachedSubmissions` — does it have `categoryTag`? Need to check. The Submission entity has it, but we need to verify the Drift table and sync.

## File Size Checks:
- GetAnalytics.cs = 268 lines (below 400 — OK)
- analytics_manager.dart = 210 lines (below 250 line warning — OK)
- analytics_drift_loader.dart = 190 lines (below 250 — OK, will grow slightly)
- analytics_filter_sheet.dart = 190 lines (close to 250 warning — adding one dropdown keeps it ~205, OK)
- analytics_filter_chips.dart = 155 lines (OK)

## Out of Scope:
- BOD report changes (separate feature)
- Changing the score averaging math or trend calculation
- Adding categoryTag to the section breakdown query
- Category tag CRUD management screen (not in this Epic)

## Risk:
- MEDIUM: The `scoringMode` references in GetAnalytics.cs lines 152 and 159 are logic bugs that exist today. If Slice 2 already fixed these, then Slice 5 just needs to add the categoryTag filter. Must confirm from implementation plan for Slice 2.
- LOW: The categoryTag list needs to come from somewhere. The cleanest approach: query DISTINCT category_tags from `submissions` table (not templates), so filters only show tags that have actual data in the current date range. Alternatively, send it from templates. Decision: read from `CachedSubmissions.categoryTag` in Dart offline, and from `db.Submissions.Select(s => s.CategoryTag).Distinct()` in backend.

## CachedSubmissions check needed: does the Drift table have categoryTag column?
Based on context from previous slices: the `Submission` entity has `CategoryTag`. The sync endpoint would need to include it. This is a dependency — need to check SyncSubmissions.

## Key Invariant:
- ScoringMode references in analytics = LEGACY BUG (introduced before Slice 2 fixed the parser). They may be cleaned up by Slice 2, but if not, this Slice must clean them.
- The scoringMode filter query param must be RENAMED to categoryTag.
</latent_space_scratchpad>

# Implementation Plan: Scoring Redesign — Slice 5: Analytics Dashboard Filter

**Created**: 2026-05-30T11:37:00+07:00
**Epic**: SCORING-REDESIGN | **Slice**: 5 of 5
**Status**: PLANNING

---

## Input Lineage

- **Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\analysis_epic_20260529_222100_scoring_redesign_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Previous Slices**: Slices 1–4 must be complete before this slice. In particular:
  - **Slice 1**: `category_tag` column exists on `submissions` and `templates` tables (PostgreSQL). ✅ Verified in migration `20260529161300_AddScoringDirectionAndCategoryTag.cs`.
  - **Slice 2**: `ScoringMode` removed from C# DTOs; `ScoreDirection`/`IsWeighted` now control parser logic. Required before fixing `GetAnalytics.cs` legacy `ScoringMode` references.
  - **Slice 3**: `ScoreDirection` enum in Flutter. `CachedSubmissions` must have `categoryTag` column synced.
  - **Slice 4**: Template builder saves `CategoryTag`. `CachedTemplates` has `categoryTag` column.

---

## Executive Summary & Out of Scope

**Goal**: Add a `categoryTag` filter to the analytics dashboard. Admins and managers can filter all KPIs, trend, and section breakdown by the audit category (e.g., `compliance`, `routine`, `financial`).

### What we build:
```text
[User taps Filters] ──► [AnalyticsFilterSheet shows Category Tag dropdown]
                                        │
                                        ▼ (manager.selectedCategoryTag = 'compliance')
                               [AnalyticsManager.load()]
                                        │
                   ┌────────────────────┴────────────────────────┐
                   │ ONLINE                                        │ OFFLINE
                   ▼                                               ▼
       [AnalyticsApiService.getAnalytics(               [analytics_drift_loader.dart]
         categoryTag: 'compliance')]                    filter CachedSubmissions by
                   │                                    templateId in templates where
                   ▼                                    categoryTag == 'compliance'
       [GET /api/analytics?categoryTag=compliance]
                   │
                   ▼
       [GetAnalytics.cs] filter:
         query.Where(s => s.CategoryTag == categoryTag)
                   │
                   ▼
       [AnalyticsResponse adds categoryTagNames list]
                   │
                   ▼
       [Flutter renders chip + count updates]
```

### What we do NOT build (YAGNI):
- No change to BOD report (separate subsystem).
- No change to scoring math or trend algorithm.
- No category tag CRUD management screen.
- No changes to the Section Breakdown widget labels.
- No `categoryTag` filter on the auditor productivity endpoint.

---

## System Context

| Constraint | Detail |
|------------|--------|
| Offline-first | `analytics_drift_loader.dart` must filter by `categoryTag` via `CachedTemplates.categoryTag` → `CachedSubmissions.templateId` join |
| API contract | `GET /api/analytics?categoryTag=compliance` — new query param. Old `scoringMode` param must be removed. |
| RBAC | No change — `RequireCapability(AppCapabilities.AnalyticsView)` gates this endpoint |
| Legacy cleanup | `GetAnalytics.cs` lines 22, 139-140, 152, 159 reference `ScoringMode` — these become dead code after Slice 2. This slice must confirm they are cleaned up. |
| File size | `analytics_filter_sheet.dart` = 190 lines; adding one dropdown ≈ 205 lines. Still within limit. |
| Data source | `categoryTagNames` list sent in API response from `db.Submissions.Select(s => s.CategoryTag).Distinct()` — filtered by active date range for relevance. |

---

## Lifecycle Context

### 4-State Matrix

| State | Screen Behavior |
|-------|----------------|
| **Loading** | `CircularProgressIndicator` shown by `analytics_page.dart` (existing behavior, no change) |
| **Success — no filter** | All KPIs show. Category Tag dropdown in filter sheet shows all tags from API response. Chip bar shows no category chip. |
| **Success — with filter** | All KPIs are scoped to the selected `categoryTag`. Category chip appears in `AnalyticsFilterChips` with delete button. `activeFilterCount` increments by 1. |
| **Error / Offline** | `isOffline = true`. `analytics_drift_loader.dart` applies category tag filter locally using `CachedTemplates.categoryTag`. Shows offline banner. |
| **Empty (filtered)** | `totalAudits == 0 && activeFilterCount > 0` → existing "Let's widen the search!" empty state fires automatically (no new code needed). |

---

## Constraint Traceability

| Constraint from Epic | Source Line | Test Contract ID |
|----------------------|-------------|-----------------|
| Dashboard can filter by category (R4) | Epic L68 | TC-01 |
| Sync contract clean: no dual-field mapping | Epic L69 | TC-02 (handled by Slice 2; verify here) |
| Old `ScoringMode` removed from analytics endpoint | Epic L303 | TC-03 |
| Averages not distorted by category filter | Epic L274 | TC-04 |
| Offline fallback filters by category tag | Epic L140 | TC-05 |
| `categoryTag` query returns only matching data | Epic L241 | TC-01 |

---

## Test Contracts

### TC-01: Category Filter Returns Only Matching Submissions
- **Type**: Integration (Acceptance)
- **Entry State**: Database has submissions with `category_tag = 'compliance'` AND `category_tag = 'routine'`.
- **Action**: `GET /api/analytics?categoryTag=compliance`
- **Expected**: `kpis.totalAudits` = count of compliance-tagged submissions only. `routine` submissions are excluded.
- **Fail if**: Unfiltered count returned. Or `400 Bad Request` because param name changed.

### TC-02: Legacy `scoringMode` Query Param Rejected (or Ignored)
- **Type**: Integration
- **Entry State**: Any submissions in DB.
- **Action**: `GET /api/analytics?scoringMode=penalty`
- **Expected**: Param is silently ignored (no filter applied). No `500` error. `kpis.totalAudits` returns unfiltered total.
- **Fail if**: Server returns 500 because it tries to read `s.ScoringMode` (column deleted in Slice 1).

### TC-03: `scoreDirection` Replaces `scoringMode` in Scored Submissions Check
- **Type**: Integration
- **Entry State**: Submissions with `score_direction = 'none'` (surveys) and `score_direction = 'down'` (scored).
- **Action**: `GET /api/analytics`
- **Expected**: `kpis.avgScore` only averages submissions where `score_direction != 'none'`. Survey submissions excluded from average.
- **Fail if**: `avgScore` includes survey scores, or backend throws null reference on `ScoringMode`.

### TC-04: Averages Are Not Distorted
- **Type**: Integration
- **Entry State**: 2 compliance submissions (scores 80, 90). 3 routine submissions (scores 50, 60, 70).
- **Action**: `GET /api/analytics?categoryTag=compliance`
- **Expected**: `kpis.avgScore = 85.0`. Total audits = 2.
- **Fail if**: `avgScore` includes routine submissions in the average.

### TC-05: Offline Category Filter via Drift
- **Type**: Widget / Integration (Flutter)
- **Entry State**: `CachedTemplates` has rows with `categoryTag = 'compliance'` and `categoryTag = 'routine'`. `CachedSubmissions` has rows linked to each. API unreachable.
- **Action**: Set `manager.selectedCategoryTag = 'compliance'`. Call `manager.load()`.
- **Expected**: `manager.isOffline = true`. `manager.data.totalAudits` = count of submissions whose template has `categoryTag == 'compliance'`.
- **Fail if**: Offline filter is ignored and unfiltered total is returned.

---

## Test Fixture & Payloads

### Seeded Data Required
```json
// Fixture A: compliance submission
{ "id": "uuid-A", "category_tag": "compliance", "score_direction": "down", "is_weighted": true, "total_score": 85.0, "status": "completed" }
// Fixture B: routine submission
{ "id": "uuid-B", "category_tag": "routine", "score_direction": "down", "is_weighted": false, "total_score": 60.0, "status": "completed" }
// Fixture C: survey (no score)
{ "id": "uuid-C", "category_tag": "compliance", "score_direction": "none", "is_weighted": false, "total_score": null, "status": "completed" }
```

### Request
```
GET /api/analytics?categoryTag=compliance
Authorization: Bearer <admin_token>
```

### Response (excerpt)
```json
{
  "kpis": {
    "totalAudits": 2,
    "totalScored": 1,
    "totalSurveys": 1,
    "avgScore": 85.0
  },
  "categoryTagNames": ["compliance", "routine"]
}
```

---

## Tools & Commands

| Tool | Purpose |
|------|---------|
| `dotnet test` | Run `ScoringRedesignSlice5Tests.cs` (acceptance tests) |
| `flutter test lib/features/analytics/` | Run widget tests for filter chips and filter sheet |
| `flutter analyze` | Verify no Dart analyzer warnings after changes |

---

## Proposed Changes

```text
[BACKEND]  server/Features/Analytics/GetAnalytics.cs       [MOD] — replace scoringMode → categoryTag filter; fix scored/survey checks
[BACKEND]  server/Features/Analytics/Dtos.cs               [MOD] — add categoryTagNames to AnalyticsResponse
[BACKEND]  server/tests/…/ScoringRedesignSlice5Tests.cs    [NEW] — acceptance test contracts TC-01 through TC-04

[FLUTTER]  lib/features/analytics/manager/analytics_data.dart         [MOD] — add categoryTagNames list to AnalyticsData
[FLUTTER]  lib/features/analytics/manager/analytics_manager.dart      [MOD] — add selectedCategoryTag field; pass to API and drift loader
[FLUTTER]  lib/features/analytics/services/analytics_api_service.dart [MOD] — add categoryTag param to getAnalytics()
[FLUTTER]  lib/features/analytics/manager/analytics_drift_loader.dart [MOD] — add selectedCategoryTag filter via CachedTemplates
[FLUTTER]  lib/features/analytics/widgets/analytics_filter_sheet.dart [MOD] — add Category Tag dropdown
[FLUTTER]  lib/features/analytics/pages/analytics_filter_chips.dart   [MOD] — add category tag chip
[FLUTTER]  lib/features/analytics/pages/analytics_page.dart           [MOD] — increment activeFilterCount for selectedCategoryTag
```

---

## Concept Diagram

```text
OLD (Legacy — must clean):
  GET /analytics?scoringMode=penalty
    → filter s.ScoringMode == "penalty"
    → scored: s.ScoringMode != "survey"  ← broken after Slice 2

NEW (This Slice):
  GET /analytics?categoryTag=compliance
    → filter s.CategoryTag == "compliance"
    → scored: s.ScoreDirection != "none"  ← correct after Slice 2
    → response includes: categoryTagNames: ["compliance", "routine", ...]

Flutter ONLINE flow:
  manager.selectedCategoryTag = 'compliance'
  → api.getAnalytics(categoryTag: 'compliance')
  → manager.data.categoryTagNames = [...] (populates dropdown)
  → AnalyticsFilterChips shows InputChip("Category: Compliance")

Flutter OFFLINE flow:
  manager.selectedCategoryTag = 'compliance'
  → loadFromDrift(selectedCategoryTag: 'compliance')
  → load CachedTemplates where categoryTag == 'compliance'
  → extract templateIds from those templates
  → filter CachedSubmissions where templateId in those IDs
```

---

## Execution Slices

### Slice 1 (Happy Path): Backend Filter + Legacy Cleanup
**Summary**: Replace the legacy `scoringMode` query param with `categoryTag` in `GetAnalytics.cs`. Fix the two broken `ScoringMode` string checks (scored query, survey count). Add `categoryTagNames` to `AnalyticsResponse` and `Dtos.cs`.

**Value**: Without this, the filter has no backend. The `ScoringMode` references will also cause runtime errors after Slice 2 is deployed.

**Entry State Required**: Slice 1 DB migration complete. `submissions.category_tag` column exists. Slice 2 backend parser complete (`ScoringMode` removed from submission entity).

**Exit State Guaranteed**: `GET /api/analytics?categoryTag=compliance` returns only compliance submissions. `avgScore` correctly excludes surveys. `categoryTagNames` is included in the JSON response. `dotnet test` passes TC-01 through TC-04.

**Scope** (4 files):
1. `server/Features/Analytics/GetAnalytics.cs` — replace filter + fix scored/survey checks
2. `server/Features/Analytics/Dtos.cs` — add `List<string> CategoryTagNames` to `AnalyticsResponse`
3. `server/tests/…/ScoringRedesignSlice5Tests.cs` — acceptance tests (write FIRST, then build)
4. Nothing else.

**Acceptance Criteria**:
- `GET /analytics?categoryTag=compliance` → `totalAudits` = compliance-only count ✅
- `GET /analytics` (no filter) → `totalAudits` = all submissions ✅
- `GET /analytics` → `categoryTagNames` array is present in response ✅
- `avgScore` excludes submissions with `score_direction = 'none'` ✅
- No `500` from legacy `s.ScoringMode` reference ✅

**Complexity**: Medium (backend only, clear pattern mirrors existing `type` filter logic at L130-136)

---

### Slice 2 (Flutter State + API + Offline): Client Filter Integration
**Summary**: Wire `selectedCategoryTag` state into the manager, pass it to the API service, and add offline filter logic to the Drift loader. Add `categoryTagNames` to `AnalyticsData`.

**Value**: Without this, the Flutter UI has no way to send or apply the category tag filter.

**Entry State Required**: Slice 1 (backend) complete and green. Slice 4 (CachedTemplates.categoryTag) complete — Drift schema has the column.

**Exit State Guaranteed**: `manager.selectedCategoryTag = 'compliance'; manager.load()` → correctly fetches filtered data online AND filters offline from Drift cache. `flutter test` passes TC-05.

**Scope** (4 files):
1. `lib/features/analytics/manager/analytics_data.dart` — add `categoryTagNames` list
2. `lib/features/analytics/manager/analytics_manager.dart` — add `selectedCategoryTag`; pass to API and drift loader; parse `categoryTagNames` from JSON response
3. `lib/features/analytics/services/analytics_api_service.dart` — add `categoryTag` param
4. `lib/features/analytics/manager/analytics_drift_loader.dart` — add `selectedCategoryTag` filter

**Acceptance Criteria**:
- `manager.selectedCategoryTag = 'compliance'` → API receives `?categoryTag=compliance` ✅
- Offline: submissions filtered to those whose templateId matches compliance templates ✅
- `manager.data.categoryTagNames` populated from API response ✅

**Complexity**: Low-Medium (follows identical pattern as existing `selectedType` filter wiring)

---

### Slice 3 (Visual Resiliency): Filter Sheet + Chip UI
**Summary**: Add the Category Tag dropdown to `AnalyticsFilterSheet`, add the dismissible chip to `AnalyticsFilterChips`, and increment `_activeFilterCount` in `analytics_page.dart`.

**Value**: Without this, the filter exists in state but the user has no way to interact with it.

**Entry State Required**: Slice 2 complete.

**Exit State Guaranteed**: User opens filter sheet → Category Tag dropdown visible with populated options from `manager.data.categoryTagNames`. User selects a tag → chip appears in chip bar, filter count increments, KPIs update. User deletes chip → filter resets. `flutter test lib/features/analytics/` green.

**Scope** (3 files):
1. `lib/features/analytics/widgets/analytics_filter_sheet.dart` — add Category Tag dropdown (mirrors Province/Store/Type pattern)
2. `lib/features/analytics/pages/analytics_filter_chips.dart` — add dismissible `InputChip` for category tag
3. `lib/features/analytics/pages/analytics_page.dart` — add `if (_manager.selectedCategoryTag != null) count++`

**Acceptance Criteria**:
- Category Tag dropdown appears in filter sheet ✅
- Options populated from `manager.data.categoryTagNames` (no hardcoded values) ✅
- Selecting "Compliance" → `InputChip("Category: Compliance")` appears in chip bar ✅
- Tapping chip × → filter cleared, `manager.load()` called ✅
- `activeFilterCount` includes the category tag ✅
- Empty state shows when `selectedCategoryTag` returns zero audits ✅

**Complexity**: Low (pure UI extension; follows existing `Province/Store/Auditor` chip pattern exactly)

---

<command_logs>
- list_dir: lib/features/analytics — found manager/, pages/, services/, utils/, widgets/
- view_file: analytics_filter_chips.dart — 155 lines, 6 filter chips (province, store, type, auditor, status, reviewStatus)
- view_file: analytics_manager.dart — 210 lines; filter state: selectedStore/Type/Province/Auditor/Status/ReviewStatus
- view_file: analytics_data.dart — 96 lines; AnalyticsData has storeNames, templateTypes, provinceNames, auditorNames (no categoryTagNames)
- view_file: analytics_drift_loader.dart — 190 lines; filters by selectedType via templateId lookup; same pattern needed for categoryTag
- view_file: analytics_api_service.dart — 26 lines; getAnalytics() params: storeId, province, startDate, endDate (no categoryTag)
- view_file: analytics_filter_sheet.dart — 190 lines; dropdowns for Province, Store, Audit Type, Auditor, Status, Review Status (no Category Tag)
- view_file: analytics_page.dart — 99 lines; _activeFilterCount counts 6 filters (selectedCategoryTag missing)
- view_file: GetAnalytics.cs L1-268 — CRITICAL: L22 reads scoringMode param (legacy); L139-140 filters on ScoringMode (legacy); L152 scored check on ScoringMode (legacy bug); L159 survey check on ScoringMode (legacy bug)
- view_file: Dtos.cs (analytics) — AnalyticsResponse lacks categoryTagNames
- grep_search: category_tag in server/ — confirmed DB migration exists; column on Submission entity mapped
</command_logs>

---

## Handoff Block

**Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\scoring_redesign\implementation_plan_20260530_113700_slice5_analytics_dashboard_cdefadc1.md`

**Task Tracker**: `C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\scoring_redesign\task_20260530_113700_slice5_analytics_dashboard_cdefadc1.md`

### Execute ONE slice at a time:

- **Slice 1 (Backend)** [Risk: Network/Database] → Write Acceptance Tests → Build
  - Files: `GetAnalytics.cs`, `Dtos.cs`, `ScoringRedesignSlice5Tests.cs`
  - Command: `rtk dotnet test`

- **Slice 2 (Flutter State + API)** [Risk: Internal Logic] → Write Unit Tests → Build
  - Files: `analytics_data.dart`, `analytics_manager.dart`, `analytics_api_service.dart`, `analytics_drift_loader.dart`
  - Command: `rtk flutter test lib/features/analytics/`

- **Slice 3 (UI)** [Risk: Visual] → Build only
  - Files: `analytics_filter_sheet.dart`, `analytics_filter_chips.dart`, `analytics_page.dart`
  - Command: `rtk flutter test lib/features/analytics/` + `rtk flutter analyze`

> [!IMPORTANT]
> Do NOT begin Slice 2 until `dotnet test` is fully green after Slice 1.
> Do NOT begin Slice 3 until `flutter test` is green after Slice 2.
