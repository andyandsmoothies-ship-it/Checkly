namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// User metadata. id = auth.users.id (FK deferred to Slice 2).
/// Maps to: public.profiles (8 columns)
/// </summary>
public sealed class Profile
{
    public Guid Id { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string? AvatarUrl { get; set; }
    public Guid? StoreId { get; set; }
    public string? AreaCode { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation properties
    public Store? Store { get; set; }
}
