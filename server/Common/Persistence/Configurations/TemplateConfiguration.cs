using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class TemplateConfiguration : IEntityTypeConfiguration<Template>
{
    public void Configure(EntityTypeBuilder<Template> e)
    {

        e.ToTable("templates");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.Title).HasColumnName("title").IsRequired();
        e.Property(x => x.Description).HasColumnName("description");
        e.Property(x => x.Type).HasColumnName("type").IsRequired();
        e.Property(x => x.Version).HasColumnName("version").HasDefaultValue(1);
        e.Property(x => x.ScoringLogicConfig).HasColumnName("scoring_logic_config").HasColumnType("jsonb");
        e.Property(x => x.DisplayNoun).HasColumnName("display_noun");
        e.Property(x => x.GeofenceMode).HasColumnName("geofence_mode").HasDefaultValue("none").IsRequired();
        e.Property(x => x.GeofenceRadiusMeters).HasColumnName("geofence_radius_meters").HasDefaultValue(100).IsRequired();
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        e.Property(x => x.CreatedBy).HasColumnName("created_by");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

        // Optimistic concurrency via PostgreSQL system column xmin
        e.Property(x => x.RowVersion)
            .HasColumnName("xmin")
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();

        // Performance indexes
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
