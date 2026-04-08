namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Maps roles to fine-grained capability strings.
/// Maps to: public.role_capabilities (4 columns)
/// Capability format: "{domain}:{action}" e.g. "templates:create"
/// Seeded once on startup; invalidation via LISTEN/NOTIFY in Slice 3.
/// </summary>
public sealed class RoleCapability
{
    public Guid Id { get; set; }
    public string Role { get; set; } = string.Empty;         // e.g. "admin"
    public string Capability { get; set; } = string.Empty;   // e.g. "templates:create"
    public DateTimeOffset CreatedAt { get; set; }
}
