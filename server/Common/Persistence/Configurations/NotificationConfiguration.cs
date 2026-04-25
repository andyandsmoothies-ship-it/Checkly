using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class NotificationConfiguration : IEntityTypeConfiguration<Notification>
{
    public void Configure(EntityTypeBuilder<Notification> e)
    {

        e.ToTable("notifications");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.UserId).HasColumnName("user_id").IsRequired();
        e.Property(x => x.Type).HasColumnName("type").IsRequired();
        e.Property(x => x.Title).HasColumnName("title").IsRequired();
        e.Property(x => x.Message).HasColumnName("message");
        e.Property(x => x.ReadAt).HasColumnName("read_at");
        e.Property(x => x.ActionUrl).HasColumnName("action_url");
        e.Property(x => x.Metadata).HasColumnName("metadata").HasColumnType("jsonb");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        // Performance indexes
        e.HasIndex(x => new { x.UserId, x.CreatedAt });
        e.HasIndex(x => new { x.UserId, x.Type });
    }
}
