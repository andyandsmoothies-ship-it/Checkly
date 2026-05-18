<latent_space_scratchpad>
## Constraints from Epic (Slice 2)

C1 — AnalyticsResponse DTO extended with 3 new fields: `List<ActionableInsight> Insights`, `RadarData? RadarData`, `bool InsightsStale`.
C2 — New DTO: `ActionableInsight(string Id, string Type, string Text, string? ActionRoute)`. Type values: "warning" | "info" | "positive".
C3 — New DTO: `RadarData` — wraps CategoryAverages for Store vs Area polygon. Fields: `Dictionary<string, double> StoreAverages`, `Dictionary<string, double> AreaAverages`.
C4 — InsightGeneratorService is a STATIC CLASS — receives only primitives (no AppDbContext, no HttpContext, no PBAC).
C5 — Sparsity guard: if totalAudits30d < 3 → return single info insight "Complete 3 audits to unlock insights", no RadarData.
C6 — Stale guard: if AreaBenchmarkSnapshot.LastCalculatedAt < UtcNow - 2h → set InsightsStale=true.
C7 — Max 3 insights returned (slice first 3 if generator produces more).
C8 — GetAnalytics.HandleAsync extended to: read AreaBenchmarkSnapshot for caller's area, call InsightGeneratorService, return extended AnalyticsResponse.
C9 — PBAC: Insights returned to all roles who pass analytics:view. The endpoint resolves areaId from profile (already done for area_manager). For store_manager: area comes from Store.AreaId. For admin/auditor: areaId from query param.
C10 — Backward compat: Existing fields (kpis, trend, sectionBreakdown) unchanged.

## Critical Code Facts
- AnalyticsResponse is a POSITIONAL RECORD. Line 189 in GetAnalytics.cs: `new AnalyticsResponse(kpis, trend, sectionBreakdown)` — MUST update this call.
- `AreaBenchmarkSnapshot.CategoryAverages` is stored as JSON string → must deserialize to `Dictionary<string, double>`.
- GetAnalytics.cs is 195 lines. Adding insight block adds ~25 lines → will reach 220 lines. File stays under 250 — no split required.
- Dtos.cs is 28 lines → adding ~15 lines → 43 lines. Fine.

## Insight Rules for InsightGeneratorService
Rule 1 (SCORE_DROP_WARNING): liveScore < areaAvg - (1.5 * stdDev)
  → Type="warning", Id="ins_score_drop", Text="Your score is significantly below the regional average."

Rule 2 (SCORE_POSITIVE): liveScore > areaAvg + stdDev
  → Type="positive", Id="ins_top_performer", Text="You're outperforming your region — keep it up!"

Rule 3 (CATEGORY_WEAK): find category where storeRatio < areaRatio - 10
  → Type="warning", Id="ins_cat_weak_{categoryName}", Text="{Category} is your weakest area vs region."

Rule 4 (CATEGORY_STRONG): find category where storeRatio > areaRatio + 10
  → Type="positive", Id="ins_cat_strong_{categoryName}", Text="{Category} is your strongest area."

Rule 5 (OAP_HIGH): overdueAPs > 0
  → Type="warning", Id="ins_oap_high", Text="{N} action plan(s) are overdue."

All rules produce IEnumerable<ActionableInsight>. Generator collects all, returns .Take(3).ToList().

## RadarData
- StoreAverages: from sectionBreakdown (already in response, re-use projected list)
- AreaAverages: from AreaBenchmarkSnapshot.CategoryAverages deserialized
- Suppress if either dict has < 3 keys.

## File Impact
- [MOD] Dtos.cs — add 3 new records + extend AnalyticsResponse (28 → ~50 lines)
- [NEW] InsightGeneratorService.cs — static class, pure logic
- [MOD] GetAnalytics.cs — add insight block at bottom before return (195 → ~230 lines)
- [NEW] InsightGeneratorTests.cs — UNIT tests for pure logic (no DB)
- [NEW] InsightsIntegrationTests.cs — integration tests for HTTP endpoint
Total = 5 files. Acceptable in one phase.

