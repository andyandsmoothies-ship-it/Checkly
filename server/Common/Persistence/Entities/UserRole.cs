namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Maps users to roles. 1:1 with profiles.
/// Maps to: public.user_roles (4 columns)
/// Role enum values: admin, auditor, store_manager, area_manager
/// </summary>
public sealed class UserRole
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
}
