using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// PUT /api/areas/{id} — admin-only. Updates Name and/or IsActive.
/// </summary>
public static class UpdateArea
{
    public record Request(string? Name, string? Description, bool? IsActive);

    public static async Task<IResult> HandleAsync(
        Guid id,
        Request request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Admin guard
        var callerRole = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (callerRole != "admin")
            return TypedResults.Forbid();

        var area = await db.Areas.FirstOrDefaultAsync(a => a.Id == id, ct);
        if (area is null)
            return TypedResults.NotFound(new { error = "Area not found" });

        if (request.Name != null)
            area.Name = request.Name.Trim();

        if (request.Description != null)
            area.Description = request.Description.Trim();

        if (request.IsActive.HasValue)
            area.IsActive = request.IsActive.Value;

        area.UpdatedAt = DateTimeOffset.UtcNow;

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(
            new AreaDto(area.Id, area.Name, area.Description, area.IsActive, area.CreatedAt));
    }
}
