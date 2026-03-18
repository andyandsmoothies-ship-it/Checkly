namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// A named group of users for template-level access control.
/// Maps to: public.user_groups
/// </summary>
public sealed class UserGroup
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<UserGroupMember> Members { get; set; } = [];
    public ICollection<TemplateAssignment> Assignments { get; set; } = [];
}
