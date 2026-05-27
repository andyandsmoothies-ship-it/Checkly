# Implementation Plan: Populating Missing Data Sections in Filtered Live BOD Report

## 1. Flow Diagram
```
[Flutter UI] --(Request with Province/District)--> [GetBodReport.cs (Live/Filtered Mode)]
                                                                |
                                                      1. Find filtered Store IDs
                                                      2. Calculate KPIs (Audits, Scores, APs)
                                                      3. Calculate 12-Month Trend (New!)
                                                      4. Calculate Weaknesses (New!)
                                                      5. Calculate AP Aging (New!)
                                                      6. Calculate Auditor Productivity (New!)
                                                                |
                                                     [JSON Response with Complete Data]
                                                                |
                                                                v
                                                     [Flutter UI Full Visualization]
```

## 2. Problem Statement
In the Checkly application's BOD Analytics dashboard, when a user applies a geographic filter (such as selecting a specific `province` or `district`), the API endpoint `/api/analytics/bod` is routed to the filtered/live computation logic in `GetBodReport.cs`. 

Currently, that logic returns empty lists for several sections:
- `trend` (12-Month Trend)
- `weaknesses` (Category Weaknesses in last 90 Days)
- `actionPlanAging` (Action Plan aging distribution)
- `auditorProductivity` (Auditor productivity analysis)

This causes the UI charts and lists to appear blank or empty when a geographic filter is selected, even though the database contains rich historical data for those stores.

## 3. Solution Strategy
We will implement the detailed queries inside `GetBodReport.cs` under the `if (!string.IsNullOrEmpty(province))` condition. These queries will parallel the nightly snapshot computation logic from `BodReportCalculator.cs`, but will be filtered specifically by `filteredStoreIds`.

### Detailed Steps

#### Step 3.1: 12-Month Trend Calculation
- Determine the start date of the trend period: 11 months before the current month (UTC).
- Query submissions completed in the last 12 months, restricted to `filteredStoreIds`.
- Group by year and month.
- Project into `TrendPoint` records.

#### Step 3.2: Category Weaknesses Calculation
- Define a 90-day window.
- Query `SubmissionSectionScores` within the last 90 days, restricted to the `StoreId`s matching `filteredStoreIds`.
- Group by section title and submission template title.
- Order by average score ascending, and take the top 5 weakest categories.

#### Step 3.3: Action Plan Aging Calculation
- Query all open action plans matching the `filteredStoreIds`.
- Distribute their creation times into four buckets: `0-7d`, `8-30d`, `31-90d`, and `90d+`.
- Project into `BodApAgingBucket` records.

#### Step 3.4: Auditor Productivity Calculation
- Define a 30-day window.
- Query submissions completed in the last 30 days, matching `filteredStoreIds`.
- Group by auditor ID and auditor name.
- Project into `BodAuditorProductivity` records.

## 4. Proposed Changes

