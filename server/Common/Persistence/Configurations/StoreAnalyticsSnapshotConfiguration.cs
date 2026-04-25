using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class StoreAnalyticsSnapshotConfiguration : IEntityTypeConfiguration<StoreAnalyticsSnapshot>
{
    public void Configure(EntityTypeBuilder<StoreAnalyticsSnapshot> e)
    {

        e.ToTable("store_analytics_snapshot");
        e.HasKey(x => x.StoreId);
        e.Property(x => x.StoreId).HasColumnName("store_id");
        e.Property(x => x.AvgScore30d).HasColumnName("avg_score_30d");
        e.Property(x => x.TotalAudits30d).HasColumnName("total_audits_30d");
        e.Property(x => x.OpenActionPlans).HasColumnName("open_action_plans").HasDefaultValue(0);
        e.Property(x => x.OverdueActionPlans).HasColumnName("overdue_action_plans").HasDefaultValue(0);
        e.Property(x => x.LastAuditScore).HasColumnName("last_audit_score");
        e.Property(x => x.LastAuditAt).HasColumnName("last_audit_at");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

        e.HasOne(x => x.Store)
            .WithOne()
            .HasForeignKey<StoreAnalyticsSnapshot>(x => x.StoreId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
