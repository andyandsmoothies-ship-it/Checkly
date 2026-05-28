<latent_space_scratchpad>
CORE FINDING: The archetype filter must be applied in TWO separate code paths:
  PATH A: BodReportCalculator.cs (nightly job snapshot) — Query 3, lines 224-256
  PATH B: GetBodReport.cs (live province-filtered path) — regional leaderboard, lines 187-203

The JOIN strategy:
  - Submission.TemplateId (Guid?) → Template.Type (string)
  - Submission already has a Template navigation property (L59 in Submission.cs)
  - No foreign key index on submissions.template_id confirmed — add index recommendation to plan

The TWO PATHS have different execution contexts:
  - PATH A: BodReportCalculator.cs → uses EF Core LINQ against AppDbContext. Joins Templates table via LINQ Join.
  - PATH B: GetBodReport.cs → already loads submissionsLast30Days into memory (L55-64), then does regional breakdown from DB. Regional leaderboard (L187-203) queries DB directly.

APPROACH: For both paths, add a .Join() or .Where(s => s.Template.Type == "QC") using the existing navigation property.
  - PATH A: Add .Join(db.Templates, ...) or use .Where(s => s.TemplateId.HasValue && db.Templates.Any(t => t.Id == s.TemplateId.Value && t.Type == "QC"))
  - Cleaner: .Where(s => s.Template != null && s.Template.Type == "QC") — but requires Include() for EF to load nav
  - Cleanest/most DB-efficient: .Join(db.Templates, s => s.TemplateId, t => t.Id, (s, t) => new { s, t.Type }).Where(x => x.Type == "QC")

CRITICAL EDGE CASE: 
  - Submissions where TemplateId IS NULL: These would be excluded from the JOIN entirely (inner join semantics).
  - Submissions where Template.Type is null or unknown: Use defensive fallback "QC" as the default.
  - Decision: Use LEFT JOIN semantics with WHERE (t.Type == "QC" OR s.TemplateId == null). 
    This ensures: if template is deleted or missing, submission falls into ScoredAudit bucket (majority case, as per epic analysis).
  - Actually the epic says: "if Type is null or unknown, treat as ScoredAudit (the majority case)"
    So the filter should INCLUDE submissions where TemplateId is null OR Template.Type == "QC".

FILE LIMIT WARNING:
  - BodReportCalculator.cs is 419 lines — EXCEEDS 400 line limit.
  - GetBodReport.cs is 439 lines — EXCEEDS 400 line limit.
  - Plan MUST include file splitting as prerequisite. However, splitting 400-line files while adding a filter in the same slice would be 2 concerns. Strategy: The filter addition is MINIMAL (3-5 lines per path). The splitting is a separate refactor concern. Plan notes the risk, directs Builder to add the WHERE guard only and flag splitting for next cleanup cycle. This is the safer approach — don't refactor + feature in the same slice.

