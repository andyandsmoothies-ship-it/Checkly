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
        int? OrderIndex,
        string? Metadata);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid criterionId,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        var criterion = await db.Criteria.FindAsync([criterionId], ct);
        if (criterion is null)
            return Results.NotFound();

        // Verify criterion belongs to a group in this template
        var group = await db.Groups.FindAsync([criterion.GroupId], ct);
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
        if (request.Metadata != null)
            criterion.Metadata = request.Metadata;

        // Validate choice criteria have options after applying updates
        var effectiveInputType = criterion.InputType;
        if (effectiveInputType is "single_choice" or "multi_choice")
        {
            if (!CreateCriterion.HasValidOptions(criterion.Metadata))
                return Results.BadRequest(new { error = "Choice criteria require at least one option in metadata" });
        }

        // Validate scale criteria have scale options after applying updates
        if (effectiveInputType is "scale")
        {
            if (!CreateCriterion.HasValidScaleOptions(criterion.Metadata))
                return Results.BadRequest(new { error = "Scale criteria require at least 2 scale options in metadata" });
        }

        criterion.UpdatedAt = DateTimeOffset.UtcNow;
        await db.SaveChangesAsync(ct);

        return Results.Ok(new
        {
            id = criterion.Id,
            label = criterion.Label,
            inputType = criterion.InputType,
            pointsWeight = criterion.PointsWeight,
        });
    }
}
