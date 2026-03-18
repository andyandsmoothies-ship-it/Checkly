namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Junction table linking profiles to user groups.
/// Maps to: public.user_group_members
/// Unique constraint: (UserGroupId, ProfileId)
/// </summary>
public sealed class UserGroupMember
{
    public Guid Id { get; set; }
    public Guid UserGroupId { get; set; }
    public Guid ProfileId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation properties
    public UserGroup UserGroup { get; set; } = null!;
    public Profile Profile { get; set; } = null!;
}
