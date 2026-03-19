using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// PUT /api/templates/{templateId}/groups/{groupId} — update group (AdminOnly).
/// </summary>
public static class UpdateGroup
{
    public record Request(
        string? Title,
        string? Description,
        decimal? Weight,
        decimal? MaxDeductionPoints,
        decimal? MinusPerFault,
        int? OrderIndex,
        string? Metadata);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid groupId,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        var group = await db.Groups.FindAsync([groupId], ct);
        if (group is null || group.TemplateId != templateId)
            return Results.NotFound();

        if (!group.IsActive)
            return Results.BadRequest(new { error = "Cannot update a deactivated group" });

        if (request.Title != null)
            group.Title = request.Title.Trim();
        if (request.Description != null)
            group.Description = request.Description.Trim();
        if (request.Weight.HasValue)
            group.Weight = request.Weight;
        if (request.MaxDeductionPoints.HasValue)
            group.MaxDeductionPoints = request.MaxDeductionPoints;
        if (request.MinusPerFault.HasValue)
            group.MinusPerFault = request.MinusPerFault;
        if (request.OrderIndex.HasValue)
            group.OrderIndex = request.OrderIndex.Value;
        if (request.Metadata != null)
            group.Metadata = request.Metadata;

        group.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        // Weight sum validation warning
        string? weightWarning = await CreateGroup.ValidateWeightSum(db, templateId, ct);

        return Results.Ok(new
        {
            id = group.Id,
            title = group.Title,
            weight = group.Weight,
            orderIndex = group.OrderIndex,
            weightWarning,
        });
    }
}
