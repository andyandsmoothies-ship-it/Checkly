namespace Checkly.Api.Features.Analytics;

/// <summary>Analytics endpoint DTOs.</summary>

public sealed record AnalyticsKpis(
    int TotalAudits,
    int TotalScored,
    int TotalSurveys,
    double AvgScore,
    int OpenAPs,
    int OverdueAPs,
    double CompletionRate);

public sealed record TrendPoint(
    string Month,
    double AvgScore,
    int Count);

public sealed record SectionScore(
    string Section,
    double AvgScore,
    int Count);

public sealed record AnalyticsResponse(
    AnalyticsKpis Kpis,
    List<TrendPoint> Trend,
    List<SectionScore> SectionBreakdown);
