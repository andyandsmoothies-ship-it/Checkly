using Checkly.Api.Features.Analytics;

namespace Checkly.Api.Tests.Features.Analytics;

/// <summary>
/// Unit tests for InsightGeneratorService (Slice 2, TDD RED phase).
/// Tests: IG-02, IG-03, IG-08.
/// Workflow: /tdd
/// 
/// Test Plan:
///   - IG-02: High-score store produces a "positive" insight (SCORE_POSITIVE rule)
///   - IG-03: Low-score store produces a "warning" insight (SCORE_DROP_WARNING rule)
///   - IG-08: All 5 rules fire simultaneously → capped at 3 insights max
/// 
/// InsightGeneratorService.Generate() is STATIC — no DB, no HTTP. Pure math.
/// </summary>
public class InsightGeneratorTests
{
    // ── IG-02 ─────────────────────────────────────────────────────────────────
    [Fact]
    public void Generate_StoreScoreWellAboveAreaAvg_ReturnsPositiveInsight()
    {
        // Arrange — store score > areaAvg + stdDev (rule 2: SCORE_POSITIVE)
        // areaAvg=80, stdDev=10, liveScore=95 → 95 > 80+10=90 ✓
        var result = InsightGeneratorService.Generate(
            liveScore: 95.0,
            areaAvgScore: 80.0,
            stdDeviation: 10.0,
            totalAudits: 5,
            storeCategoryAverages: new Dictionary<string, double> { ["Safety"] = 90.0 },
            areaCategoryAverages: new Dictionary<string, double> { ["Safety"] = 80.0 },
            overdueAPs: 0
        );

        // Assert
        Assert.NotNull(result);
        Assert.NotEmpty(result.Insights);
        Assert.Contains(result.Insights, i => i.Type == "positive" && i.Id == "ins_top_performer");
    }

    // ── IG-03 ─────────────────────────────────────────────────────────────────
    [Fact]
    public void Generate_StoreScoreWellBelowAreaAvg_ReturnsWarningInsight()
    {
        // Arrange — liveScore < areaAvg - 1.5*stdDev (rule 1: SCORE_DROP_WARNING)
        // areaAvg=80, stdDev=10, threshold=80-15=65, liveScore=55 ✓
        var result = InsightGeneratorService.Generate(
            liveScore: 55.0,
            areaAvgScore: 80.0,
            stdDeviation: 10.0,
            totalAudits: 5,
            storeCategoryAverages: new Dictionary<string, double> { ["Safety"] = 60.0 },
            areaCategoryAverages: new Dictionary<string, double> { ["Safety"] = 80.0 },
            overdueAPs: 0
        );

        // Assert
        Assert.NotNull(result);
        Assert.NotEmpty(result.Insights);
        Assert.Contains(result.Insights, i => i.Type == "warning" && i.Id == "ins_score_drop");
    }

    // ── IG-08 ─────────────────────────────────────────────────────────────────
    [Fact]
    public void Generate_AllFiveRulesFire_ReturnsMaxThreeInsights()
    {
        // Arrange — construct a scenario where all 5 rules fire:
        // Rule 1 (SCORE_DROP_WARNING): liveScore=55 < 80-(1.5*10)=65 ✓
        // Rule 2 (SCORE_POSITIVE): NOT fired (score too low), so we pick a mid-range score
        // — to fire BOTH 1 and 2 is impossible by math; fire rules 1,3,4,5 instead
        // Rule 1: score low → warning (ins_score_drop)
        // Rule 3 (CATEGORY_WEAK): storeRatio=40, areaRatio=80 → 40 < 80-10=70 ✓ → ins_cat_weak_Safety
        // Rule 4 (CATEGORY_STRONG): storeRatio=95, areaRatio=80 → 95 > 80+10=90 ✓ → ins_cat_strong_Hygiene
        // Rule 5 (OAP_HIGH): overdueAPs=3 > 0 ✓ → ins_oap_high
        // That's 4 rules firing → result must be capped at 3
        var result = InsightGeneratorService.Generate(
            liveScore: 55.0,
            areaAvgScore: 80.0,
            stdDeviation: 10.0,
            totalAudits: 5,
            storeCategoryAverages: new Dictionary<string, double>
            {
                ["Safety"] = 40.0,
                ["Hygiene"] = 95.0
            },
            areaCategoryAverages: new Dictionary<string, double>
            {
                ["Safety"] = 80.0,
                ["Hygiene"] = 80.0
            },
            overdueAPs: 3
        );

        // Assert — cap enforced
        Assert.NotNull(result);
        Assert.True(
            result.Insights.Count <= 3,
            $"Expected max 3 insights but got {result.Insights.Count}. Ids: {string.Join(", ", result.Insights.Select(i => i.Id))}"
        );
        Assert.True(result.Insights.Count > 0, "Expected at least 1 insight to fire.");
    }

    // ── RadarData suppression when < 3 categories ────────────────────────────
    [Fact]
    public void Generate_LessThanThreeCategories_ReturnsNullRadarData()
    {
        // Arrange — only 1 category key → RadarData must be suppressed (C3)
        var result = InsightGeneratorService.Generate(
            liveScore: 80.0,
            areaAvgScore: 80.0,
            stdDeviation: 10.0,
            totalAudits: 5,
            storeCategoryAverages: new Dictionary<string, double> { ["Safety"] = 80.0 },
            areaCategoryAverages: new Dictionary<string, double> { ["Safety"] = 80.0 },
            overdueAPs: 0
        );

        // Assert
        Assert.Null(result.RadarData);
    }

    // ── Sparsity guard (unit path) ────────────────────────────────────────────
    [Fact]
    public void Generate_TotalAuditsBelow3_ReturnsSingleInfoInsight()
    {
        // Arrange — totalAudits = 2 (below sparsity threshold of 3)
        var result = InsightGeneratorService.Generate(
            liveScore: 55.0,
            areaAvgScore: 80.0,
            stdDeviation: 10.0,
            totalAudits: 2,
            storeCategoryAverages: new Dictionary<string, double> { ["Safety"] = 60.0 },
            areaCategoryAverages: new Dictionary<string, double> { ["Safety"] = 80.0 },
            overdueAPs: 0
        );

        // Assert — sparsity returns exactly 1 "info" insight
        Assert.Single(result.Insights);
        Assert.Equal("info", result.Insights[0].Type);
        Assert.Null(result.RadarData);
    }
}
