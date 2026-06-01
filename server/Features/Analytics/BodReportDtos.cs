using System;
using System.Collections.Generic;

namespace Checkly.Api.Features.Analytics
{
    public record BodReportResponse(
        BodChainKpis Kpis,
        List<TrendPoint> Trend,
        List<BodStoreRankEntry>? TopStores,
        List<BodStoreRankEntry>? BottomStores,
        List<BodCategoryWeakness> Weaknesses,
        List<BodApAgingBucket> ActionPlanAging,
        List<BodAuditorProductivity> AuditorProductivity);

    public record BodChainKpis(
        int TotalAudits,
        decimal AvgScore,
        decimal CompletionRate,
        int OpenActionPlans,
        int OverdueActionPlans,
        int ActiveStores,
        int TotalAuditors,
        decimal AvgTtrDays = 0m,
        int GeofenceBypassCount = 0);


    public record BodStoreRankEntry(Guid StoreId, string StoreName, decimal AvgScore, int AuditCount, DateTimeOffset? LastSyncedAt);


    public record BodCategoryWeakness(string CategoryName, string TemplateTitle, decimal AvgScore, int AuditCount);

    public record BodApAgingBucket(string Bucket, int Count);

    public record BodAuditorProductivity(Guid AuditorId, string AuditorName, int CompletedAudits, decimal AvgScore);

    public record ApDetailEntry(Guid Id, string CriteriaLabel, string StoreName, string ManagerName, int AgeInDays);

    public record AuditorProductivityEntry(Guid AuditorId, string AuditorName, int CompletedAudits, decimal AvgScore, string BiasRating);

    public record StoreBodSummary(
        string StoreName, 
        List<RecentAuditEntry> RecentAudits, 
        List<CategoryScoreEntry> CategoryBreakdown,
        string? QuartileLabel = null,
        decimal RegionalAvgScore = 0m,
        List<BodApAgingBucket>? SlaOverdueBuckets = null);
    public record RecentAuditEntry(DateTimeOffset Date, decimal Score, string AuditorName);
    public record CategoryScoreEntry(string CategoryName, decimal AvgScore);
    public record CategoryStoreEntry(string StoreName, decimal AvgScore, int AuditCount, int FailureCount);
}
