namespace Checkly.Api.Common.Persistence.Entities;

public sealed class Area
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Code { get; set; } = string.Empty;
    public bool IsActive { get; set; } = true;
    public DateTimeOffset CreatedAt { get; set; }
    public DateTimeOffset UpdatedAt { get; set; }

    // Navigation collections
    public ICollection<Store> Stores { get; set; } = [];
    public ICollection<Profile> Profiles { get; set; } = [];
}