## Test Contracts
IG-01: Store with 2 audits → Insights has 1 "info" item, RadarData=null, InsightsStale=false
IG-02: Store with 5 audits, score >> area avg → "positive" insight returned
IG-03: Store with 5 audits, score << area avg → "warning" insight returned  
IG-04: Stale benchmark (LastCalculatedAt = 3h ago) → InsightsStale=true
IG-05: No AreaBenchmarkSnapshot row → Insights=[], RadarData=null, InsightsStale=false (graceful)
IG-06: RadarData.StoreAverages and AreaAverages both populated when benchmark exists
IG-07: AnalyticsResponse still has kpis, trend, sectionBreakdown (backward compat — AC-S2.1 must still pass)
IG-08: Max 3 insights even when 5 rules fire
</latent_space_scratchpad>

# Implementation Plan: Slice 2 — InsightGeneratorService & DTO Extension

## Input Lineage
- **Epic**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\analysis_epic_20260517_153008_EPIC1_reporting.md`
- **Slice 1 Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260517_162900_SL1_area_benchmark.md`
- **Slice 0 Plan**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260517_160000_SL0_analytics_rewire.md`

---

## Executive Summary & Out of Scope

**Goal:** Wire the pre-computed `AreaBenchmarkSnapshot` (from Slice 1) into the `GET /api/analytics` response by adding an `InsightGeneratorService` (pure static domain class) and three new fields to `AnalyticsResponse`. The endpoint resolves the caller's area, reads the benchmark row, generates insights, and returns an enriched response — backward compatible.

**Delivers:**
- `InsightGeneratorService` — static class, 5 heuristic rules, no DB/PBAC coupling
- `RadarData` DTO — store vs area polygon data for the Flutter `RadarChart`
- `ActionableInsight` DTO — ID, type, text, optional route
- Extended `AnalyticsResponse` — 3 new additive fields
- Extended `GetAnalytics.HandleAsync` — reads benchmark, calls generator

**Out of Scope (YAGNI):**
- Flutter Insight Cards widget — Slice 3
- Flutter RadarChart widget — Slice 3  
- `GetAreaLeaderboard`, `GetMyStats`, `GetTopFailures` — unchanged
- No new EF migrations (table exists from Slice 1)
- No new NuGet packages

> [!WARNING]
> **Positional record constructor risk:** `AnalyticsResponse` is a positional record. Adding fields changes the constructor signature. The only call site is `GetAnalytics.cs` line 189. That line MUST be updated in the same commit or the build breaks.

---

## System Context

| Dimension | Details |
|---|---|
| **RBAC / PBAC** | `analytics:view` gate is unchanged. Domain layer receives `Guid? areaId` only — no roles. |
| **Online / Offline** | Server-side only. No Flutter changes in this slice. |
| **Area Resolution** | `store_manager`: area comes from `Store.AreaId` (requires joining Store). `area_manager`: already in `areaIdStr`. `admin/auditor`: from query param `?areaId=`. |
| **Stale Threshold** | `LastCalculatedAt < UtcNow - 2h` → `InsightsStale = true`. |
| **Sparsity Guard** | `totalAudits30d < 3` OR no benchmark row → return single info insight, `RadarData = null`. |

---

## Lifecycle Context

| State | API Response |
|---|---|
| **Success (≥ 3 audits, fresh benchmark)** | `insights` = 1–3 items, `radarData` = store vs area polygon, `insightsStale = false` |
| **Sparse (< 3 audits)** | `insights = [{type:"info", text:"Complete 3 audits to unlock insights..."}]`, `radarData = null` |
| **No benchmark row** | `insights = []`, `radarData = null`, `insightsStale = false` (graceful) |
| **Stale benchmark (> 2h)** | Normal insights + `insightsStale = true` |
| **No area context** | No insight data resolved; `insights = []`, `radarData = null` |

---

## Constraint Traceability

| ID | Constraint (from Epic) | Test Contract |
|---|---|---|
| C1 | `AnalyticsResponse` extended with `Insights`, `RadarData`, `InsightsStale` | IG-07 |
| C2 | `ActionableInsight(Id, Type, Text, ActionRoute?)` — type is "warning"/"info"/"positive" | IG-02, IG-03 |
| C3 | `RadarData` holds store + area category averages | IG-06 |
| C4 | `InsightGeneratorService` is static, no AppDbContext/HttpContext | (structural — compile check) |
| C5 | Sparsity guard: < 3 audits → single info insight, null RadarData | IG-01 |
| C6 | Stale guard: `LastCalculatedAt` > 2h → `InsightsStale = true` | IG-04 |
| C7 | Max 3 insights | IG-08 |
| C8 | `GetAnalytics` reads benchmark, calls generator | IG-02, IG-03, IG-05 |
| C9 | All roles with analytics:view get insights | IG-02 (admin client) |
| C10 | Existing `kpis`, `trend`, `sectionBreakdown` fields backward-compat | IG-07 |

---

## Test Contracts

| ID | Scenario | Required State | Why RED First |
|---|---|---|---|
| **IG-01** | Store with 2 audits → 1 "info" insight, RadarData=null | Store + benchmark row with TotalAuditCount=2 | `Insights` field doesn't exist on DTO |
| **IG-02** | Store score >> area avg → "positive" insight in list | Benchmark + store with high TotalScore | `InsightGeneratorService` doesn't exist |
| **IG-03** | Store score << area avg → "warning" insight in list | Benchmark + store with low TotalScore | `InsightGeneratorService` doesn't exist |
| **IG-04** | `LastCalculatedAt` = 3h ago → `insightsStale=true` | Benchmark row with old timestamp | `InsightsStale` field doesn't exist |
| **IG-05** | No benchmark row → `insights=[]`, `radarData=null` | Store with audits, no benchmark row | `Insights` field doesn't exist |
| **IG-06** | RadarData populated with store + area keys | Benchmark row + section score data | `RadarData` DTO doesn't exist |
| **IG-07** | Existing `kpis`, `trend`, `sectionBreakdown` still present | Any | Positional constructor change breaks build |
| **IG-08** | All 5 rules fire → only 3 insights returned | Constructed scenario | `InsightGeneratorService.Generate()` doesn't exist |

---

## Test Fixture & Payloads

### Unit Tests: `InsightGeneratorTests.cs`
Pure C# — no DB, no HTTP client. Calls `InsightGeneratorService.Generate()` directly.

```csharp
// Fixture: Store below regional avg by 2 standard deviations
var result = InsightGeneratorService.Generate(
    liveScore: 55.0,
    areaAvgScore: 80.0,
    stdDeviation: 10.0,
    totalAudits: 5,
    storeCategoryAverages: new() { ["Safety"] = 60.0 },
    areaCategoryAverages: new() { ["Safety"] = 80.0 },
    overdueAPs: 2
);
// Assert: result.Insights has ≥1 warning, result.RadarData != null
```

### Integration Tests: `InsightsIntegrationTests.cs`
Uses `TestWebApplicationFactory`. Seeds data via EF directly, calls `GET /api/analytics`.

```json
// Expected response shape
{
  "kpis": { "totalAudits": 5, "avgScore": 55.0, ... },
  "trend": [...],
  "sectionBreakdown": [...],
  "insights": [
    { "id": "ins_score_drop", "type": "warning", "text": "...", "actionRoute": null }
  ],
  "radarData": {
    "storeAverages": { "Safety": 60.0 },
    "areaAverages": { "Safety": 80.0 }
  },
  "insightsStale": false
}
```

### Required Fixture State for Integration Tests
```
Area → has AreaBenchmarkSnapshot (OverallAvgScore=80, StdDev=10, TotalAuditCount=8, CategoryAverages={"Safety":80})
  Store → has StoreAnalyticsSnapshot (AvgScore30d=55)
  Store → has SubmissionSectionScores [Safety: 60/100]
  Store → 5 completed Submissions in last 30d
