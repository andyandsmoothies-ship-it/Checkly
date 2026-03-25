using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Areas;

/// <summary>
/// POST /api/areas — admin-only. Creates a new area.
/// Returns 409 Conflict if code already exists.
/// </summary>
public static class CreateArea
{
    public record Request(string Name, string? Description);

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

        // Duplicate name check
        var nameNormalized = request.Name.Trim().ToLowerInvariant();
        var exists = await db.Areas.AnyAsync(a => a.Name.ToLower() == nameNormalized, ct);
        if (exists)
            return TypedResults.Conflict(new { error = "Area name already exists" });

        if (request.Name.Length > 200)
            return TypedResults.BadRequest(new { error = "Name must not exceed 200 characters" });

        if (request.Description?.Length > 1000)
            return TypedResults.BadRequest(new { error = "Description must not exceed 1000 characters" });

        var area = new Area
        {
            Id = Guid.NewGuid(),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow,
        };

        db.Areas.Add(area);
        await db.SaveChangesAsync(ct);
        AuditLogger.Log(db, user, "area_created", "Area", area.Id,
            message: $"Area '{area.Name}' created",
            userEmail: user.FindFirstValue(ClaimTypes.Email));
        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/areas/{area.Id}",
            new AreaDto(area.Id, area.Name, area.Description, 0, null, area.CreatedAt));
    }
}
