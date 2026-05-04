using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ProgramAssignmentConfiguration : IEntityTypeConfiguration<ProgramAssignment>
{
    public void Configure(EntityTypeBuilder<ProgramAssignment> e)
    {
        e.ToTable("program_assignments");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.ProgramId).HasColumnName("program_id").IsRequired();
        e.Property(x => x.StoreId).HasColumnName("store_id").IsRequired();
        e.Property(x => x.AssignedById).HasColumnName("assigned_by_id").IsRequired();
        e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("pending");
        e.Property(x => x.CompletedAt).HasColumnName("completed_at");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.RejectionComment).HasColumnName("rejection_comment");
        e.Property(x => x.VerifiedAt).HasColumnName("verified_at");

        // Optimistic concurrency via PostgreSQL system column xmin
        e.Property(x => x.RowVersion)
            .HasColumnName("xmin")
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();

        // FK: ProgramAssignment → Program (cascade: deleting a program deletes its assignments)
        e.HasOne(x => x.Program)
            .WithMany(p => p.Assignments)
            .HasForeignKey(x => x.ProgramId)
            .OnDelete(DeleteBehavior.Cascade);

        // FK: ProgramAssignment → Store (restrict: cannot delete a store that has assignments)
        e.HasOne(x => x.Store)
            .WithMany()
            .HasForeignKey(x => x.StoreId)
            .OnDelete(DeleteBehavior.Restrict);

        // Performance indexes: core query patterns
        e.HasIndex(x => new { x.ProgramId, x.Status });
        e.HasIndex(x => new { x.StoreId, x.Status });
        e.HasIndex(x => new { x.ProgramId, x.CreatedAt }).IsDescending(false, true);
        e.HasIndex(x => x.AssignedById);
    }
}
