using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class SubmissionSectionScoreConfiguration : IEntityTypeConfiguration<SubmissionSectionScore>
{
    public void Configure(EntityTypeBuilder<SubmissionSectionScore> e)
    {

        e.ToTable("submission_section_scores");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.SubmissionId).HasColumnName("submission_id").IsRequired();
        e.Property(x => x.StoreId).HasColumnName("store_id");
        e.Property(x => x.TemplateId).HasColumnName("template_id");
        e.Property(x => x.SectionTitle).HasColumnName("section_title").IsRequired();
        e.Property(x => x.Score).HasColumnName("score");
        e.Property(x => x.MaxScore).HasColumnName("max_score");
        e.Property(x => x.Ratio).HasColumnName("ratio");
        e.Property(x => x.IsCcpFailed).HasColumnName("is_ccp_failed").HasDefaultValue(false);
        e.Property(x => x.Weight).HasColumnName("weight");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        e.HasOne(x => x.Submission)
            .WithMany()
            .HasForeignKey(x => x.SubmissionId)
            .OnDelete(DeleteBehavior.Cascade);

        // Performance indexes
        e.HasIndex(x => x.SubmissionId);
        e.HasIndex(x => new { x.StoreId, x.SectionTitle });
        e.HasIndex(x => x.CreatedAt);
        e.HasIndex(x => new { x.CreatedAt, x.StoreId });
    }
}
