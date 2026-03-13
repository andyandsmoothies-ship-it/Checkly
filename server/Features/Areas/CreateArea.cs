using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// POST /api/areas — admin-only. Creates a new area.
/// Returns 409 Conflict if code already exists.
/// </summary>
public static class CreateArea
{
    public record Request(string Name, string Code);

    public static async Task<IResult> HandleAsync(
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        // Duplicate code check
        var codeNormalized = request.Code.Trim().ToLowerInvariant();
        var exists = await db.Areas.AnyAsync(a => a.Code == codeNormalized, ct);
        if (exists)
            return TypedResults.Conflict(new { error = "Area code already exists" });

        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Code = codeNormalized,
            IsActive = true,
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };

        db.Areas.Add(area);
        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/areas/{area.Id}",
            new AreaDto(area.Id, area.Name, area.Code, area.IsActive, area.CreatedAt));
    }
}
