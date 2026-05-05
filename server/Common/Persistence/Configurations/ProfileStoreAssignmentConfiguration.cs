using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

/// <summary>
/// EF Core configuration for the ProfileStoreAssignment junction table.
/// Uses a composite PK (ProfileId, StoreId) — no surrogate Id.
/// Profile delete → CASCADE; Store delete → RESTRICT (prevents orphaned access grants).
/// </summary>
public sealed class ProfileStoreAssignmentConfiguration : IEntityTypeConfiguration<ProfileStoreAssignment>
{
    public void Configure(EntityTypeBuilder<ProfileStoreAssignment> e)
    {
        e.ToTable("profile_store_assignments");

        // Composite PK
        e.HasKey(x => new { x.ProfileId, x.StoreId });

        // Strict 1-to-M constraint: A store can only be assigned to one Area Manager
        e.HasIndex(x => x.StoreId).IsUnique();

        e.Property(x => x.ProfileId).HasColumnName("profile_id").IsRequired();
        e.Property(x => x.StoreId).HasColumnName("store_id").IsRequired();
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // FK: deleting a Profile cascades and removes their store assignments.
        e.HasOne(x => x.Profile)
            .WithMany(p => p.StoreAssignments)
            .HasForeignKey(x => x.ProfileId)
            .OnDelete(DeleteBehavior.Cascade);

        // FK: RESTRICT — cannot delete a Store that has active AM assignments.
        // This protects against accidental store removal breaking AM access.
        e.HasOne(x => x.Store)
            .WithMany(s => s.AssignedManagers)
            .HasForeignKey(x => x.StoreId)
            .OnDelete(DeleteBehavior.Restrict);
    }
}
