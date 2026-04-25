using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class GlobalRiskConfiguration : IEntityTypeConfiguration<GlobalRisk>
{
    public void Configure(EntityTypeBuilder<GlobalRisk> e)
    {

        e.ToTable("global_risks");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.Label).HasColumnName("label").IsRequired().HasMaxLength(200);
        e.Property(x => x.Description).HasColumnName("description");
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

        // Performance indexes
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
    }
}
