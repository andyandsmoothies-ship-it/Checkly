using System;
using System.Collections.Generic;
using System.Linq;

namespace Checkly.Api.Features.Analytics;

public static class InsightGeneratorService
{
    public sealed record GenerationResult(List<ActionableInsight> Insights, RadarData? RadarData);

    public static GenerationResult Generate(
        double liveScore,
        double areaAvgScore,
        double stdDeviation,
        int totalAudits,
        Dictionary<string, double> storeCategoryAverages,
        Dictionary<string, double> areaCategoryAverages,
        int overdueAPs)
    {
        // Guard 1: Sparsity
        if (totalAudits < 3)
        {
            var sparseInsight = new ActionableInsight(
                Id: "ins_sparse_data",
                Type: "info",
                Title: "Insufficient Data",
                Description: "Complete at least 3 audits to unlock area benchmark insights and radar charts.");
            return new GenerationResult(new List<ActionableInsight> { sparseInsight }, null);
        }

        var insights = new List<ActionableInsight>();

        // Rule 1: SCORE_DROP_WARNING
        if (liveScore < areaAvgScore - (1.5 * stdDeviation))
        {
            insights.Add(new ActionableInsight(
                Id: "ins_score_drop",
                Type: "warning",
                Title: "Critical Score Drop",
                Description: "Your store's overall score has fallen significantly below the area average. Immediate attention required."));
        }
        // Rule 2: SCORE_POSITIVE
        else if (liveScore > areaAvgScore + stdDeviation)
        {
            insights.Add(new ActionableInsight(
                Id: "ins_top_performer",
                Type: "positive",
                Title: "Top Performer",
                Description: "Excellent work! Your store is performing well above the area average."));
        }

        // Radar Data intersection
        var categories = storeCategoryAverages.Keys.Intersect(areaCategoryAverages.Keys).OrderBy(k => k).ToList();
        RadarData? radarData = null;

        if (categories.Count >= 3)
        {
            var storeScores = categories.Select(c => storeCategoryAverages[c]).ToList();
            var areaScores = categories.Select(c => areaCategoryAverages[c]).ToList();
            radarData = new RadarData(categories, storeScores, areaScores);
        }

        // Rule 3: CATEGORY_WEAK
        foreach (var cat in categories)
        {
            if (storeCategoryAverages[cat] < areaCategoryAverages[cat] - 10.0)
            {
                insights.Add(new ActionableInsight(
                    Id: $"ins_cat_weak_{cat}",
                    Type: "warning",
                    Title: $"{cat} Needs Focus",
                    Description: $"Your {cat} score is more than 10 points below the area average."));
            }
        }

        // Rule 4: CATEGORY_STRONG
        foreach (var cat in categories)
        {
            if (storeCategoryAverages[cat] > areaCategoryAverages[cat] + 10.0)
            {
                insights.Add(new ActionableInsight(
                    Id: $"ins_cat_strong_{cat}",
                    Type: "positive",
                    Title: $"{cat} Excellence",
                    Description: $"Outstanding performance in {cat}, beating the area average by over 10 points."));
            }
        }

        // Rule 5: OAP_HIGH
        if (overdueAPs > 0)
        {
            insights.Add(new ActionableInsight(
                Id: "ins_oap_high",
                Type: "warning",
                Title: "Overdue Action Plans",
                Description: $"You have {overdueAPs} overdue action plans. Please resolve them to maintain compliance."));
        }

        // Enforce Cap
        var cappedInsights = insights.Take(3).ToList();

        return new GenerationResult(cappedInsights, radarData);
    }
}
