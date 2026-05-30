using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class BodReportSnapshotConfiguration : IEntityTypeConfiguration<BodReportSnapshot>
{
    public void Configure(EntityTypeBuilder<BodReportSnapshot> e)
    {
        e.ToTable("bod_report_snapshots");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");

        e.Property(x => x.Date)
            .HasColumnName("date")
            .IsRequired();

        e.HasIndex(x => x.Date)
            .IsUnique();

        e.Property(x => x.ComputedAt)
            .HasColumnName("computed_at")
            .IsRequired();

        e.Property(x => x.Status)
            .HasColumnName("status")
            .HasMaxLength(20)
            .IsRequired();

        e.Property(x => x.Payload)
            .HasColumnName("payload")
            .HasColumnType("jsonb")
            .IsRequired();
    }
}