### [GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs)
```csharp
            // 2. 12-Month Trend (Filtered by stores)
            var localFirstDay = new DateTime(now.Year, now.Month, 1, 0, 0, 0, DateTimeKind.Utc).AddMonths(-11);
            var trendStartDate = new DateTimeOffset(localFirstDay, TimeSpan.Zero);
            
            var trendRaw = await db.Submissions.AsNoTracking()
                .Where(s => 
                    s.Status == "completed" && 
                    (s.ReviewStatus == null || s.ReviewStatus != "rejected") && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt >= trendStartDate && 
                    s.CompletedAt <= now && 
                    (s.ScoringMode == null || s.ScoringMode != "survey") && 
                    s.TotalScore.HasValue &&
                    s.StoreId.HasValue &&
                    filteredStoreIds.Contains(s.StoreId.Value))
                .GroupBy(s => new { s.CompletedAt!.Value.Year, s.CompletedAt.Value.Month })
                .Select(g => new
                {
                    g.Key.Year,
                    g.Key.Month,
                    AvgScore = g.Average(s => s.TotalScore!.Value),
                    Count = g.Count()
                })
                .ToListAsync(ct);

            var trendList = trendRaw
                .OrderBy(x => x.Year).ThenBy(x => x.Month)
                .Select(x => new TrendPoint(
                    $"{x.Year}-{x.Month:D2}",
                    Math.Round((double)x.AvgScore, 1),
                    x.Count))
                .ToList();

            // 4. Category Weaknesses (Last 90 Days) (Filtered by stores)
            var start90DaysAgo = now.AddDays(-90);
            
            var sectionStats = await db.SubmissionSectionScores.AsNoTracking()
                .Where(ss => ss.CreatedAt >= start90DaysAgo && 
                             ss.CreatedAt <= now && 
                             ss.MaxScore > 0 &&
                             ss.StoreId.HasValue &&
                             filteredStoreIds.Contains(ss.StoreId.Value))
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

            var weaknessesList = sectionStats
                .Select(x => new BodCategoryWeakness(
                    x.CategoryName,
                    x.TemplateTitle,
                    x.TotalMaxScore > 0 ? Math.Round((x.TotalScore / x.TotalMaxScore) * 100m, 1) : 0m,
                    x.AuditCount))
                .OrderBy(x => x.AvgScore)
                .Take(5)
                .ToList();

            // 5. Action Plan Aging (Filtered by stores)
            var openAps = await db.ActionPlans.AsNoTracking()
                .Where(ap => ap.Status == "open" && 
                             ap.CreatedAt <= now &&
                             ap.StoreId.HasValue &&
                             filteredStoreIds.Contains(ap.StoreId.Value))
                .Select(ap => ap.CreatedAt)
                .ToListAsync(ct);

            var bucket_0_7 = 0;
            var bucket_8_30 = 0;
            var bucket_31_90 = 0;
            var bucket_90_plus = 0;

            foreach (var apCreatedAt in openAps)
            {
                var ageInDays = (now - apCreatedAt).TotalDays;
                if (ageInDays <= 7) bucket_0_7++;
                else if (ageInDays <= 30) bucket_8_30++;
                else if (ageInDays <= 90) bucket_31_90++;
                else bucket_90_plus++;
            }

            var actionPlanAgingList = new List<BodApAgingBucket>
            {
                new("0-7d", bucket_0_7),
                new("8-30d", bucket_8_30),
                new("31-90d", bucket_31_90),
                new("90d+", bucket_90_plus)
            };

            // 6. Auditor Productivity (Last 30 Days) (Filtered by stores)
            var auditorStats = await db.Submissions.AsNoTracking()
                .Where(s => 
                    s.Status == "completed" && 
                    (s.ReviewStatus == null || s.ReviewStatus != "rejected") && 
                    s.CompletedAt.HasValue && 
                    s.CompletedAt >= start30DaysAgo && 
                    s.CompletedAt <= now && 
                    s.AuditorId.HasValue &&
                    s.StoreId.HasValue &&
                    filteredStoreIds.Contains(s.StoreId.Value))
                .GroupBy(s => new { s.AuditorId!.Value, s.AuditorName })
                .Select(g => new
                {
                    AuditorId = g.Key.Value,
                    AuditorName = g.Key.AuditorName ?? "Unknown Auditor",
                    CompletedAudits = g.Count(),
                    AvgScore = g.Any(s => s.TotalScore.HasValue && s.ScoringMode != "survey")
                        ? g.Where(s => s.TotalScore.HasValue && s.ScoringMode != "survey").Average(s => s.TotalScore!.Value)
                        : 0m
                })
                .ToListAsync(ct);

            var auditorProductivityList = auditorStats
                .Select(x => new BodAuditorProductivity(
                    x.AuditorId,
                    x.AuditorName,
                    x.CompletedAudits,
                    Math.Round(x.AvgScore, 1)))
                .OrderByDescending(x => x.CompletedAudits)
                .ToList();
```

And in the returned payload:
```csharp
                trend = trendList,
                topStores = topStoresList,
                bottomStores = bottomStoresList,
                weaknesses = weaknessesList,
                actionPlanAging = actionPlanAgingList,
                auditorProductivity = auditorProductivityList,
```

## 5. Verification Plan
1. **Compilation Check**: Run `rtk dotnet build` in `server/` to verify zero compile errors.
2. **Standard Tests**: Run `rtk dotnet test` to verify no existing tests break.
3. **Endpoint Integration Testing**:
   - Write/run tests targeting `/api/analytics/bod?province=...` to ensure it successfully populates and returns non-empty sections for trend, weaknesses, actionPlanAging, and auditorProductivity.
