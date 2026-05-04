namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Store locations with GPS. Soft delete via IsActive.
/// Maps to: public.stores (9 columns)
/// </summary>
public sealed class Store
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string? Address { get; set; }
    public Guid? AreaId { get; set; }
    public decimal? GpsLat { get; set; }
    public decimal? GpsLng { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public bool? IsActive { get; set; }

    // Navigation properties
    public Area? Area { get; set; }
    public ICollection<Profile> Profiles { get; set; } = [];
    public ICollection<Submission> Submissions { get; set; } = [];
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
    public ICollection<ProfileStoreAssignment> AssignedManagers { get; set; } = [];
}
