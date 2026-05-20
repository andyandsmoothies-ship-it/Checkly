using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// POST /api/admin/users — creates a new user (Identity + Profile + UserRole).
/// Admin-only. Returns 201 with the new user DTO.
/// </summary>
public static class CreateUser
{
    public record Request(
        string Email,
        string Password,
        string FullName,
        string Role,
        Guid? StoreId = null,
        Guid[]? AssignedStoreIds = null,
        bool ForceReassign = false);

    public record Response(Guid Id, string Email, string FullName, string Role);

    private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

    public static async Task<IResult> HandleAsync(
        Request request,
        ClaimsPrincipal user,
        UserManager<AppUser> userManager,
        AppDbContext db,
        CancellationToken ct)
    {
        // 1. Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // 2. Validate role
        if (!ValidRoles.Contains(request.Role))
            return TypedResults.BadRequest(new { message = $"Invalid role. Must be one of: {string.Join(", ", ValidRoles)}" });

        // 3. Duplicate email check → 409
        var existing = await userManager.FindByEmailAsync(request.Email);
        if (existing is not null)
            return TypedResults.Conflict(new { message = "A user with this email already exists." });

        // 4. Assignment guards (S9/S10) BEFORE Identity Creation
        if (request.Role == "store_manager" && request.StoreId.HasValue)
        {
            var store = await db.Stores.AsNoTracking()
                .FirstOrDefaultAsync(s => s.Id == request.StoreId.Value, ct);
            if (store is null)
                return TypedResults.BadRequest(new { message = "Store not found" });
            if (store.IsActive != true)
                return TypedResults.BadRequest(new { message = "Cannot assign to inactive store" });

            var existingSm = await RoleAssignmentGuard.FindExistingStoreManager(
                db, request.StoreId.Value, null, ct);
            if (existingSm.HasValue)
            {
                if (!request.ForceReassign)
                {
                    return TypedResults.Conflict(new
                    {
                        error = "Store already has a store manager assigned",
                        existingManagerId = existingSm.Value
                    });
                }
            }
        }

        if (request.Role == "area_manager" && request.AssignedStoreIds is not null)
        {
            foreach (var storeId in request.AssignedStoreIds)
            {
                var store = await db.Stores.AsNoTracking()
                    .FirstOrDefaultAsync(s => s.Id == storeId, ct);
                if (store is null || store.IsActive != true)
                    return TypedResults.BadRequest(new { message = $"Store {storeId} is invalid or inactive" });

                var existingAm = await RoleAssignmentGuard.FindExistingAreaManagerForStore(
                    db, storeId, null, ct);

                if (existingAm.HasValue)
                {
                    if (!request.ForceReassign)
                    {
                        var existingName = await db.Profiles.Where(p => p.Id == existingAm.Value)
                            .Select(p => p.FullName).FirstOrDefaultAsync(ct);
                        return TypedResults.Conflict(new
                        {
                            error = "Store already has an area manager assigned",
                            existingManagerId = existingAm.Value,
                            existingManagerName = existingName,
                            storeName = store.Name
                        });
                    }
                }
            }
        }

        // 5. Create Identity user
        var appUser = new AppUser
        {
            Id = Guid.NewGuid(),
            UserName = request.Email,
            Email = request.Email
        };

        var identityResult = await userManager.CreateAsync(appUser, request.Password);
        if (!identityResult.Succeeded)
        {
            var errors = string.Join("; ", identityResult.Errors.Select(e => e.Description));
            return TypedResults.BadRequest(new { message = errors });
        }

        // 6. Create Profile and UserRole with compensating transaction
        try
        {
            var profile = new Profile
            {
                Id = appUser.Id,
                FullName = request.FullName,
                Email = request.Email,
                StoreId = request.StoreId,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            };
            db.Profiles.Add(profile);

            var userRole = new UserRole
            {
                Id = Guid.NewGuid(),
                UserId = appUser.Id,
                Role = request.Role,
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.AppUserRoles.Add(userRole);

            if (request.Role == "area_manager" && request.AssignedStoreIds is not null)
            {
                // Force reassign cleanup
                if (request.ForceReassign)
                {
                    var oldAssignments = await db.ProfileStoreAssignments
                        .Where(a => request.AssignedStoreIds.Contains(a.StoreId))
                        .ToListAsync(ct);
                    db.ProfileStoreAssignments.RemoveRange(oldAssignments);
                }

                var newAssignments = request.AssignedStoreIds.Select(storeId => new ProfileStoreAssignment
                {
                    ProfileId = appUser.Id,
                    StoreId = storeId,
                    CreatedAt = DateTimeOffset.UtcNow
                });
                db.ProfileStoreAssignments.AddRange(newAssignments);
            }

            await db.SaveChangesAsync(ct);
        }
        catch
        {
            // Roll back Identity user to prevent phantom account
            await userManager.DeleteAsync(appUser);
            throw;
        }

        // 7. Return 201 Created
        return TypedResults.Created(
            $"/api/admin/users/{appUser.Id}",
            new Response(appUser.Id, appUser.Email!, request.FullName, request.Role));
    }
}
