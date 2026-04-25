using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class TemplateAssignmentConfiguration : IEntityTypeConfiguration<TemplateAssignment>
{
    public void Configure(EntityTypeBuilder<TemplateAssignment> e)
    {

        e.ToTable("template_assignments");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
        e.Property(x => x.UserGroupId).HasColumnName("user_group_id").IsRequired();
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        e.HasIndex(x => new { x.TemplateId, x.UserGroupId }).IsUnique();

        e.HasOne(x => x.Template)
            .WithMany(t => t.Assignments)
            .HasForeignKey(x => x.TemplateId)
            .OnDelete(DeleteBehavior.Cascade);

        e.HasOne(x => x.UserGroup)
            .WithMany(g => g.Assignments)
            .HasForeignKey(x => x.UserGroupId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
