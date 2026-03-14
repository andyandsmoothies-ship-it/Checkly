using System.Security.Claims;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;

namespace Checkly.Api.Features.Admin;

/// <summary>
/// POST /api/admin/users/{id}/reset-password — admin resets a user's password.
/// Uses Identity's ResetPasswordAsync for policy enforcement.
/// </summary>
public static class ResetPassword
{
    public record Request(string NewPassword);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        UserManager<AppUser> userManager)
    {
        // 1. Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // 2. Find user by ID → 404 if not found
        var targetUser = await userManager.FindByIdAsync(id.ToString());
        if (targetUser is null)
            return TypedResults.NotFound(new { message = "User not found." });

        // 3. Generate reset token + reset password (policy enforced by Identity)
        var resetToken = await userManager.GeneratePasswordResetTokenAsync(targetUser);
        var result = await userManager.ResetPasswordAsync(targetUser, resetToken, request.NewPassword);

        if (!result.Succeeded)
        {
            var errors = string.Join("; ", result.Errors.Select(e => e.Description));
            return TypedResults.BadRequest(new { message = errors });
        }

        // 4. Success
        return TypedResults.Ok(new { message = "Password updated successfully." });
    }
}
