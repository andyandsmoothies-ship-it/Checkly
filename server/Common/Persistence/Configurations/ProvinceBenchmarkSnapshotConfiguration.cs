using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ProvinceBenchmarkSnapshotConfiguration : IEntityTypeConfiguration<ProvinceBenchmarkSnapshot>
{
    public void Configure(EntityTypeBuilder<ProvinceBenchmarkSnapshot> e)
    {
        e.ToTable("province_benchmark_snapshots");
        e.HasKey(x => x.Province);

        e.Property(x => x.Province).HasColumnName("province").HasMaxLength(200);
        e.Property(x => x.CategoryAverages).HasColumnName("category_avgs").HasColumnType("jsonb");
        e.Property(x => x.OverallAvgScore).HasColumnName("overall_avg");
        e.Property(x => x.StdDeviation).HasColumnName("std_deviation");
        e.Property(x => x.TotalAuditCount).HasColumnName("total_audits");
        e.Property(x => x.LastCalculatedAt).HasColumnName("last_calc_at");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
    }
}
