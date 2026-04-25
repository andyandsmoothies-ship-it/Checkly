using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class CriterionConfiguration : IEntityTypeConfiguration<Criterion>
{
    public void Configure(EntityTypeBuilder<Criterion> e)
    {

        e.ToTable("criteria");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.GroupId).HasColumnName("group_id").IsRequired();
        e.Property(x => x.Label).HasColumnName("label").IsRequired();
        e.Property(x => x.Description).HasColumnName("description");
        e.Property(x => x.InputType).HasColumnName("input_type").IsRequired();
        e.Property(x => x.PointsWeight).HasColumnName("points_weight").HasDefaultValue(1.0m);
        e.Property(x => x.IsCcp).HasColumnName("is_ccp").HasDefaultValue(false);
        e.Property(x => x.IsRisk).HasColumnName("is_risk").HasDefaultValue(false);
        e.Property(x => x.MinusImpact).HasColumnName("minus_impact");
        e.Property(x => x.MaxDeductionPoints).HasColumnName("max_deduction_points");
        e.Property(x => x.OrderIndex).HasColumnName("order_index").HasDefaultValue(0);
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");
        e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
        e.Property(x => x.IsActive).HasColumnName("is_active").HasDefaultValue(true);

        e.HasOne(x => x.Group)
            .WithMany(g => g.Criteria)
            .HasForeignKey(x => x.GroupId)
            .OnDelete(DeleteBehavior.Cascade);

        // Performance indexes
        e.HasIndex(x => x.IsActive).HasFilter("is_active = true");
        e.HasIndex(x => x.UpdatedAt); // For offline delta sync
    }
}
