using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class SubmissionConfiguration : IEntityTypeConfiguration<Submission>
{
    public void Configure(EntityTypeBuilder<Submission> e)
    {

        e.ToTable("submissions");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.TemplateId).HasColumnName("template_id");
        e.Property(x => x.AuditorId).HasColumnName("auditor_id");
        e.Property(x => x.StoreId).HasColumnName("store_id");
        e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("draft");
        e.Property(x => x.ScoringMode).HasColumnName("scoring_mode").HasDefaultValue("penalty");
        e.Property(x => x.TotalScore).HasColumnName("total_score");
        e.Property(x => x.SectionScores).HasColumnName("section_scores").HasColumnType("jsonb");
        e.Property(x => x.GpsLat).HasColumnName("gps_lat");
        e.Property(x => x.GpsLng).HasColumnName("gps_lng");
        e.Property(x => x.GpsVerifiedAt).HasColumnName("gps_verified_at");
        e.Property(x => x.Notes).HasColumnName("notes");
        e.Property(x => x.ScheduledAt).HasColumnName("scheduled_at");
        e.Property(x => x.CompletedAt).HasColumnName("completed_at");
        e.Property(x => x.ApprovedBy).HasColumnName("approved_by");
        e.Property(x => x.ApprovedAt).HasColumnName("approved_at");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.StartedAt).HasColumnName("started_at");
        e.Property(x => x.AuditorName).HasColumnName("auditor_name");
        e.Property(x => x.AuditorEmail).HasColumnName("auditor_email");
        e.Property(x => x.StoreName).HasColumnName("store_name");
        e.Property(x => x.TemplateTitle).HasColumnName("template_title");
        e.Property(x => x.TemplateType).HasColumnName("template_type");
        e.Property(x => x.DisplayNoun).HasColumnName("display_noun");
        e.Property(x => x.ApproverName).HasColumnName("approver_name");
        e.Property(x => x.ReviewStatus).HasColumnName("review_status");
        e.Property(x => x.IdempotencyKey).HasColumnName("idempotency_key");
        e.Property(x => x.TemplateSnapshot).HasColumnName("template_snapshot").HasColumnType("jsonb");
        e.Property(x => x.TemplateVersion).HasColumnName("template_version");
        e.Property(x => x.RawEarnedPoints).HasColumnName("raw_earned_points");
        e.Property(x => x.RawMaxPoints).HasColumnName("raw_max_points");
        e.Property(x => x.IsWeighted).HasColumnName("is_weighted");
        e.Property(x => x.VoidReason).HasColumnName("void_reason");
        e.Property(x => x.VoidedAt).HasColumnName("voided_at");

        // Optimistic concurrency via PostgreSQL system column xmin
        // Guards against TOCTOU race on concurrent FinalizeSubmission requests (F7)
        e.Property(x => x.RowVersion)
            .HasColumnName("xmin")
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();

        e.HasIndex(x => x.IdempotencyKey)
            .IsUnique()
            .HasFilter("idempotency_key IS NOT NULL");

        // Performance indexes
        e.HasIndex(x => x.AuditorId);
        e.HasIndex(x => x.CreatedAt).IsDescending();
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
        e.HasIndex(x => new { x.Status, x.ReviewStatus });
        e.HasIndex(x => new { x.StoreId, x.CreatedAt }).IsDescending(false, true);
        e.HasIndex(x => new { x.TemplateId, x.ScoringMode });

        e.HasOne(x => x.Template)
            .WithMany(t => t.Submissions)
            .HasForeignKey(x => x.TemplateId)
            .OnDelete(DeleteBehavior.SetNull);

        e.HasOne(x => x.Store)
            .WithMany(s => s.Submissions)
            .HasForeignKey(x => x.StoreId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
