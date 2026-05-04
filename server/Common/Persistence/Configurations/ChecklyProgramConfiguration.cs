using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ChecklyProgramConfiguration : IEntityTypeConfiguration<ChecklyProgram>
{
    public void Configure(EntityTypeBuilder<ChecklyProgram> e)
    {
        e.ToTable("programs");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
        e.Property(x => x.Title).HasColumnName("title").IsRequired().HasMaxLength(200);
        e.Property(x => x.Category).HasColumnName("category").IsRequired().HasMaxLength(100);
        e.Property(x => x.Deadline).HasColumnName("deadline").IsRequired();
        e.Property(x => x.Status).HasColumnName("status").HasDefaultValue("active");
        e.Property(x => x.CreatedBy).HasColumnName("created_by").IsRequired();
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

        // Optimistic concurrency via PostgreSQL system column xmin
        e.Property(x => x.RowVersion)
            .HasColumnName("xmin")
            .HasColumnType("xid")
            .ValueGeneratedOnAddOrUpdate()
            .IsConcurrencyToken();

        // FK: Program → Template (restrict: cannot delete a template that has programs)
        e.HasOne(x => x.Template)
            .WithMany()
            .HasForeignKey(x => x.TemplateId)
            .OnDelete(DeleteBehavior.Restrict);

        // Performance indexes
        e.HasIndex(x => x.Status);
        e.HasIndex(x => x.Deadline);
        e.HasIndex(x => x.CreatedBy);
        e.HasIndex(x => x.CreatedAt).IsDescending();
    }
}
