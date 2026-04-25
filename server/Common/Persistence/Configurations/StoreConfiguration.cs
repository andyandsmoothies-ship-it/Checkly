using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class StoreConfiguration : IEntityTypeConfiguration<Store>
{
    public void Configure(EntityTypeBuilder<Store> e)
    {

        e.ToTable("stores");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.Name).HasColumnName("name").IsRequired();
        e.Property(x => x.Address).HasColumnName("address");
        e.Property(x => x.AreaId).HasColumnName("area_id");
        e.Property(x => x.GpsLat).HasColumnName("gps_lat");
        e.Property(x => x.GpsLng).HasColumnName("gps_lng");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);

        // FK: Store → Area
        e.HasOne(x => x.Area)
            .WithMany(a => a.Stores)
            .HasForeignKey(x => x.AreaId)
            .OnDelete(DeleteBehavior.SetNull);

        // Performance indexes
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
