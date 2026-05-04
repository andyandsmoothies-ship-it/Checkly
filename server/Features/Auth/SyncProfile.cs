using Checkly.Api.Common.Persistence;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Checkly.Api.Features.Auth;

/// <summary>
/// Handles profile synchronization for mobile apps (Slice 4).
/// Endpoint: GET /api/sync/profile
/// </summary>
public static class SyncProfile
{
    public static async Task<IResult> HandleAsync(AppDbContext db, HttpContext httpContext, CancellationToken ct)
    {
        var profileIdClaim = httpContext.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        var role = httpContext.User.FindFirst(ClaimTypes.Role)?.Value;
        
        if (profileIdClaim is null || !Guid.TryParse(profileIdClaim, out var profileId))
        {
            return Results.Unauthorized();
        }

        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == profileId, ct);

        if (profile is null)
            return Results.NotFound();

        Guid[]? assignedStoreIds = null;
        
        // Only return store scopes if the user's current role is area_manager.
        // This ensures downgraded AMs do not get stale store assignments.
        if (role == "area_manager")
        {
            assignedStoreIds = await db.ProfileStoreAssignments
                .AsNoTracking()
                .Where(a => a.ProfileId == profileId && a.Store!.IsActive == true)
                .Select(a => a.StoreId)
                .ToArrayAsync(ct);
        }

        return Results.Ok(new
        {
            profileId = profile.Id,
            fullName = profile.FullName,
            email = profile.Email,
            role = role,
            assignedStoreIds
        });
    }
}
