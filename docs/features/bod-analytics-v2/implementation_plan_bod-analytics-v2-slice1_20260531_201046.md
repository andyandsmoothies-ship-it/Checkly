---
conversation_id: e4a8d231-abcb-46c0-ae41-613c2d8ed2c0
created_at: 2026-05-31T20:10:46+07:00
topic: bod-analytics-v2
type: implementation_plan
status: IN_PROGRESS
---

# Implementation Plan: Area Manager BOD Dashboard (Slice 1)

This plan outlines the design and step-by-step instructions to deliver **Slice 1** of the **BOD Analytics V2** epic. It introduces a tenancy-scoped Boardroom Dashboard endpoint and Flutter UI integration tailored specifically for Area Managers.

## 1. Data Flow & Component Relationship

```text
[Flutter Client] ───> GET /api/analytics/bod/area (analytics:area)
                             │
                             ├── [Tenancy Verification]
                             │   ├── Retrieve user ProfileId from Claims
                             │   └── Load assigned StoreIds from ProfileStoreAssignments
                             │
                             └── [Analytical Calculations]
                                 ├── Filter Submissions & Action Plans by StoreIds (Last 30/90d)
                                 ├── Compute KPIs (Completion rate, SLA buckets, Leaderboard)
                                 └── Return AreaBodResponse DTO
```

## 2. Overview & Objectives

*   **Goal**: Provide Area Managers (AM) with a detailed, high-level overview (BOD dashboard) of their assigned stores.
*   **Tenancy Enforcement**: Area Managers must only see data matching their assigned stores. If an AM is not assigned to any stores, the dashboard returns `200 OK` with zeroed/empty fields instead of failing.
*   **PBAC Gate**: Access is guarded on both backend and frontend by the new `analytics:area` capability.

## 3. Technical Architecture & Component Map

### A. Capability Seeding
*   **C# (`server/Common/Auth/AppCapabilities.cs`)**: Register `public const string AnalyticsArea = "analytics:area";`.
*   **Dart (`lib/_shared/constants/app_capabilities.dart`)**: Register `static const analyticsArea = 'analytics:area';` and add it to `adminDomainCapabilities` to ensure access is recognized.
*   **Database Seeding (`server/Program.cs`)**:
    Add `INSERT` statements to map `'analytics:area'` to `area_manager` and `admin` roles.
*   **Test Database Seeding (`server/tests/Checkly.Api.Tests/TestWebApplicationFactory.cs`)**:
    Map `'analytics:area'` to `area_manager` and `admin` roles in the integration test database setup.

### B. C# Backend Endpoint (`server/Features/Analytics/GetAreaBodReport.cs`)
Create a new endpoint `GET /api/analytics/bod/area` mapped in `AnalyticsEndpoints.cs`.
*   **Tenancy Scoping**:
    Join `ProfileStoreAssignments` on the current user's profile ID to retrieve the list of assigned `StoreId` values.
*   **Edge Case**:
    If `assignedStoreIds` is empty, return a default `AreaBodResponse` with zeros/empty arrays.
*   **Live Aggregations**:
    *   **Active Stores**: Count of active stores matching assigned store IDs.
    *   **Total Audits**: Completed audits in the last 30 days for these stores.
    *   **Average Score**: Average of completed audit scores.
    *   **Completion Rate**: Completed audits divided by scheduled audits (last 30 days).
    *   **Action Plans (Open/Overdue)**: Counts filtered by assigned store IDs.
    *   **Total Auditors**: Distinct auditor profiles performing audits in the last 30 days.
    *   **Average TTR**: Average days from creation to close of closed action plans.
    *   **Golden Store**: The assigned store with the highest average score (last 30 days).
    *   **Trend**: 12-month rolling trend of average scores.
    *   **Leaderboard**: Top 5 and bottom 5 stores by average score.
    *   **Category Weaknesses**: Top 5 underperforming categories/sections (last 90 days).
    *   **SLA Aging**: Counts of open action plans grouped by aging buckets: "0-7d", "8-30d", "31-90d", "90d+".

### C. Flutter API & Manager Integration
*   **API Client (`lib/features/analytics/services/area_bod_api_service.dart`)**:
    *   Create a dedicated service with `getReport()`, `getFilteredReport(...)`, `getApBucketDetail(...)`, `getStoreBodSummary(...)`, `getCategoryDetail(...)`, and `getAuditorProductivity()`.
    *   Targets `/api/analytics/bod/area`.
