namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Audit questions within a template.
/// Maps to: public.criteria (13 columns)
/// Valid InputType values: 'pass_fail', 'scale', 'numeric', 'single_choice', 'multi_choice', 'text', 'photo', 'signature', 'barcode'
/// </summary>
public sealed class Criterion
{
    public Guid Id { get; set; }
    public Guid GroupId { get; set; }
    public string Label { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string InputType { get; set; } = string.Empty;
    public decimal? PointsWeight { get; set; }
    public bool IsCcp { get; set; }
    public bool IsRisk { get; set; }
    public decimal? MinusImpact { get; set; }
    public decimal? MaxDeductionPoints { get; set; }
    public int OrderIndex { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public string? Metadata { get; set; }
    public bool IsActive { get; set; }
    public List<string>? CategoryTags { get; set; }

    // Navigation properties
    public Group Group { get; set; } = null!;
    public ICollection<Answer> Answers { get; set; } = [];
}
