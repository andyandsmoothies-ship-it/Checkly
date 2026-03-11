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
    public record Response(Guid UserId, string Email, string Role, string Token);

    internal sealed class Handler(
        UserManager<AppUser> userManager,
        AppDbContext db,
        TokenService tokenService)
    {
        public async Task<IResult> ExecuteAsync(Request request, CancellationToken ct)
        {
            // Find user
            var user = await userManager.FindByEmailAsync(request.Email);
            if (user is null)
            {
                return TypedResults.Unauthorized();
            }

            // Verify password
            var validPassword = await userManager.CheckPasswordAsync(user, request.Password);
            if (!validPassword)
            {
                return TypedResults.Unauthorized();
            }

            // Get role from user_roles table
            var userRole = await db.AppUserRoles
                .Where(r => r.UserId == user.Id)
                .Select(r => r.Role)
                .FirstOrDefaultAsync(ct);

            if (userRole is null)
            {
                return TypedResults.Problem("User has no assigned role.", statusCode: 500);
            }

            // Generate token
            var token = tokenService.GenerateToken(user.Id, user.Email!, userRole);

            return TypedResults.Ok(new Response(user.Id, user.Email!, userRole, token));
        }
    }
}
