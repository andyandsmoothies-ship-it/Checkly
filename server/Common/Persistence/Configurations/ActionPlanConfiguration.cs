using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ActionPlanConfiguration : IEntityTypeConfiguration<ActionPlan>
{
    public void Configure(EntityTypeBuilder<ActionPlan> e)
    {

        e.ToTable("action_plans");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.AnswerId).HasColumnName("answer_id");
        e.Property(x => x.SubmissionId).HasColumnName("submission_id");
        e.Property(x => x.StoreId).HasColumnName("store_id");
        e.Property(x => x.StoreManagerId).HasColumnName("store_manager_id");
        e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label").IsRequired();
        e.Property(x => x.GroupTitle).HasColumnName("group_title").IsRequired();
        e.Property(x => x.PlanDescription).HasColumnName("plan_description");
        e.Property(x => x.EvidencePhotoUrl).HasColumnName("evidence_photo_url");
        e.Property(x => x.EvidenceNote).HasColumnName("evidence_note");
        e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("open");
        e.Property(x => x.Deadline).HasColumnName("deadline");
        e.Property(x => x.ClosedAt).HasColumnName("closed_at");
        e.Property(x => x.VerifiedBy).HasColumnName("verified_by");
        e.Property(x => x.VerifiedAt).HasColumnName("verified_at");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.RootCause).HasColumnName("root_cause");
        e.Property(x => x.CorrectionPlan).HasColumnName("correction_plan");
        e.Property(x => x.StoreName).HasColumnName("store_name");
        e.Property(x => x.StoreManagerName).HasColumnName("store_manager_name");
        e.Property(x => x.VerifierName).HasColumnName("verifier_name");
        e.Property(x => x.EvidenceSubmittedAt).HasColumnName("evidence_submitted_at");
        e.Property(x => x.EvidenceSubmittedByName).HasColumnName("evidence_submitted_by_name");

        e.HasOne(x => x.Answer)
            .WithMany(a => a.ActionPlans)
            .HasForeignKey(x => x.AnswerId)
            .OnDelete(DeleteBehavior.SetNull);

        e.HasOne(x => x.Submission)
            .WithMany(s => s.ActionPlans)
            .HasForeignKey(x => x.SubmissionId)
            .OnDelete(DeleteBehavior.SetNull);

        e.HasOne(x => x.Store)
            .WithMany(s => s.ActionPlans)
            .HasForeignKey(x => x.StoreId)
            .OnDelete(DeleteBehavior.SetNull);

        // Unique constraint: prevents duplicate APs for the same (submission, answer) under race conditions
        e.HasIndex(x => new { x.SubmissionId, x.AnswerId })
            .IsUnique()
            .HasFilter("submission_id IS NOT NULL AND answer_id IS NOT NULL");

        // Performance indexes
        e.HasIndex(x => new { x.StoreId, x.Status });
        e.HasIndex(x => x.Deadline);
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