*   **Manager (`lib/features/analytics/manager/area_bod_manager.dart`)**:
    *   Implement `AreaBodManager` extending `CommandManager` to handle loading, polling, filtering, detail lookups, and error states.
*   **Dependency Injection (`lib/locator.dart`)**:
    *   Register `AreaBodApiService` and `AreaBodManager`.

## 4. Step-by-Step Implementation Details

### Step 4.1: Capability Definitions & Seeding
Modify `AppCapabilities.cs` to add:
```csharp
public const string AnalyticsArea = "analytics:area";
```
Modify `app_capabilities.dart` to add:
```dart
static const analyticsArea = 'analytics:area';
```

Modify `server/Program.cs` and `TestWebApplicationFactory.cs` to append:
```sql
(gen_random_uuid(), 'area_manager', 'analytics:area', now()),
(gen_random_uuid(), 'admin', 'analytics:area', now())
```

### Step 4.2: Backend Endpoint
Create `server/Features/Analytics/GetAreaBodReport.cs`:
```csharp
namespace Checkly.Api.Features.Analytics;

using System;
using System.Collections.Generic;
using System.Linq;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Checkly.Api.Common.Auth;
using Checkly.Api.Database;

public static class GetAreaBodReport
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Fetch assigned StoreIds from tenancy assignments
        var assignedStoreIds = await db.ProfileStoreAssignments
            .AsNoTracking()
            .Where(a => a.ProfileId == userId)
            .Select(a => a.StoreId)
            .ToListAsync(ct);

        if (!assignedStoreIds.Any())
        {
            return Results.Ok(new AreaBodResponse
            {
                IsLiveData = true,
                Kpis = new AreaBodKpiDto(),
                GoldenStore = null,
                Trend = new List<AreaTrendPointDto>(),
                TopStores = new List<AreaStoreRankEntryDto>(),
                BottomStores = new List<AreaStoreRankEntryDto>(),
                Weaknesses = new List<AreaCategoryWeaknessDto>(),
                ActionPlanAging = GetDefaultAgingBuckets(),
                AuditorProductivity = new List<AreaAuditorProductivityDto>(),
                AllowedActions = new List<string>()
            });
        }

        var now = DateTimeOffset.UtcNow;
        var start30DaysAgo = now.AddDays(-30);
        var start90DaysAgo = now.AddDays(-90);

        // Submissions last 30 days
        var submissionsLast30Days = await db.Submissions
            .AsNoTracking()
            .Where(s => s.Status == "completed" 
                && (s.ReviewStatus == null || s.ReviewStatus != "rejected")
                && (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo 
                && (s.CompletedAt ?? s.CreatedAt) <= now 
                && (s.ScoringMode == null || s.ScoringMode != "survey")
                && s.TotalScore.HasValue 
                && s.StoreId.HasValue 
                && assignedStoreIds.Contains(s.StoreId.Value))
            .ToListAsync(ct);

        int totalAudits = submissionsLast30Days.Count;
        decimal avgScore = totalAudits > 0 ? Math.Round(submissionsLast30Days.Average(s => s.TotalScore!.Value), 1) : 0m;

        // Completion Rate
        var totalScheduled = await db.Submissions
            .AsNoTracking()
            .CountAsync(s => (s.ReviewStatus == null || s.ReviewStatus != "rejected")
                && s.CreatedAt >= start30DaysAgo 
                && s.CreatedAt <= now 
                && s.StoreId.HasValue 
                && assignedStoreIds.Contains(s.StoreId.Value), ct);
        decimal completionRate = totalScheduled > 0 ? Math.Round((decimal)totalAudits / totalScheduled * 100m, 1) : 0m;

        // Action Plans
        var openActionPlans = await db.ActionPlans
            .AsNoTracking()
            .CountAsync(ap => ap.Status == "open" && ap.StoreId.HasValue && assignedStoreIds.Contains(ap.StoreId.Value), ct);
        var overdueActionPlans = await db.ActionPlans
            .AsNoTracking()
            .CountAsync(ap => ap.Status == "open" && ap.StoreId.HasValue && assignedStoreIds.Contains(ap.StoreId.Value) && ap.Deadline.HasValue && ap.Deadline <= now, ct);

        // Active Stores
        var activeStores = await db.Stores
            .AsNoTracking()
            .CountAsync(s => assignedStoreIds.Contains(s.Id) && s.IsActive == true, ct);

        // Total Auditors
        var totalAuditors = await db.Submissions
            .AsNoTracking()
            .Where(s => s.Status == "completed" 
                && (s.ReviewStatus == null || s.ReviewStatus != "rejected")
                && (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo 
                && (s.CompletedAt ?? s.CreatedAt) <= now 
                && s.AuditorId.HasValue 
                && s.StoreId.HasValue 
                && assignedStoreIds.Contains(s.StoreId.Value))
            .Select(s => s.AuditorId!.Value)
            .Distinct()
            .CountAsync(ct);

        // Average TTR
        var closedActionPlans = await db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.Status == "closed" && ap.ClosedAt.HasValue && ap.StoreId.HasValue && assignedStoreIds.Contains(ap.StoreId.Value))
            .Select(ap => new { ap.CreatedAt, ap.ClosedAt })
            .ToListAsync(ct);
        decimal avgTtrDays = 0m;
        if (closedActionPlans.Any())
        {
            var totalTtr = closedActionPlans.Sum(ap => (ap.ClosedAt!.Value - ap.CreatedAt).TotalDays);
            avgTtrDays = Math.Round((decimal)(totalTtr / closedActionPlans.Count), 1);
        }

        // Golden Store
        AreaGoldenStoreDto? goldenStore = null;
        var storeScores = submissionsLast30Days
            .GroupBy(s => s.StoreId!.Value)
            .Select(g => new { StoreId = g.Key, AvgScore = g.Average(s => s.TotalScore!.Value), Count = g.Count() })
            .ToList();

        if (storeScores.Any())
        {
            var topStore = storeScores.OrderByDescending(x => x.AvgScore).ThenByDescending(x => x.Count).FirstOrDefault();
            if (topStore != null)
            {
                var storeEntity = await db.Stores.AsNoTracking().FirstOrDefaultAsync(st => st.Id == topStore.StoreId, ct);
                if (storeEntity != null)
                {
                    goldenStore = new AreaGoldenStoreDto
                    {
                        StoreName = storeEntity.Name,
                        AvgScore = Math.Round(topStore.AvgScore, 1),
                        Province = storeEntity.Address2?.Province ?? ""
                    };
                }
            }
        }

        // Leaderboard (Top/Bottom 5)
        var regionalStoreScores = await db.Submissions
            .AsNoTracking()
            .Where(s => s.Status == "completed" 
                && (s.ReviewStatus == null || s.ReviewStatus != "rejected")
                && (s.CompletedAt ?? s.CreatedAt) >= start30DaysAgo 
                && (s.CompletedAt ?? s.CreatedAt) <= now 
                && (s.ScoringMode == null || s.ScoringMode != "survey")
                && s.TotalScore.HasValue 
                && s.StoreId.HasValue 
                && assignedStoreIds.Contains(s.StoreId.Value)
                && (s.TemplateId == null || s.Template.Type == "QC"))
            .GroupBy(s => s.StoreId!.Value)
            .Select(g => new { StoreId = g.Key, AvgScore = g.Average(s => s.TotalScore!.Value), Count = g.Count() })
            .ToListAsync(ct);

        var regionalStoreIds = regionalStoreScores.Select(x => x.StoreId).ToList();
        var regionalStoresMap = await db.Stores
            .AsNoTracking()
            .Where(s => regionalStoreIds.Contains(s.Id))
            .ToDictionaryAsync(s => s.Id, ct);

        var storeRankEntries = regionalStoreScores.Select(x =>
        {
            var storeEntity = regionalStoresMap.GetValueOrDefault(x.StoreId);
            return new AreaStoreRankEntryDto
            {
                StoreId = x.StoreId,
                StoreName = storeEntity?.Name ?? "Unknown Store",
                AvgScore = Math.Round(x.AvgScore, 1),
                AuditCount = x.Count,
                LastSyncedAt = storeEntity?.LastSyncedAt
            };
        }).ToList();

        var topStores = storeRankEntries.OrderByDescending(x => x.AvgScore).ThenByDescending(x => x.AuditCount).Take(5).ToList();
        var bottomStores = storeRankEntries.OrderBy(x => x.AvgScore).ThenBy(x => x.AuditCount).Take(5).ToList();

        // 12-Month Trend
        var localFirstDay = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-11);
        var trendStartDate = new DateTimeOffset(localFirstDay, TimeSpan.Zero);
        var trendRaw = await db.Submissions
            .AsNoTracking()
            .Where(s => s.Status == "completed" 
                && (s.ReviewStatus == null || s.ReviewStatus != "rejected")
                && s.CompletedAt.HasValue 
                && s.CompletedAt >= trendStartDate 
                && s.CompletedAt <= now 
                && (s.ScoringMode == null || s.ScoringMode != "survey")
                && s.TotalScore.HasValue 
                && s.StoreId.HasValue 
                && assignedStoreIds.Contains(s.StoreId.Value))
            .GroupBy(s => new { s.CompletedAt!.Value.Year, s.CompletedAt.Value.Month })
            .Select(g => new
            {
                g.Key.Year,
                g.Key.Month,
                AvgScore = g.Average(s => s.TotalScore!.Value),
                Count = g.Count()
            })
            .ToListAsync(ct);

        var trend = trendRaw
            .OrderBy(x => x.Year)
            .ThenBy(x => x.Month)
            .Select(x => new AreaTrendPointDto
            {
                Month = $"{x.Year}-{x.Month:D2}",
                AvgScore = Math.Round((double)x.AvgScore, 1),
                AuditCount = x.Count
            }).ToList();

        // Weaknesses (Last 90 Days)
        var sectionStats = await db.SubmissionSectionScores
            .AsNoTracking()
            .Where(ss => ss.CreatedAt >= start90DaysAgo 
                && ss.CreatedAt <= now 
                && ss.MaxScore > 0 
                && ss.StoreId.HasValue 
                && assignedStoreIds.Contains(ss.StoreId.Value))
            .GroupBy(ss => new { ss.SectionTitle, TemplateTitle = ss.Submission != null ? ss.Submission.TemplateTitle : "Unknown Template" })
            .Select(g => new
            {
                CategoryName = g.Key.SectionTitle,
                TemplateTitle = g.Key.TemplateTitle ?? "Unknown Template",
                TotalScore = g.Sum(ss => ss.Score),
                TotalMaxScore = g.Sum(ss => ss.MaxScore),
                AuditCount = g.Count()
            })
            .ToListAsync(ct);

        var weaknesses = sectionStats.Select(x => new AreaCategoryWeaknessDto
        {
            CategoryName = x.CategoryName,
            TemplateName = x.TemplateTitle,
            AvgScore = x.TotalMaxScore > 0 ? Math.Round((x.TotalScore / x.TotalMaxScore) * 100m, 1) : 0m,
            AuditCount = x.AuditCount
        }).OrderBy(x => x.AvgScore).Take(5).ToList();

        // SLA Action Plan Aging
        var openAps = await db.ActionPlans
            .AsNoTracking()
            .Where(ap => ap.Status == "open" && ap.CreatedAt <= now && ap.StoreId.HasValue && assignedStoreIds.Contains(ap.StoreId.Value))
            .Select(ap => ap.CreatedAt)
            .ToListAsync(ct);

        int bucket_0_7 = 0, bucket_8_30 = 0, bucket_31_90 = 0, bucket_90_plus = 0;
        foreach (var apCreatedAt in openAps)
        {
            var ageInDays = (now - apCreatedAt).TotalDays;
            if (ageInDays <= 7) bucket_0_7++;
            else if (ageInDays <= 30) bucket_8_30++;
            else if (ageInDays <= 90) bucket_31_90++;
            else bucket_90_plus++;
        }

        var actionPlanAging = new List<AreaApAgingBucketDto>
        {
            new("0-7d", bucket_0_7),
            new("8-30d", bucket_8_30),
            new("31-90d", bucket_31_90),
            new("90d+", bucket_90_plus)
        };

        return Results.Ok(new AreaBodResponse
        {
            IsLiveData = true,
            Kpis = new AreaBodKpiDto
            {
                TotalAudits = totalAudits,
                AvgScore = avgScore,
                CompletionRate = completionRate,
                OpenActionPlans = openActionPlans,
                OverdueActionPlans = overdueActionPlans,
                ActiveStores = activeStores,
                TotalAuditors = totalAuditors,
                AvgTtrDays = avgTtrDays
            },
            GoldenStore = goldenStore,
            Trend = trend,
            TopStores = topStores,
            BottomStores = bottomStores,
            Weaknesses = weaknesses,
            ActionPlanAging = actionPlanAging,
            AuditorProductivity = new List<AreaAuditorProductivityDto>(), // standard placeholder
            AllowedActions = new List<string>()
        });
    }

    private static List<AreaApAgingBucketDto> GetDefaultAgingBuckets()
    {
        return new List<AreaApAgingBucketDto>
        {
            new("0-7d", 0),
            new("8-30d", 0),
            new("31-90d", 0),
            new("90d+", 0)
        };
    }
}

// --- DTO Definition records ---
public record AreaBodResponse
{
    public bool IsLiveData { get; init; }
    public AreaBodKpiDto Kpis { get; init; } = new();
    public AreaGoldenStoreDto? GoldenStore { get; init; }
    public List<AreaTrendPointDto> Trend { get; init; } = new();
    public List<AreaStoreRankEntryDto> TopStores { get; init; } = new();
    public List<AreaStoreRankEntryDto> BottomStores { get; init; } = new();
    public List<AreaCategoryWeaknessDto> Weaknesses { get; init; } = new();
    public List<AreaApAgingBucketDto> ActionPlanAging { get; init; } = new();
    public List<AreaAuditorProductivityDto> AuditorProductivity { get; init; } = new();
    public List<string> AllowedActions { get; init; } = new();
}

public record AreaBodKpiDto
{
    public int TotalAudits { get; init; }
    public decimal AvgScore { get; init; }
    public decimal CompletionRate { get; init; }
    public int OpenActionPlans { get; init; }
    public int OverdueActionPlans { get; init; }
    public int ActiveStores { get; init; }
    public int TotalAuditors { get; init; }
    public decimal AvgTtrDays { get; init; }
}

public record AreaGoldenStoreDto
{
    public string StoreName { get; init; } = "";
    public decimal AvgScore { get; init; }
    public string Province { get; init; } = "";
}

public record AreaTrendPointDto
{
    public string Month { get; init; } = "";
    public double AvgScore { get; init; }
    public int AuditCount { get; init; }
}

public record AreaStoreRankEntryDto
{
    public Guid StoreId { get; init; }
    public string StoreName { get; init; } = "";
    public decimal AvgScore { get; init; }
    public int AuditCount { get; init; }
    public DateTimeOffset? LastSyncedAt { get; init; }
}

public record AreaCategoryWeaknessDto
{
    public string CategoryName { get; init; } = "";
    public string TemplateName { get; init; } = "";
    public decimal AvgScore { get; init; }
    public int AuditCount { get; init; }
}

public record AreaApAgingBucketDto(string Bucket, int Count);
public record AreaAuditorProductivityDto(string AuditorName, int CompletedCount, decimal AvgScore);
```

