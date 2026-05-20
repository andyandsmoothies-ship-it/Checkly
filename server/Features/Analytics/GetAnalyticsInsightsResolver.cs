using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

public static class GetAnalyticsInsightsResolver
{
    public static async Task<(List<ActionableInsight>? Insights, RadarData? RadarData, bool InsightsStale)> ResolveAsync(
        AppDbContext db,
        string? province,
        bool storeIdParsed,
        Guid sid,
        List<SectionScore> sectionBreakdown,
        double avgScore,
        int totalAudits,
        int overdueAPs,
        CancellationToken ct)
    {
        List<ActionableInsight>? insights = null;
        RadarData? radarData = null;
        bool insightsStale = false;

        string? resolvedProvince = province;

        if (string.IsNullOrEmpty(resolvedProvince))
        {
            if (storeIdParsed)
            {
                var store = await db.Stores.AsNoTracking().FirstOrDefaultAsync(st => st.Id == sid, ct);
                resolvedProvince = store?.Address2?.Province;
            }
        }

        if (!string.IsNullOrEmpty(resolvedProvince))
        {
            var snapshot = await db.ProvinceBenchmarkSnapshots
                .AsNoTracking()
                .FirstOrDefaultAsync(b => b.Province == resolvedProvince, ct);

            if (snapshot is not null)
            {
                insightsStale = snapshot.LastCalculatedAt < DateTimeOffset.UtcNow.AddHours(-2);

                var storeCategoryAverages = sectionBreakdown.ToDictionary(s => s.Section, s => s.AvgScore);

                var areaCategoryAverages = string.IsNullOrEmpty(snapshot.CategoryAverages)
                    ? new Dictionary<string, double>()
                    : System.Text.Json.JsonSerializer.Deserialize<Dictionary<string, double>>(snapshot.CategoryAverages) ?? new Dictionary<string, double>();

                var generatorResult = InsightGeneratorService.Generate(
                    liveScore: avgScore,
                    areaAvgScore: (double)snapshot.OverallAvgScore,
                    stdDeviation: (double)snapshot.StdDeviation,
                    totalAudits: totalAudits,
                    storeCategoryAverages: storeCategoryAverages,
                    areaCategoryAverages: areaCategoryAverages,
                    overdueAPs: overdueAPs
                );

                insights = generatorResult.Insights;
                radarData = generatorResult.RadarData;
            }
        }

        return (insights, radarData, insightsStale);
    }
}
