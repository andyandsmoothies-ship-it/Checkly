using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Auth;

/// <summary>
/// POST /api/auth/register
/// Creates an AppUser (Identity) + Profile + UserRole in one transaction.
/// Returns JWT token on success.
/// </summary>
public static class Register
{
    public record Request(string Email, string Password, string FullName, string Role);
    public record Response(Guid UserId, string Email, string Token);

    internal sealed class Handler(
        UserManager<AppUser> userManager,
        AppDbContext db,
        TokenService tokenService)
    {
        private static readonly HashSet<string> ValidRoles = ["admin", "auditor", "store_manager", "area_manager"];

        public async Task<IResult> ExecuteAsync(Request request, HttpContext httpContext, CancellationToken ct)
        {
            // Validate role
            if (!ValidRoles.Contains(request.Role))
            {
                return TypedResults.BadRequest(new { error = $"Invalid role. Must be one of: {string.Join(", ", ValidRoles)}" });
            }

            // Admin role creation requires an existing admin JWT
            if (request.Role == "admin")
            {
                var callerRole = httpContext.User.FindFirst(System.Security.Claims.ClaimTypes.Role)?.Value;
                if (callerRole != "admin")
                {
                    return TypedResults.Forbid();
                }
            }

            // Check if user already exists
            var existingUser = await userManager.FindByEmailAsync(request.Email);
            if (existingUser is not null)
            {
                return TypedResults.Conflict(new { error = "A user with this email already exists." });
            }

            // Create Identity user
            var user = new AppUser
            {
                Id = Guid.NewGuid(),
                UserName = request.Email,
                Email = request.Email
            };

            var result = await userManager.CreateAsync(user, request.Password);
            if (!result.Succeeded)
            {
                var errors = result.Errors.Select(e => e.Description);
                return TypedResults.BadRequest(new { errors });
            }

            // Create Profile
            var profile = new Profile
            {
                Id = user.Id,
                FullName = request.FullName,
                Email = request.Email,
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            };
            db.Profiles.Add(profile);

            // Create UserRole
            var userRole = new UserRole
            {
                Id = Guid.NewGuid(),
                UserId = user.Id,
                Role = request.Role,
                CreatedAt = DateTimeOffset.UtcNow
            };
            db.AppUserRoles.Add(userRole);

            await db.SaveChangesAsync(ct);

            // Generate token
            var token = tokenService.GenerateToken(user.Id, user.Email!, request.Role);

            return TypedResults.Created(
                $"/api/auth/{user.Id}",
                new Response(user.Id, user.Email!, token));
        }
    }
}
