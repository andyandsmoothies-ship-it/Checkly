using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class SubmissionRiskConfiguration : IEntityTypeConfiguration<SubmissionRisk>
{
    public void Configure(EntityTypeBuilder<SubmissionRisk> e)
    {

        e.ToTable("submission_risks");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.SubmissionId).HasColumnName("submission_id").IsRequired();
        e.Property(x => x.GlobalRiskId).HasColumnName("global_risk_id").IsRequired();
        e.Property(x => x.TriggeredById).HasColumnName("triggered_by_id");
        e.Property(x => x.Note).HasColumnName("note");
        e.Property(x => x.TriggeredAt).HasColumnName("triggered_at");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // FK: submission_id → submissions (cascade: deleting submission deletes its risks)
        e.HasOne(x => x.Submission)
            .WithMany(s => s.SubmissionRisks)
            .HasForeignKey(x => x.SubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        // FK: global_risk_id → global_risks (restrict: cannot delete a risk that has been triggered)
        e.HasOne(x => x.GlobalRisk)
            .WithMany(r => r.SubmissionRisks)
            .HasForeignKey(x => x.GlobalRiskId)
            .OnDelete(DeleteBehavior.Restrict);

        // Unique constraint: prevents double-triggering same risk on a submission
        e.HasIndex(x => new { x.SubmissionId, x.GlobalRiskId }).IsUnique();

        // Performance indexes
        e.HasIndex(x => x.SubmissionId);
        e.HasIndex(x => x.GlobalRiskId);
    }
}
