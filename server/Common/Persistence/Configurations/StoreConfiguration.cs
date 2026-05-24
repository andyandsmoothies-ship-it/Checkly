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
        e.Property(x => x.GpsLat).HasColumnName("gps_lat");
        e.Property(x => x.GpsLng).HasColumnName("gps_lng");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        e.Property(x => x.LastSyncedAt).HasColumnName("last_synced_at");


        // Performance indexes
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync

        // Province required — Province.IsRequired() inside the lambda suppresses
        // EF OptionalDependentWithoutIdentifyingPropertyWarning (Province is the identifying field).
        // Province is NOT NULL in DB — see migration MakeStoreAddressProvinceRequired.
        e.OwnsOne(x => x.Address2, a =>
        {
            a.Property(p => p.Province).HasColumnName("address_province").IsRequired();
            a.Property(p => p.District).HasColumnName("address_district");
            a.Property(p => p.Ward).HasColumnName("address_ward");
            a.Property(p => p.Street).HasColumnName("address_street");
            a.WithOwner();
        });
    }
}