```

---

## Tools & Commands

| Tool | Purpose |
|---|---|
| `testing-strategy` skill | xUnit v3 + WebApplicationFactory pattern |
| `tdd` skill | Red-Green-Refactor cycle |

```bash
# Unit tests only (fast, no DB)
rtk dotnet test --filter "InsightGenerator" server/tests/Checkly.Api.Tests

# Integration tests
rtk dotnet test --filter "InsightsIntegration" server/tests/Checkly.Api.Tests
```

---

## Proposed Changes

| Action | File | Notes |
|---|---|---|
| [MOD] | `server/Features/Analytics/Dtos.cs` | Add `ActionableInsight`, `RadarData`, extend `AnalyticsResponse` (28→~55 lines) |
| [NEW] | `server/Features/Analytics/InsightGeneratorService.cs` | Static class, 5 heuristic rules, ~80 lines |
| [MOD] | `server/Features/Analytics/GetAnalytics.cs` | Add benchmark read + insight call block (195→~235 lines) |
| [NEW] | `server/tests/Checkly.Api.Tests/Features/Analytics/InsightGeneratorTests.cs` | Unit tests IG-02, IG-03, IG-08 (~80 lines) |
| [NEW] | `server/tests/Checkly.Api.Tests/Features/Analytics/InsightsIntegrationTests.cs` | Integration tests IG-01, IG-04, IG-05, IG-06, IG-07 (~150 lines) |

---

## Concept Diagram

```text
GET /api/analytics
  │
  ├── [EXISTING] Role/IDOR guard → resolves storeId, areaIdStr
  ├── [EXISTING] KPI queries (totalAudits, avgScore, ...)
  ├── [EXISTING] 6-month trend
  ├── [EXISTING] Section breakdown (→ used as StoreAverages for RadarData)
  │
  ├── [NEW] Resolve areaId for insights:
  │     store_manager → db.Stores.Where(s.Id==sid).Select(s.AreaId)
  │     area_manager  → already in areaIdParsed
  │     admin/auditor → areaIdParsed if provided
  │
  ├── [NEW] Read AreaBenchmarkSnapshot WHERE AreaId = resolvedAreaId
  │     → null? → insights=[], radarData=null
  │     → stale? → insightsStale=true
  │
  ├── [NEW] InsightGeneratorService.Generate(
  │           liveScore: avgScore,
  │           areaAvgScore: snapshot.OverallAvgScore,
  │           stdDeviation: snapshot.StdDeviation,
  │           totalAudits: totalAudits (from KPI),
  │           storeCategoryAverages: sectionBreakdown→dict,
  │           areaCategoryAverages: deserialize(snapshot.CategoryAverages),
  │           overdueAPs: overdueAPs
  │         )
  │         → InsightResult { Insights: List<ActionableInsight>, RadarData? }
  │
  └── return AnalyticsResponse(kpis, trend, sectionBreakdown,
              insights, radarData, insightsStale)

