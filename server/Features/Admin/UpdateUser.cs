using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// PUT /api/admin/users/{id} — update user role, store assignment, or area assignment.
/// Enforces S9 (1 SM per store) and S10 (1 AM per area).
/// </summary>
public static class UpdateUser
{
    public record Request(string? Role, Guid? StoreId, string? AreaCode);

    private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // Validate role if provided
        if (request.Role != null && !ValidRoles.Contains(request.Role))
            return TypedResults.BadRequest(new { error = $"Invalid role. Must be one of: {string.Join(", ", ValidRoles)}" });

        var profile = await db.Profiles.FirstOrDefaultAsync(p => p.Id == id, ct);
        if (profile is null)
            return TypedResults.NotFound(new { error = "User not found" });

        var userRole = await db.AppUserRoles.FirstOrDefaultAsync(r => r.UserId == id, ct);
        if (userRole is null)
            return TypedResults.NotFound(new { error = "User role not found" });

        var effectiveRole = request.Role ?? userRole.Role;

        // S9: 1 SM per store
        if (effectiveRole == "store_manager" && request.StoreId.HasValue)
        {
            var existingSm = await RoleAssignmentGuard.FindExistingStoreManager(
                db, request.StoreId.Value, id, ct);
            if (existingSm.HasValue)
                return TypedResults.Conflict(new
                {
                    error = "Store already has a store manager assigned",
                    existingManagerId = existingSm.Value
                });
        }

        // S10: 1 AM per area
        if (effectiveRole == "area_manager" && !string.IsNullOrEmpty(request.AreaCode))
        {
            var existingAm = await RoleAssignmentGuard.FindExistingAreaManager(
                db, request.AreaCode, id, ct);
            if (existingAm.HasValue)
                return TypedResults.Conflict(new
                {
                    error = "Area already has an area manager assigned",
                    existingManagerId = existingAm.Value
                });
        }

        // Apply updates
        if (request.Role != null)
            userRole.Role = request.Role;

        if (request.StoreId.HasValue)
            profile.StoreId = request.StoreId;

        if (request.AreaCode != null)
            profile.AreaCode = request.AreaCode;

        profile.UpdatedAt = DateTimeOffset.UtcNow;

        // Log the admin action
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = "update_user",
            Category = "admin",
            Message = $"Updated user {profile.FullName} ({profile.Email}): role={effectiveRole}",
            Path = $"/api/admin/users/{id}",
            Level = "info",
            CreatedAt = DateTimeOffset.UtcNow
        });

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new
        {
            id = profile.Id,
            role = userRole.Role,
            storeId = profile.StoreId,
            areaCode = profile.AreaCode,
        });
    }
}
