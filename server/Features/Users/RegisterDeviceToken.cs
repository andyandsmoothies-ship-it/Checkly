using System;
using System.Security.Claims;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Users;

public static class RegisterDeviceToken
{
    public class Request
    {
        public string Token { get; set; } = string.Empty;
        public string Platform { get; set; } = string.Empty;
    }

    public static void MapEndpoint(IEndpointRouteBuilder app)
    {
        app.MapPost("/api/users/me/device-tokens", HandleAsync)
            .RequireAuthorization()
            .WithTags("Users");
    }

    public static async Task<IResult> HandleAsync(
        Request request,
        AppDbContext db,
        ClaimsPrincipal user,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.Token) || string.IsNullOrWhiteSpace(request.Platform))
        {
            return TypedResults.BadRequest("Token and Platform are required.");
        }

        var userIdString = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (!Guid.TryParse(userIdString, out var userId))
        {
            return TypedResults.Unauthorized();
        }

        var existingToken = await db.UserDeviceTokens
            .FirstOrDefaultAsync(x => x.UserId == userId && x.FcmToken == request.Token, ct);

        if (existingToken != null)
        {
            existingToken.LastUsedAt = DateTime.UtcNow;
            existingToken.Platform = request.Platform;
        }
        else
        {
            var newToken = new UserDeviceToken
            {
                UserId = userId,
                FcmToken = request.Token,
                Platform = request.Platform,
                LastUsedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow
            };
            db.UserDeviceTokens.Add(newToken);
        }

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok();
    }
}
