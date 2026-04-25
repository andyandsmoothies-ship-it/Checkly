using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class UserDeviceTokenConfiguration : IEntityTypeConfiguration<UserDeviceToken>
{
    public void Configure(EntityTypeBuilder<UserDeviceToken> e)
    {

        e.ToTable("user_device_tokens");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id").HasDefaultValueSql("gen_random_uuid()");
        e.Property(x => x.UserId).HasColumnName("user_id").IsRequired();
        e.Property(x => x.FcmToken).HasColumnName("fcm_token").IsRequired();
        e.Property(x => x.Platform).HasColumnName("platform").IsRequired();
        e.Property(x => x.LastUsedAt).HasColumnName("last_used_at").HasDefaultValueSql("now()");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");

        e.HasIndex(x => new { x.UserId, x.FcmToken }).IsUnique();
    }
}
