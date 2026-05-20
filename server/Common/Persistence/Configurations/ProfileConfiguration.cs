using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class ProfileConfiguration : IEntityTypeConfiguration<Profile>
{
    public void Configure(EntityTypeBuilder<Profile> e)
    {

        e.ToTable("profiles");
        e.HasKey(x => x.Id);
        e.Property(x => x.Id).HasColumnName("id");
        e.Property(x => x.FullName).HasColumnName("full_name");
        e.Property(x => x.Email).HasColumnName("email");
        e.Property(x => x.AvatarUrl).HasColumnName("avatar_url");
        e.Property(x => x.StoreId).HasColumnName("store_id");
        e.Property(x => x.CreatedAt).HasColumnName("created_at").HasDefaultValueSql("now()");
        e.Property(x => x.UpdatedAt).HasColumnName("updated_at").HasDefaultValueSql("now()");

        e.HasOne(x => x.Store)
            .WithMany(s => s.Profiles)
            .HasForeignKey(x => x.StoreId)
            .OnDelete(DeleteBehavior.SetNull);
    }
}
