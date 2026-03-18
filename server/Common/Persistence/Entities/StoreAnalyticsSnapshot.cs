namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Pre-computed store-level analytics snapshot.
/// Upserted during FinalizeSubmission — one row per store.
/// Maps to: public.store_analytics_snapshot
/// </summary>
public sealed class StoreAnalyticsSnapshot
{
    public Guid StoreId { get; set; }
    public decimal AvgScore30d { get; set; }
    public int TotalAudits30d { get; set; }
    public int OpenActionPlans { get; set; }
    public int OverdueActionPlans { get; set; }
    public decimal? LastAuditScore { get; set; }
    public DateTimeOffset? LastAuditAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation
    public Store? Store { get; set; }
}
