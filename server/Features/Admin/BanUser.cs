using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// POST /api/admin/users/{id}/ban — lock out (ban) a user via Identity LockoutEnd.
/// </summary>
public static class BanUser
{
    public record Request(bool IsBanned);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        UserManager<AppUser> userManager,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // Prevent self-ban
        var callerId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        if (callerId == id)
            return TypedResults.BadRequest(new { error = "Cannot ban yourself" });

        var appUser = await userManager.FindByIdAsync(id.ToString());
        if (appUser is null)
            return TypedResults.NotFound(new { error = "User not found" });

        if (request.IsBanned)
        {
            await userManager.SetLockoutEndDateAsync(appUser, DateTimeOffset.MaxValue);
        }
        else
        {
            await userManager.SetLockoutEndDateAsync(appUser, null);
        }

        // Log the admin action
        var profile = await db.Profiles.AsNoTracking().FirstOrDefaultAsync(p => p.Id == id, ct);
        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = callerId,
            Action = request.IsBanned ? "ban_user" : "unban_user",
            Category = "admin",
            Message = $"{(request.IsBanned ? "Banned" : "Unbanned")} user {profile?.FullName ?? id.ToString()} ({profile?.Email})",
            Path = $"/api/admin/users/{id}/ban",
            Level = request.IsBanned ? "warning" : "info",
            CreatedAt = DateTimeOffset.UtcNow,
        });

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { id, isBanned = request.IsBanned });
    }
}
