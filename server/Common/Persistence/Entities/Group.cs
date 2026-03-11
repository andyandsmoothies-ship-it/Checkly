namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Sections within a template (formerly called sections).
/// Self-referencing hierarchy via ParentId.
/// Maps to: public.groups (12 columns)
/// </summary>
public sealed class Group
{
    public Guid Id { get; set; }
    public Guid TemplateId { get; set; }
    public string Title { get; set; } = string.Empty;
    public string? Description { get; set; }
    public decimal? Weight { get; set; }
    public decimal? MaxDeductionPoints { get; set; }
    public int OrderIndex { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public Guid? ParentId { get; set; }
    public string? Metadata { get; set; }
    public bool IsActive { get; set; }

    // Navigation properties
    public Template Template { get; set; } = null!;
    public Group? Parent { get; set; }
    public ICollection<Group> Children { get; set; } = [];
    public ICollection<Criterion> Criteria { get; set; } = [];
}
