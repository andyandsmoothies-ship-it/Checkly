using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin.Roles;

/// <summary>
/// GET /api/admin/roles
/// Returns all 4 known system roles, each with their live capability assignments from the DB.
/// Reads directly from role_capabilities (not the cache) so admins always see persisted truth.
/// Auth: RequireCapability("admin:manage_roles") — only admins with this capability may read.
/// </summary>
public static class GetRoles
{
    /// <summary>All system roles — supplement DB results with roles that have no capabilities yet.</summary>
    private static readonly string[] KnownRoles =
        ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        CancellationToken ct)
    {
        var rows = await db.RoleCapabilities
            .AsNoTracking()
            .GroupBy(r => r.Role)
            .Select(g => new RoleWithCapabilitiesDto(g.Key, g.Select(r => r.Capability).ToArray()))
            .ToListAsync(ct);

        // Supplement: ensure all 4 known roles appear even if they have no capabilities
        var rolesWithData = rows.ToDictionary(r => r.Role, r => r.Capabilities);

        var result = KnownRoles
            .Select(role => new RoleWithCapabilitiesDto(
                role,
                rolesWithData.TryGetValue(role, out var caps) ? caps : []))
            .ToList();

        return TypedResults.Ok(result);
    }
}

/// <summary>DTO for GET /api/admin/roles response.</summary>
public sealed record RoleWithCapabilitiesDto(string Role, string[] Capabilities);