### Step 4.3: Flutter Services Integration
*   Create `lib/features/analytics/services/area_bod_api_service.dart` wrapping the target endpoints.
*   Create `lib/features/analytics/manager/area_bod_manager.dart` that delegates requests, processes loading shimmers, and handles polling of pre-computed states cleanly.

## 5. Test Design & Strategy

### A. C# Integration Tests
Create `server/tests/Checkly.Api.Tests/Features/Analytics/GetAreaBodReportTests.cs`:
1.  **Unauthorized**: Attempt to call `/api/analytics/bod/area` without a token or with a token missing `analytics:area` capability. Assert `403 Forbidden` or `401 Unauthorized`.
2.  **Empty Tenancy Handled**: Seed an Area Manager user with 0 store assignments. Assert a `200 OK` response returning clean empty arrays and zeroed KPI fields.
3.  **Strict Store Tenancy Restriction**:
    *   Seed Store A assigned to AM 1. Seed Store B assigned to AM 2.
    *   Seed completed audits with distinct scores for Store A and Store B.
    *   Authenticate as AM 1. Get the Area BOD Report.
    *   Assert that the KPIs, Trend, Golden Store, Leaderboard, and Weaknesses contain data **ONLY** for Store A, completely isolating Store B's records.

### B. Flutter Widget & Integration Tests
*   Ensure widget models correctly map responses from `AreaBodApiService` to the view.
*   Verify loading shimmer state rendering and offline check dialogs.

## 6. Checklist & Verification Steps

- [ ] Run `rtk dotnet build` in the `server` directory to check compilation.
- [ ] Run `rtk dotnet test` in the `server/tests/Checkly.Api.Tests` directory to run all backend tests.
- [ ] Run `flutter analyze` in the `lib` directory to verify syntax correctness.
- [ ] Run `flutter test` to ensure existing and new unit tests compile and pass.