InsightGeneratorService (static):
  Rule 1: liveScore < areaAvg - 1.5*stdDev → "warning: score below regional avg"
  Rule 2: liveScore > areaAvg + stdDev     → "positive: top performer"
  Rule 3: weakest category vs area         → "warning: {cat} weak vs region"
  Rule 4: strongest category vs area       → "positive: {cat} strong"
  Rule 5: overdueAPs > 0                   → "warning: {N} overdue action plans"
  → Collect all → .Take(3).ToList()
```

---

## Execution Slices

### Execution Phase (Single Phase — 5 files, all backend)
**Plain English:** Add the 3 new DTOs, write the static `InsightGeneratorService` with 5 heuristic rules, and extend `GetAnalytics.HandleAsync` to read the benchmark snapshot and call the generator before returning.

**Value Delivered:** `GET /api/analytics` now returns rich insight cards and radar data — the data contract Flutter needs for Slice 3.

**Entry State Required:** Slice 1 complete — `AreaBenchmarkSnapshot` entity and table exist (✅ confirmed GREEN).

**Exit State Guaranteed:**
- `dotnet build` passes with 0 errors (positional record constructor updated)
- Unit tests IG-02, IG-03, IG-08 pass (pure logic — no DB)
- Integration tests IG-01, IG-04, IG-05, IG-06, IG-07 pass
- Existing test `GetAnalytics_Response_Shape_Unchanged_After_Refactor` (AC-S2.1) still passes

**Scope:**
- Dtos.cs — additive only
- InsightGeneratorService.cs — new file
- GetAnalytics.cs — extend only (no existing lines removed)

**Acceptance Criteria:**
1. `GET /api/analytics` returns `insights`, `radarData`, `insightsStale` fields (C1)
2. Store with `totalAudits30d < 3` → exactly 1 "info" insight, `radarData = null` (C5)
3. Stale benchmark → `insightsStale = true` (C6)
4. No benchmark row → `insights = []`, `radarData = null`, `insightsStale = false` (graceful) (C8)
5. Max 3 insights regardless of rules firing (C7)
6. `InsightGeneratorService` is static — no DI registration needed (C4)
7. Existing `kpis`, `trend`, `sectionBreakdown` still present in response (C10)

**Key Design Decision — `InsightResult` return type:**

| Option | Pros | Cons |
|---|---|---|
| **A: Return tuple `(List<ActionableInsight>, RadarData?)`** | Simple, no extra class | Harder to read, IDE warnings |
| **B: Return `InsightResult` record** | Clean, readable, testable | 1 extra DTO |

**Decision: Option B** — `InsightResult` as a private record inside `InsightGeneratorService.cs`. Not exposed in the HTTP DTO.

**Complexity:** Medium — joining sectionBreakdown output to store averages dict for RadarData requires careful projection from the already-computed list.

<command_logs>
- view_file: `Dtos.cs` (28 lines) — confirmed 4 existing records, AnalyticsResponse positional constructor
- view_file: `GetAnalytics.cs` (195 lines) — confirmed line 189 positional constructor call to update
- view_file: `AnalyticsEndpoints.cs` (30 lines) — no changes needed
- view_file: `AreaBenchmarkSnapshot.cs` — confirmed 7 fields including CategoryAverages (jsonb string)
- view_file: `AreaBenchmarkCalculator.cs` — confirmed CategoryAverages is JSON-serialized dict
- view_file: `AreaBenchmarkWorker.cs` — Slice 1 worker intact
- view_file: `AppCapabilities.cs` — AnalyticsView, AnalyticsArea, AnalyticsAdmin confirmed
- view_file: `Profile.cs` — AreaId (Guid?) confirmed
- view_file: `AreaBenchmarkWorkerTests.cs` — Slice 1 tests GREEN (2 passed)
- view_file: `executed_tests_SL1_B2_handoff.md` — Slice 1 confirmed GREEN
- view_file: `AnalyticsTests.cs` (lines 312–693) — AC-S2.1 checks only kpis/trend/sectionBreakdown shape (safe to add new fields)
- grep_search: `AnalyticsResponse` in server/ — 1 usage in GetAnalytics.cs line 189 only
- grep_search: `AreaBenchmarkSnapshot` in server/ — confirmed in DbContext, Calculator, migration
</command_logs>

---

## Handoff Block

> **Route: TDD → Implementation** (Track B — contains business logic/math)

Execute **ONE AT A TIME** in this order:

**Step 1 — TDD Phase (write failing tests first)**
```
/tdd c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_060602_SL2_insight_generator.md
```
Focus: Write `InsightGeneratorTests.cs` (unit, IG-02, IG-03, IG-08) and `InsightsIntegrationTests.cs` (integration, IG-01, IG-04, IG-05, IG-06, IG-07). Run tests — confirm RED.

**Step 2 — Implementation Phase (make tests GREEN)**
```
/implement c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260518_060602_SL2_insight_generator.md
```
Focus: Implement `InsightGeneratorService.cs`, extend `Dtos.cs`, extend `GetAnalytics.cs`. Run tests — confirm GREEN.

**Concurrency:** Slice 3 (Flutter UI) CANNOT start until this Slice 2 is GREEN — Flutter needs the `insights` and `radarData` fields in the API contract.
