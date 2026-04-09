using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin.Roles;

/// <summary>
/// DELETE /api/admin/roles/{role}/capabilities/{capability}
/// Idempotent atomic revoke: removes a single capability from a role.
/// Returns 204 even if the row does not exist (delete 0 rows = success).
/// AC-10: Revoke of admin:manage_roles from admin role is blocked (self-lockout guard).
/// Auth: RequireCapability("admin:manage_roles").
/// </summary>
public static class RevokeCapability
{
    private static readonly string[] KnownRoles =
        ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        string role,
        string capability,
        AppDbContext db,
        PbacDictionaryCache pbacCache,
        IServiceProvider sp,
        CancellationToken ct)
    {
        // AC-11: Role must be exact lowercase match.
        if (!KnownRoles.Contains(role, StringComparer.Ordinal))
            return TypedResults.BadRequest($"Unknown role '{role}'. Valid roles: {string.Join(", ", KnownRoles)}");

        // Capability must exist in the catalog (prevents garbage path params).
        if (!GetCapabilityCatalog.Catalog.Contains(capability, StringComparer.Ordinal))
            return TypedResults.BadRequest($"Unknown capability '{capability}'.");

        // AC-10: Self-lockout guard — cannot revoke admin:manage_roles from the admin role.
        if (role == "admin" && capability == "admin:manage_roles")
            return TypedResults.BadRequest(
                "Cannot revoke 'admin:manage_roles' from the 'admin' role. " +
                "This would permanently lock all admins out of the Admin Dashboard.");

        // Idempotent delete — 0 rows deleted is still success.
        await db.RoleCapabilities
            .Where(rc => rc.Role == role && rc.Capability == capability)
            .ExecuteDeleteAsync(ct);

        // Belt-and-suspenders: immediately reload cache.
        await pbacCache.InitializeAsync(sp);

        return TypedResults.NoContent();
    }
}
