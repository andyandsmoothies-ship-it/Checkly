using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ProgramEvidenceConfiguration : IEntityTypeConfiguration<ProgramEvidence>
{
    public void Configure(EntityTypeBuilder<ProgramEvidence> e)
    {
        e.ToTable("program_evidence");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.AssignmentId).HasColumnName("assignment_id").IsRequired();
        e.Property(x => x.CriteriaId).HasColumnName("criteria_id");
        e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label").HasMaxLength(500);
        e.Property(x => x.Value).HasColumnName("value").IsRequired();
        e.Property(x => x.PhotoLocalKey).HasColumnName("photo_local_key");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // FK: ProgramEvidence → ProgramAssignment (cascade: deleting an assignment deletes its evidence)
        e.HasOne(x => x.Assignment)
            .WithMany()
            .HasForeignKey(x => x.AssignmentId)
            .OnDelete(DeleteBehavior.Cascade);

        e.HasIndex(x => x.AssignmentId);
    }
}
