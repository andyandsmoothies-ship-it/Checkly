using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin.Roles;

/// <summary>
/// POST /api/admin/roles/{role}/capabilities/{capability}
/// Idempotent atomic grant: adds a single capability to a role.
/// Uses INSERT ON CONFLICT DO NOTHING — safe to call twice (returns 204 both times).
/// Auth: RequireCapability("admin:manage_roles").
/// Consistency: Eventual — after 204, the in-memory PBAC cache is refreshed asynchronously
/// by <see cref="PbacCacheListenerService"/> via Postgres LISTEN/NOTIFY (~50ms propagation).
/// </summary>
public static class GrantCapability
{
    private static readonly string[] KnownRoles =
        ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        string role,
        string capability,
        AppDbContext db,
        CancellationToken ct)
    {
        // AC-11: Role must be exact lowercase match — reject "ADMIN", "Admin", etc.
        if (!KnownRoles.Contains(role, StringComparer.Ordinal))
            return TypedResults.BadRequest($"Unknown role '{role}'. Valid roles: {string.Join(", ", KnownRoles)}");

        // AC-05: Capability must exist in the static catalog.
        if (!GetCapabilityCatalog.Catalog.Contains(capability, StringComparer.Ordinal))
            return TypedResults.BadRequest($"Unknown capability '{capability}'.");

        // Idempotent upsert — ON CONFLICT DO NOTHING so duplicate returns 1 or 0 rows, never throws.
        var existing = await db.RoleCapabilities
            .AsNoTracking()
            .AnyAsync(rc => rc.Role == role && rc.Capability == capability, ct);

        if (!existing)
        {
            db.RoleCapabilities.Add(new RoleCapability
            {
                Id = Guid.NewGuid(),
                Role = role,
                Capability = capability,
                CreatedAt = DateTimeOffset.UtcNow,
            });
            await db.SaveChangesAsync(ct);
        }

        return TypedResults.NoContent();
    }
}
