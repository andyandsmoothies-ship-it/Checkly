using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Auth;

/// <summary>
/// POST /api/auth/login
/// Validates credentials, reads role from user_roles table, returns JWT.
/// </summary>
public static class Login
{
    public record Request(string Email, string Password);
    public record Response(Guid UserId, string Email, string Role, string Token, string? FullName);

    internal sealed class Handler(
        UserManager<AppUser> userManager,
        SignInManager<AppUser> signInManager,
        AppDbContext db,
        TokenService tokenService)
    {
        public async Task<IResult> ExecuteAsync(Request request, CancellationToken ct)
        {
            // Find user
            var user = await userManager.FindByEmailAsync(request.Email);
            if (user is null)
            {
                return TypedResults.Problem(
                    "Invalid email or password.", 
                    statusCode: 401, 
                    extensions: new Dictionary<string, object?> { { "code", "invalid_credentials" } });
            }

            // Verify password with lockout tracking
            var result = await signInManager.CheckPasswordSignInAsync(
                user, request.Password, lockoutOnFailure: true);

            if (result.IsLockedOut)
                return TypedResults.Problem(
                    "Account locked due to multiple failed attempts. Try again in 15 minutes.",
                    statusCode: 423,
                    extensions: new Dictionary<string, object?> { { "code", "account_locked" } });

            if (!result.Succeeded)
                return TypedResults.Problem(
                    "Invalid email or password.", 
                    statusCode: 401, 
                    extensions: new Dictionary<string, object?> { { "code", "invalid_credentials" } });

            // Get role from user_roles table
            var userRole = await db.AppUserRoles
                .Where(r => r.UserId == user.Id)
                .Select(r => r.Role)
                .FirstOrDefaultAsync(ct);

            if (userRole is null)
            {
                return TypedResults.Problem("User has no assigned role.", statusCode: 500);
            }

            // Get profile for full name
            var fullName = await db.Profiles
                .Where(p => p.Id == user.Id)
                .Select(p => p.FullName)
                .FirstOrDefaultAsync(ct);

            // Generate token
            var token = tokenService.GenerateToken(user.Id, user.Email!, userRole);

            return TypedResults.Ok(new Response(user.Id, user.Email!, userRole, token, fullName));
        }
    }
}
