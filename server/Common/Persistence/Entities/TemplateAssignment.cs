namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Links a template to a user group for access control.
/// Maps to: public.template_assignments
/// Unique constraint: (TemplateId, UserGroupId)
/// </summary>
public sealed class TemplateAssignment
{
    public Guid Id { get; set; }
    public Guid TemplateId { get; set; }
    public Guid UserGroupId { get; set; }
    public DateTimeOffset CreatedAt { get; set; }

    // Navigation properties
    public Template Template { get; set; } = null!;
    public UserGroup UserGroup { get; set; } = null!;
}
