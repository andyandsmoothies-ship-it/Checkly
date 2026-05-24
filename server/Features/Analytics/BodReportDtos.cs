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
        int TotalAuditors);

    public record BodStoreRankEntry(Guid StoreId, string StoreName, decimal AvgScore, int AuditCount);

    public record BodCategoryWeakness(string CategoryName, string TemplateTitle, decimal AvgScore, int AuditCount);

    public record BodApAgingBucket(string Bucket, int Count);

    public record BodAuditorProductivity(Guid AuditorId, string AuditorName, int CompletedAudits, decimal AvgScore);
}
