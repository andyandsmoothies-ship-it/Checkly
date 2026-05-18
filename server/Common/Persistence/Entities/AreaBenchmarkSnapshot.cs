namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Pre-computed area-level benchmark snapshot.
/// Maps to: public.area_benchmark_snapshots
/// </summary>
public sealed class AreaBenchmarkSnapshot
{
    public Guid AreaId { get; set; }
    public string CategoryAverages { get; set; } = string.Empty; // jsonb
    public decimal OverallAvgScore { get; set; }
    public decimal StdDeviation { get; set; }
    public int TotalAuditCount { get; set; }
    public DateTimeOffset LastCalculatedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation
    public Area? Area { get; set; }
}
