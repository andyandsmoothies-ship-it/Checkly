using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class GroupConfiguration : IEntityTypeConfiguration<Group>
{
    public void Configure(EntityTypeBuilder<Group> e)
    {

        e.ToTable("groups");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.TemplateId).HasColumnName("template_id").IsRequired();
        e.Property(x => x.Title).HasColumnName("title").IsRequired();
        e.Property(x => x.Description).HasColumnName("description");
        e.Property(x => x.Weight).HasColumnName("weight");
        e.Property(x => x.MaxDeductionPoints).HasColumnName("max_deduction_points");
        e.Property(x => x.MinusPerFault).HasColumnName("minus_per_fault");
        e.Property(x => x.OrderIndex).HasColumnName("order_index").HasDefaultValue(0);
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.ParentId).HasColumnName("parent_id");
        e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);
        e.Property(x => x.CategoryTags).HasColumnName("category_tags");

        e.HasOne(x => x.Template)
            .WithMany(t => t.Groups)
            .HasForeignKey(x => x.TemplateId)
            .OnDelete(DeleteBehavior.Cascade);

        e.HasOne(x => x.Parent)
            .WithMany(g => g.Children)
            .HasForeignKey(x => x.ParentId)
            .OnDelete(DeleteBehavior.Restrict);

        // Performance indexes
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
