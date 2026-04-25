using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class SystemLogConfiguration : IEntityTypeConfiguration<SystemLog>
{
    public void Configure(EntityTypeBuilder<SystemLog> e)
    {

        e.ToTable("system_logs");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.UserId).HasColumnName("user_id");
        e.Property(x => x.Action).HasColumnName("action").IsRequired();
        e.Property(x => x.Category).HasColumnName("category").IsRequired();
        e.Property(x => x.Message).HasColumnName("message");
        e.Property(x => x.Path).HasColumnName("path");
        e.Property(x => x.Level).HasColumnName("level").HasDefaultValue("info");
        e.Property(x => x.EntityType).HasColumnName("entity_type");
        e.Property(x => x.EntityId).HasColumnName("entity_id");
        e.Property(x => x.TraceId).HasColumnName("trace_id");
        e.Property(x => x.UserEmail).HasColumnName("user_email");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // Performance indexes
        e.HasIndex(x => x.CreatedAt).IsDescending();
        e.HasIndex(x => new { x.EntityType, x.EntityId });
    }
}
