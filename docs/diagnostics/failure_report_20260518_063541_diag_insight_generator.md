# Failure Report: Sparsity Guard Bypass in Insight Generator

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\qa\gates\reporting\verification_20260518_063029_SL2_insight_generator.md`

## Root Cause
The `GetAnalytics` endpoint (Slice 2) was bypassing the sparsity guard (which enforces a minimum of 3 audits to display insights and radar charts). When calling the `InsightGeneratorService.Generate()` method, the code incorrectly passed `snapshot.TotalAuditCount` (the **Area's** total audit count) instead of the caller-filtered `totalAudits` (the **Store's** total audit count). 

Because the integration test seeded both the Area and Store with exactly 2 audits, the Area's count was also below the threshold, masking the bug during TDD.

## Explicit Code Trace (Premises + Proof)
**Premise 1**: The integration test (`InsightsIntegrationTests.cs`) was modified to seed an area with 10 total audits, but a store with only 2 total audits (`totalAuditCount: 10`).
**Proof 1**: Running the test caused it to fail, expecting the "info" insight (insufficient data), but returning "warning" instead. This proved that the Area's count (10) was driving the sparsity guard.

**Premise 2**: In `GetAnalytics.cs`, line 101 correctly evaluates the localized `totalAudits` for the given store/area/template context.
```csharp
var totalAudits = await query.CountAsync(ct);
```

**Premise 3**: In `GetAnalytics.cs`, line 223 passed `snapshot.TotalAuditCount` instead of `totalAudits`.
```csharp
var generatorResult = InsightGeneratorService.Generate(
    liveScore: avgScore,
    areaAvgScore: (double)snapshot.OverallAvgScore,
    stdDeviation: (double)snapshot.StdDeviation,
    totalAudits: totalAudits, // <-- FIX APPLIED HERE
    // ...
```
**Proof 2**: After making the 1-line change to pass `totalAudits`, the integration test turned GREEN, successfully suppressing insights for a sparse store even if its parent area has abundant data.

## Proposed Scope-Limited Fix
The fix requires a simple 1-line variable swap in `GetAnalytics.cs` and a seed data update in `InsightsIntegrationTests.cs`.
Since the micro-experiment was already verified as part of Phase 3, this code is ready for handoff.

### Trade-offs / Pros & Cons
- **Pros**: Perfectly aligns the `InsightGeneratorService` with its original Acceptance Criteria (C5). Ensures Store Managers do not get skewed AI insights based on a sample size of 1.
- **Cons / Risks**: N/A. The fix uses existing variables loaded in memory and requires no new SQL executions or architectural changes.

<forensic_evidence>
```bash
[rtk] /!\ No hook installed — run `rtk init -g` for automatic token savings
ok dotnet test: completed (binlog-only mode, counts unavailable, 0 warnings) (unknown)
Test run for C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\bin\Debug\net10.0\Checkly.Api.Tests.dll (.NETCoreApp,Version=v10.0)
VSTest version 18.0.1 (x64)

[xUnit.net 00:00:04.82]     Checkly.Api.Tests.Features.Analytics.InsightsIntegrationTests.GetAnalytics_SparseStore_ReturnsSingleInfoInsightAndNullRadarData [FAIL]
  Failed Checkly.Api.Tests.Features.Analytics.InsightsIntegrationTests.GetAnalytics_SparseStore_ReturnsSingleInfoInsightAndNullRadarData [4 s]
  Error Message:
   Assert.Equal() Failure: Strings differ
           ↓ (pos 0)
Expected: "info"
Actual:   "warning"
           ↑ (pos 0)

Passed!  - Failed:     0, Passed:     1, Skipped:     0, Total:     1, Duration: 4 s - Checkly.Api.Tests.dll (net10.0)
```
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict & Persistent path**:
   - Verdict: **Logical Regression Confirmed & Fixed**.
   - Path: `c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260518_063541_diag_insight_generator.md`
2. **The required fix and its blast radius**:
   - Fix: Swap `snapshot.TotalAuditCount` for `totalAudits` inside `GetAnalytics.cs`.
   - Blast Radius: Limited entirely to the `GetAnalytics` endpoint. No side effects.
3. **AI Agent Mission Brief**:
   - The Builder must officially apply the verified 1-line fix in `GetAnalytics.cs` to pass `totalAudits` instead of `snapshot.TotalAuditCount` to the insight generator, update the `InsightsIntegrationTests` to seed an area count of 10, and run a final `/verify` check. *(Note: The fix has been drafted via micro-experiment during diagnostics).*
4. **Execution Queue**:
   - [ ] `@[/implement] c:\Users\HP\Documents\GitHub\Checkly\docs\diagnostics\failure_report_20260518_063541_diag_insight_generator.md`
