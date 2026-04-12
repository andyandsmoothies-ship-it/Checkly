using Microsoft.AspNetCore.Identity;

namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// ASP.NET Identity user entity. Extends IdentityUser with Guid keys.
/// Links 1:1 to Profile via shared primary key (AppUser.Id = Profile.Id).
/// </summary>
public sealed class AppUser : IdentityUser<Guid>
{
    // Navigation: 1:1 with Profile (same Id)
    public Profile? Profile { get; set; }

    /// <summary>
    /// If set, any JWT token issued BEFORE this timestamp is immediately rejected.
    /// Stamped with UtcNow when an admin changes this user's role via UpdateUser.
    /// </summary>
    public DateTimeOffset? InvalidateTokensBefore { get; set; }
}
