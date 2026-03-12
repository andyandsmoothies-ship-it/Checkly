using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// POST /api/templates/{templateId}/groups/{groupId}/criteria — create criterion (AdminOnly).
/// </summary>
public static class CreateCriterion
{
    public record Request(
        string Label,
        string? Description,
        string InputType,
        decimal? PointsWeight,
        bool? IsCcp,
        bool? IsRisk,
        decimal? MinusImpact,
        int? OrderIndex);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid groupId,
        Request request,
        AppDbContext db)
    {
        // Verify group belongs to template and both are active
        var group = await db.Groups.FindAsync(groupId);
        if (group is null || group.TemplateId != templateId || !group.IsActive)
            return Results.NotFound();

        if (string.IsNullOrWhiteSpace(request.Label))
            return Results.BadRequest(new { error = "Criterion label is required" });

        if (string.IsNullOrWhiteSpace(request.InputType))
            return Results.BadRequest(new { error = "Input type is required" });

        var now = DateTimeOffset.UtcNow;
        var criterion = new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = groupId,
            Label = request.Label.Trim(),
            Description = request.Description?.Trim(),
            InputType = request.InputType.Trim(),
            PointsWeight = request.PointsWeight,
            IsCcp = request.IsCcp ?? false,
            IsRisk = request.IsRisk ?? false,
            MinusImpact = request.MinusImpact,
            OrderIndex = request.OrderIndex ?? 0,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        };

        db.Criteria.Add(criterion);
        await db.SaveChangesAsync();

        return Results.Created(
            $"/api/templates/{templateId}/criteria/{criterion.Id}",
            new
            {
                id = criterion.Id,
                groupId,
                label = criterion.Label,
                inputType = criterion.InputType,
            });
    }
}
