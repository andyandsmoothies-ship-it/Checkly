namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Company-wide risk flags that auditors can trigger independently of audit templates.
/// Maps to: public.global_risks (6 columns)
/// </summary>
public sealed class GlobalRisk
{
    public Guid Id { get; set; }
    public string Label { get; set; } = string.Empty;
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation properties
    public ICollection<SubmissionRisk> SubmissionRisks { get; set; } = [];
}