INDEX FINDING:
  - No HasIndex on submissions.template_id found in AppDbContext config.
  - Query 3 adds a JOIN on submissions.template_id → templates.id. This adds a potential full-scan risk if table is large.
  - Recommendation: The plan must note that submissions.template_id should have an index. No migration needed just for an index (EF HasIndex doesn't require schema change unless column is new).
  - Actually, EF index IS a migration change. The column already exists (from CreateSubmission seeder — TemplateId is already set). We just add an index. This requires a migration.
  - DECISION: Document the index risk but do NOT add a migration in Slice 1. Monitor query performance. Index can be added as a follow-up.

AvgTtrDays SCOPE CLARIFICATION:
  - AvgTtrDays is NOT computed in BodReportCalculator.cs. Default is 0m in DTO.
  - It IS computed in GetBodReport.cs (live province path, L113-127).
  - The epic says "AvgTtrDays is already in BodChainKpis" — confirmed, but only populated on live path.
  - Scope of Slice 1: We are ONLY adding the archetype filter to the leaderboard query. Not promoting AvgTtrDays to nightly snapshot. That's Slice 2 (Flutter KPI promotion work).

OUT OF SCOPE FOR SLICE 1:
  - AvgTtrDays computation in nightly snapshot
  - Database migration (index on template_id)
  - Flutter UI changes
  - Category Weaknesses archetype filter (not in scope per epic)
</latent_space_scratchpad>

# Implementation Plan: Golden Metrics MVP — Slice 1 (Backend Archetype Filter Gate)

**Date**: 2026-05-28 | **ConvID**: cdefadc1-bcb6-48a6-b2df-d50ea610949f  
**Pattern**: Data Pipeline Filter Gate — Additive WHERE Clause on Existing JOIN  
**Workflow**: /analyze-feature | **Track**: B2 (Route 3: Acceptance Tests First)

---

## Input Lineage

- **Epic Analysis**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\analysis_epic_20260528_162900_c3563378_golden-metrics-mvp_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

## Executive Summary & Out of Scope

**Goal**: Add an Archetype Filter Gate to the BOD Store Leaderboard so that only `QC`-type template submissions enter the Top/Bottom store ranking. This prevents mathematically invalid score mixing between Scored Audits and Task Campaign submissions.

```
[Nightly BodReportCalculator]               [Live GetBodReport — province path]
  Query 3: Store Leaderboard                  Regional Leaderboard Query
  + JOIN Templates ON TemplateId             + JOIN Templates ON TemplateId
  + WHERE Type = 'QC'                        + WHERE Type = 'QC'
       │                                           │
       ▼                                           ▼
  Snapshot JSON (stored in bod_report_snapshots)   HTTP Response (60s cache)
```

**Key Facts from Code Research:**
- `Submission.TemplateId` (Guid?) → `Template.Type` (string: `'QC'`, `'Training'`, `'General'`).
- `Submission` has a `Template` navigation property already declared (L59, `Submission.cs`).
- Query 3 in `BodReportCalculator.cs` is at lines 224–256. It does NOT currently join Templates.
- The regional leaderboard query in `GetBodReport.cs` is at lines 187–203. It also does NOT currently join Templates.
- **Critical Discovery**: `AvgTtrDays` is NOT calculated in `BodReportCalculator.cs`. It is only computed in `GetBodReport.cs` (live path). Nightly snapshot currently returns `avgTtrDays: 0`. This is out of scope for Slice 1.

**Out of Scope — YAGNI:**
- ❌ Database migration (index on `submissions.template_id` — monitor first, add later).
- ❌ Category Weaknesses archetype filter.
- ❌ Flutter KPI card changes (Slice 2).
- ❌ `AvgTtrDays` computation in nightly snapshot (Slice 2).
- ❌ Date-range filter API on `GET /api/analytics/bod` (Cancelled — MVP out of scope).
- ❌ Tap-to-Filter charts gesture (Cancelled — MVP out of scope).
- ❌ File splitting for `BodReportCalculator.cs` and `GetBodReport.cs` (both exceed 400 lines — flagged for next cleanup cycle, NOT in this slice).

---

## System Context

| Dimension | Value |
| :--- | :--- |
| **Offline/Online** | Nightly snapshot is offline-computed. Live filtered path is online. Both must be guarded. |
| **RBAC** | BOD is `analytics:bod` capability — admin only. No RBAC change. |
| **API Contract** | `BodChainKpis` DTO already has `AvgTtrDays = 0m` default. `BodStoreRankEntry` DTO unchanged. |
| **Sync** | No Flutter sync change. Shape A — no new DB column. |
| **Performance Risk** | JOIN on `submissions.template_id` with no existing index. Acceptable for MVP at current data volume. Monitor via query plan after deploy. |
| **Index Status** | `submissions.template_id` has NO explicit EF index configured. Document risk; defer index migration to follow-up. |

---

## Lifecycle Context — 4-State Matrix

| State | Behavior |
| :--- | :--- |
| **Success** | Leaderboard returns only stores with `QC` template submissions. `topStores`/`bottomStores` arrays contain entries with `AvgScore` from scored audits only. |
| **Loading** | Nightly job — async; no UI loading state. Live path: 60s cache; downstream Flutter shows shimmer (Slice 2 scope). |
| **Error** | If Query 3 JOIN fails, `BodReportCalculator` catches the exception and sets `LastRunStatus = "PartiallyFailed"`. `topStores` and `bottomStores` are set to `null` in the payload. Existing error path — NO CHANGE. |
| **Empty** | If a chain has zero `QC`-type submissions in the last 30 days, `topStores` and `bottomStores` return empty arrays `[]` (not null). The Flutter frontend must render "No scored audits found" empty state. |

---

## Constraint Traceability

| Constraint (from Epic) | Source | Test Contract ID |
| :--- | :--- | :--- |
| R1 — Prevent mathematically invalid mixing across template types | Epic Analysis | TC-S1-01 |
| R3 — Leaderboard comparisons only within same archetype (QC) | Epic Analysis | TC-S1-02 |
| R4 — Dashboard loads in <50ms (nightly snapshot path) | Epic Analysis | TC-S1-03 (structural) |
| Defensive fallback: if Type is null/unknown, treat as ScoredAudit | Epic Risk Table | TC-S1-04 |
| PartiallyFailed status preserved if query throws | Existing pattern | TC-S1-05 |
| `submissions.template_id` may be NULL (optional FK) | Code review | TC-S1-06 |

---

## Test Contracts

| ID | Description | Approach | Fail Reason |
| :--- | :--- | :--- | :--- |
| **TC-S1-01** | Store with `QC` template submissions appears in leaderboard | Seed 1 `QC` submission + 1 `General` submission for separate stores; call nightly calculator; assert only QC store is in `topStores` | General store leaks into scored leaderboard |
| **TC-S1-02** | Store with `General` template submission is excluded from leaderboard | Same seed as TC-S1-01; assert `bottomStores` does not contain the General store | No filter applied — General store appears |
| **TC-S1-03** | Leaderboard returns empty array (not null) when no QC submissions exist | Seed only General submissions; run calculator; assert `topStores == []` | Returns null instead of empty array — Flutter null-crashes |
| **TC-S1-04** | Store with submission where TemplateId is NULL is included in leaderboard (fallback = ScoredAudit) | Seed a submission with `TemplateId = null`, `TotalScore = 80`; run calculator; assert it appears in `topStores` | NULL TemplateId excluded — regression for legacy submissions |
| **TC-S1-05** | PartiallyFailed preserved when query throws | Existing test `RunNightlyJobAsync_OneQueryFails_SavesWithPartiallyFailedStatus` — must still pass after filter added | Test breaks due to filter change |
| **TC-S1-06** | Live province-filtered path also excludes General template stores from leaderboard | Seed General + QC stores in same province; call `GET /api/analytics/bod?province=X`; assert only QC store in `topStores` | Filter applied to nightly but not live path |

---

## Test Fixture & Payloads

### Required Seeder State (for TC-S1-01, TC-S1-02, TC-S1-06)

```csharp
// Template: QC type (scored audits)
var templateQc = new Template { Id = Guid.NewGuid(), Title = "QC Audit Template", Type = "QC", IsActive = true, Version = 1, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

// Template: General type (task campaigns)
var templateGeneral = new Template { Id = Guid.NewGuid(), Title = "General Task Template", Type = "General", IsActive = true, Version = 1, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

// Store A — linked to QC submission
var storeA = new Store { Id = Guid.NewGuid(), Name = $"QC Store {Guid.NewGuid():N}", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

// Store B — linked to General submission
var storeB = new Store { Id = Guid.NewGuid(), Name = $"General Store {Guid.NewGuid():N}", CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow };

// Submission for Store A — QC type, scored
var submA = new Submission
{
    Id = Guid.NewGuid(), StoreId = storeA.Id, TemplateId = templateQc.Id,
    Status = "completed", ScoringMode = "penalty",
    TotalScore = 85.0m, TemplateType = "QC",
    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2), UpdatedAt = DateTimeOffset.UtcNow
};

// Submission for Store B — General type, completion-only
var submB = new Submission
{
    Id = Guid.NewGuid(), StoreId = storeB.Id, TemplateId = templateGeneral.Id,
    Status = "completed", ScoringMode = "penalty",
    TotalScore = 92.0m, TemplateType = "General",
    CompletedAt = DateTimeOffset.UtcNow.AddHours(-1),
    CreatedAt = DateTimeOffset.UtcNow.AddHours(-2), UpdatedAt = DateTimeOffset.UtcNow
};
```

> [!NOTE]
> Both submissions must have `CompletedAt` within the last 30 days to appear in Query 3's time window. Use `DateTimeOffset.UtcNow.AddHours(-1)`.

### Expected API Response Shape (TC-S1-01)

After running `BodReportCalculator.ComputeDailyReportWithTimezoneAsync(db, today, null, ct)`:

```json
{
  "topStores": [
    { "storeId": "<storeA.Id>", "storeName": "QC Store ...", "avgScore": 85.0 }
  ],
  "bottomStores": [
    { "storeId": "<storeA.Id>", "storeName": "QC Store ...", "avgScore": 85.0 }
  ]
}
```

**Assert**: `topStores` does NOT contain any entry with `storeId == storeB.Id`.

---

## Tools & Commands

| Tool | Purpose |
| :--- | :--- |
| `testing-strategy` skill | Mandatory — test project setup and xUnit v3 patterns |
| `tdd` skill | Acceptance test authoring style |
| `ef-core` skill | LINQ Join pattern for navigation property join |

**Test Command**:
```
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~BodAnalytics"
```

**Full Suite (regression check)**:
```
rtk dotnet test server/tests/Checkly.Api.Tests/Checkly.Api.Tests.csproj --filter "FullyQualifiedName~BodReport"
```

---

## Proposed Changes

> ⚠️ **File Limit Warning**: `BodReportCalculator.cs` (419 lines) and `GetBodReport.cs` (439 lines) both exceed the 400-line limit. File splitting is a technical debt item but is OUT OF SCOPE for this slice. The change in this slice is additive (3–5 lines each file). A dedicated cleanup slice should split these files in the next session.

| # | Action | File | Change |
| :--- | :--- | :--- | :--- |
| 1 | `[MOD]` | `server/tests/Checkly.Api.Tests/Features/Analytics/BodAnalyticsFilteredEndpointTests.cs` | Add 3 new test methods: TC-S1-01, TC-S1-02, TC-S1-06 |
| 2 | `[NEW]` | `server/tests/Checkly.Api.Tests/Features/Analytics/BodReportCalculatorArchetypeTests.cs` | New test class: TC-S1-03, TC-S1-04 (unit-style, using direct BodReportCalculator + real DB) |
| 3 | `[MOD]` | `server/Features/Analytics/BodReportCalculator.cs` | Modify Query 3 (lines 224–242) — add JOIN to Templates, add WHERE `t.Type == "QC" OR s.TemplateId == null` |
| 4 | `[MOD]` | `server/Features/Analytics/GetBodReport.cs` | Modify regional leaderboard query (lines 187–203) — add same JOIN + WHERE archetype guard |

**Sequential Build Order**: `[1, 2]` → RED tests → `[3]` → GREEN → `[4]` → GREEN on TC-S1-06.

---

## Concept Diagram

```
[BodReportCalculator.cs — Query 3]          [GetBodReport.cs — regional leaderboard]
         │                                              │
  db.Submissions                                db.Submissions
    .Where(s => completed, not-rejected...)       .Where(s => completed, not-rejected...)
    + .Join(db.Templates,                         + .Join(db.Templates,
        s => s.TemplateId,                            s => s.TemplateId,
        t => t.Id,                                    t => t.Id,
        (s, t) => new { s, t.Type })                  (s, t) => new { s, t.Type })
    + .Where(x => x.Type == "QC"                  + .Where(x => x.Type == "QC"
               || x.s.TemplateId == null)                      || x.s.TemplateId == null)
    .GroupBy(StoreId)                             .GroupBy(StoreId)
    .ToListAsync()                                .ToListAsync()
         │                                              │
         ▼                                              ▼
  topStores / bottomStores                      topStoresList / bottomStoresList
  (ScoredAudit-only)                            (ScoredAudit-only)
```

---

## Execution Slices

### Slice 1-A: Write Failing Acceptance Tests `[BLOCKING — must go RED first]`

**Summary**: Write the acceptance tests in `BodAnalyticsFilteredEndpointTests.cs` and new `BodReportCalculatorArchetypeTests.cs` that assert the archetype filter behavior. These tests must fail before any production code is changed.

**Value**: Proves the gap. Defines the exact contract the Builder must fulfill.

**Entry State**: Production code unchanged (no archetype filter in Query 3).  
**Exit State**: Tests compile but FAIL with correct assertion messages showing General store appears where it shouldn't.

**Scope**:
- `[MOD]` `BodAnalyticsFilteredEndpointTests.cs` — Add TC-S1-01, TC-S1-02, TC-S1-06
- `[NEW]` `BodReportCalculatorArchetypeTests.cs` — Add TC-S1-03, TC-S1-04

**Acceptance Criteria**:
- [ ] TC-S1-01: `Assert.DoesNotContain(storeB.Id, topStores)` — FAILS (General store leaks in).
- [ ] TC-S1-02: Same seed — General store appears in `bottomStores` — FAILS.
- [ ] TC-S1-03: Empty result — calculator returns `topStores == []` — PASSES already (no QC data = empty).
- [ ] TC-S1-04: NULL TemplateId submission — does NOT crash, IS included — verify behavior.
- [ ] TC-S1-06: Province-filtered live path — FAILS (General store leaks into regional leaderboard).

**Complexity**: Medium — 3 files, seeder with Template entity, two test classes.

---

### Slice 1-B: Implement Archetype Filter in Production Code `[SEQUENTIAL after 1-A is RED]`

**Summary**: Modify Query 3 in `BodReportCalculator.cs` and the regional leaderboard query in `GetBodReport.cs` to add the archetype JOIN + WHERE guard.

**Value**: Makes all RED tests GREEN. Prevents mathematically invalid cross-template score mixing in both the nightly snapshot and the live province-filtered path.

**Entry State**: All Slice 1-A tests are failing (RED).  
**Exit State**: All Slice 1-A tests pass (GREEN). Existing `BodReport` tests still pass (no regression).

**Scope**:
- `[MOD]` `server/Features/Analytics/BodReportCalculator.cs` — Query 3 only (lines 224–242)
- `[MOD]` `server/Features/Analytics/GetBodReport.cs` — Regional leaderboard (lines 187–203)

**LINQ Pattern to Use** (in Query 3):
```
db.Submissions.AsNoTracking()
    .Where(... existing filters ...)
    .Join(
        db.Templates,
        s => s.TemplateId,
        t => t.Id,
        (s, t) => new { Submission = s, TemplateType = t.Type }
    )
    .Where(x => x.TemplateType == "QC")
    // PLUS: handle TemplateId == null via left join alternative
    .Select(x => x.Submission)
    ...
```

> [!WARNING]
> The LINQ inner JOIN excludes all submissions with `TemplateId == null`. To implement the defensive fallback, use a UNION pattern or a LEFT JOIN with DefaultIfEmpty. Preferred: filter submissions into two groups (null TemplateId OR QC type) using a subquery:
> ```
> .Where(s => s.TemplateId == null || db.Templates.Any(t => t.Id == s.TemplateId && t.Type == "QC"))
> ```
> This translates to a correlated subquery in PostgreSQL. Performance acceptable at MVP scale. Builder must verify via EF Core SQL logging.

**Acceptance Criteria**:
- [ ] All 6 test contracts pass (GREEN).
- [ ] `dotnet test --filter BodReport` full suite passes with zero regressions.
- [ ] `LastRunStatus = "PartiallyFailed"` test still passes.

**Complexity**: Low — 2 files, 3–5 lines change each.

---

<command_logs>
- grep_search: BodAnalyticsFilter in server/ → Found BodAnalyticsFilteredEndpointTests.cs (409 lines, 4 tests)
- view_file: BodAnalyticsFilteredEndpointTests.cs → Confirmed test patterns, seeder style, no Template entity seeded
- grep_search: TemplateId in server/Common → Found Submission.TemplateId (Guid?, L13), Template.Id navigation declared L59
- view_file: Template.cs → Confirmed Type: string ('QC', 'Training', 'General'), L13
- view_file: Submission.cs → Confirmed TemplateId (Guid?, L13), Template nav property (L59), TemplateType snapshot field (L38)
- view_file: BodReportCalculator.cs (419 lines) → Query 3 (lines 224-256), no Templates join, ScoringMode != survey guard
- view_file: BodReportDtos.cs → BodChainKpis has AvgTtrDays = 0m default, BodStoreRankEntry has LastSyncedAt
- view_file: BodReportWorkerTests.cs → FakeFailingBodReportCalculator pattern, test seeder style
- view_file: GetBodReport.cs (439 lines) → AvgTtrDays computed L113-127, regional leaderboard L187-203
- grep_search: HasIndex TemplateId in Common/Persistence → No results (no index configured)
- grep_search: AvgTtrDays in server/ → Only in GetBodReport.cs (live path) and BodReportDtos.cs (default 0m)
- grep_search: class Bod in tests/ → BodReportWorkerTests.cs only (BodAnalyticsFilteredEndpointTests is class-based)
</command_logs>

---

## Handoff Block

**Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\implementation_plan_20260528_193050_golden-metrics-slice1_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

**Route**: **Route 3 — Acceptance Tests First** (uses Database, new JOIN pattern, medium testing risk).

### Execute ONE AT A TIME:

1. **Slice 1-A (Write RED Tests)**: QA Agent writes TC-S1-01 to TC-S1-06 into `BodAnalyticsFilteredEndpointTests.cs` and new `BodReportCalculatorArchetypeTests.cs`. Run `dotnet test --filter BodAnalytics` and confirm FAIL (RED).

2. **Slice 1-B (Build Filter Gate)**: Builder modifies `BodReportCalculator.cs` Query 3 + `GetBodReport.cs` regional leaderboard. Run `dotnet test --filter "BodAnalytics|BodReport"` and confirm all GREEN. Verify `BodReportWorkerTests` suite has zero regressions.

> Do NOT run Slice 1-B until Slice 1-A is confirmed RED.

> [!IMPORTANT]
> `[PRODUCTION_LOCK]` — Scout does not write production code. Hand this plan to the Builder agent (or QA Sentinel for Slice 1-A). Plan is ready for execution.
