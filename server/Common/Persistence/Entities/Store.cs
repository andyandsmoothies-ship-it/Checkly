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
    /// <summary>
    /// Structured address (SL-1). Owned entity maps to flat columns:
    /// address_province, address_district, address_ward, address_street.
    /// Named Address2 to avoid collision with legacy Address string.
    /// </summary>
    public StoreAddress? Address2 { get; set; }
    public decimal? GpsLat { get; set; }
    public decimal? GpsLng { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }
    public bool? IsActive { get; set; }

    // Navigation properties
    public ICollection<Profile> Profiles { get; set; } = [];
    public ICollection<Submission> Submissions { get; set; } = [];
    public ICollection<ActionPlan> ActionPlans { get; set; } = [];
    public ICollection<ProfileStoreAssignment> AssignedManagers { get; set; } = [];
}
