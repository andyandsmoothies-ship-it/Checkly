using Checkly.Api.Common.Persistence;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// PUT /api/templates/{templateId}/criteria/{criterionId} — update criterion (AdminOnly).
/// </summary>
public static class UpdateCriterion
{
    public record Request(
        string? Label,
        string? Description,
        string? InputType,
        decimal? PointsWeight,
        bool? IsCcp,
        bool? IsRisk,
        decimal? MinusImpact,
        int? OrderIndex);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid criterionId,
        Request request,
        AppDbContext db)
    {
        var criterion = await db.Criteria.FindAsync(criterionId);
        if (criterion is null)
            return Results.NotFound();

        // Verify criterion belongs to a group in this template
        var group = await db.Groups.FindAsync(criterion.GroupId);
        if (group is null || group.TemplateId != templateId)
            return Results.NotFound();

        if (!criterion.IsActive)
            return Results.BadRequest(new { error = "Cannot update a deactivated criterion" });

        if (request.Label != null)
            criterion.Label = request.Label.Trim();
        if (request.Description != null)
            criterion.Description = request.Description.Trim();
        if (request.InputType != null)
            criterion.InputType = request.InputType.Trim();
        if (request.PointsWeight.HasValue)
            criterion.PointsWeight = request.PointsWeight;
        if (request.IsCcp.HasValue)
            criterion.IsCcp = request.IsCcp.Value;
        if (request.IsRisk.HasValue)
            criterion.IsRisk = request.IsRisk.Value;
        if (request.MinusImpact.HasValue)
            criterion.MinusImpact = request.MinusImpact;
        if (request.OrderIndex.HasValue)
            criterion.OrderIndex = request.OrderIndex.Value;

        criterion.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync();

        return Results.Ok(new
        {
            id = criterion.Id,
            label = criterion.Label,
            inputType = criterion.InputType,
            pointsWeight = criterion.PointsWeight,
        });
    }
}
