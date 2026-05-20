using System.Security.Claims;
using Checkly.Api.Common;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Users;

public class SimpleUserDto
{
    public Guid Id { get; set; }
    public string? FullName { get; set; }
    public string? Email { get; set; }
    public string Role { get; set; } = string.Empty;
    public string? StoreId { get; set; }
}

public static class SearchUsers
{
    public static void MapEndpoint(IEndpointRouteBuilder app)
    {
        app.MapGet("/api/users", HandleAsync)
            .RequireAuthorization("AreaManagerAccess")
            .WithTags("Users");
    }

    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var requireCapability = httpContext.Request.Query["requireCapability"].FirstOrDefault();
        var search = httpContext.Request.Query["search"].FirstOrDefault();

        var query = from p in db.Profiles.AsNoTracking()
                    join r in db.AppUserRoles.AsNoTracking() on p.Id equals r.UserId
                    select new { p, r };

        if (!string.IsNullOrEmpty(requireCapability))
        {
            var validRoles = db.RoleCapabilities
                .Where(rc => rc.Capability == requireCapability)
                .Select(rc => rc.Role);

            query = query.Where(x => validRoles.Contains(x.r.Role));
        }

        if (!string.IsNullOrEmpty(search))
        {
            query = query.Where(x =>
                (x.p.FullName != null && x.p.FullName.Contains(search)) ||
                (x.p.Email != null && x.p.Email.Contains(search)));
        }

        var users = await query
            .OrderBy(x => x.p.FullName)
            .Take(100)
            .Select(x => new SimpleUserDto
            {
                Id = x.p.Id,
                FullName = x.p.FullName,
                Email = x.p.Email,
                Role = x.r.Role,
                StoreId = x.p.StoreId != null ? x.p.StoreId.ToString() : null
            })
            .ToListAsync(ct);

        return TypedResults.Ok(new { items = users });
    }
}
