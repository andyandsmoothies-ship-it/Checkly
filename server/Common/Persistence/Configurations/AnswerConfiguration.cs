using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class AnswerConfiguration : IEntityTypeConfiguration<Answer>
{
    public void Configure(EntityTypeBuilder<Answer> e)
    {

        e.ToTable("answers");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.SubmissionId).HasColumnName("submission_id");
        e.Property(x => x.CriteriaId).HasColumnName("criteria_id");
        e.Property(x => x.Value).HasColumnName("value");
        e.Property(x => x.NumericValue).HasColumnName("numeric_value");
        e.Property(x => x.Note).HasColumnName("note");
        e.Property(x => x.PhotoUrl).HasColumnName("photo_url");
        e.Property(x => x.PhotoMetadata).HasColumnName("photo_metadata").HasColumnType("jsonb");
        e.Property(x => x.IsRepeatedError).HasColumnName("is_repeated_error").HasDefaultValue(false);
        e.Property(x => x.IsCcp).HasColumnName("is_ccp").HasDefaultValue(false);
        e.Property(x => x.IsRisk).HasColumnName("is_risk").HasDefaultValue(false);
        e.Property(x => x.IsFailure).HasColumnName("is_failure").HasDefaultValue(false);
        e.Property(x => x.RepeatedFaults).HasColumnName("repeated_faults").HasDefaultValue(0);
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
        e.Property(x => x.CriteriaLabel).HasColumnName("criteria_label");

        e.HasOne(x => x.Submission)
            .WithMany(s => s.Answers)
            .HasForeignKey(x => x.SubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        e.HasOne(x => x.Criterion)
            .WithMany(c => c.Answers)
            .HasForeignKey(x => x.CriteriaId)
            .OnDelete(DeleteBehavior.SetNull);

        // Composite index for fast Top Failures analytics query (concept brief Phase A mandate)
        e.HasIndex(x => new { x.IsFailure, x.CriteriaId })
            .HasDatabaseName("IX_answers_is_failure_criteria_id");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
