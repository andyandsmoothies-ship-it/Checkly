namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Pre-computed province-level benchmark snapshot.
/// Maps to: public.province_benchmark_snapshots
/// PK is the GSO province name string (e.g. "Hồ Chí Minh").
/// Replaces AreaBenchmarkSnapshot (SL-2).
/// </summary>
public sealed class ProvinceBenchmarkSnapshot
{
    public string Province { get; set; } = string.Empty;
    public string CategoryAverages { get; set; } = string.Empty; // jsonb
    public decimal OverallAvgScore { get; set; }
    public decimal StdDeviation { get; set; }
    public int TotalAuditCount { get; set; }
    public DateTimeOffset LastCalculatedAt { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
