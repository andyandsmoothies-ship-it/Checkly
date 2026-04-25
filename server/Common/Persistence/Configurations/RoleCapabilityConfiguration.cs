using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class RoleCapabilityConfiguration : IEntityTypeConfiguration<RoleCapability>
{
    public void Configure(EntityTypeBuilder<RoleCapability> e)
    {

        e.ToTable("role_capabilities");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.Role).HasColumnName("role").IsRequired().HasMaxLength(50);
        e.Property(x => x.Capability).HasColumnName("capability").IsRequired().HasMaxLength(100);
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // Composite unique constraint: one capability string per role
        e.HasIndex(x => new { x.Role, x.Capability })
            .IsUnique()
            .HasDatabaseName("UX_role_capabilities_role_capability");

        // Performance index: cache warm-up queries by role
        e.HasIndex(x => x.Role)
            .HasDatabaseName("IX_role_capabilities_role");
    }
}
