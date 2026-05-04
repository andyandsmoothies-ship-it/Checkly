using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace Checkly.Api.Common.Persistence.Configurations;

public class AppUserConfiguration : IEntityTypeConfiguration<AppUser>
{
    public void Configure(EntityTypeBuilder<AppUser> e)
    {
        // Profile ↔ AppUser: logically 1:1 via matching Id
        // NOT enforced by FK — Profiles can exist without AppUser rows
        // (e.g., test seeding, offline-created profiles, SQL migration data)
        // The registration flow ensures both records are created together.
        e.Ignore(u => u.Profile);

        // F2 Fix: snake_case column mapping for the revocation timestamp.
        // EF Identity would default to "InvalidateTokensBefore" (PascalCase) without this.
        e.Property(u => u.InvalidateTokensBefore)
            .HasColumnName("invalidate_tokens_before");
    }
}
