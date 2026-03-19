using System.Text.Json;
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
        int? OrderIndex,
        string? Metadata);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Guid groupId,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        // Verify group belongs to template and both are active
        var group = await db.Groups.FindAsync([groupId], ct);
        if (group is null || group.TemplateId != templateId || !group.IsActive)
            return Results.NotFound();

        if (string.IsNullOrWhiteSpace(request.Label))
            return Results.BadRequest(new { error = "Criterion label is required" });

        if (string.IsNullOrWhiteSpace(request.InputType))
            return Results.BadRequest(new { error = "Input type is required" });

        // Choice criteria must have at least one option in metadata
        if (request.InputType is "single_choice" or "multi_choice")
        {
            if (!HasValidOptions(request.Metadata))
                return Results.BadRequest(new { error = "Choice criteria require at least one option in metadata" });
        }

        // Scale criteria must have at least 2 scale options in metadata
        if (request.InputType is "scale")
        {
            if (!HasValidScaleOptions(request.Metadata))
                return Results.BadRequest(new { error = "Scale criteria require at least 2 scale options in metadata" });
        }

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
            Metadata = request.Metadata,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        };

        db.Criteria.Add(criterion);
        await db.SaveChangesAsync(ct);

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

    /// <summary>
    /// Validates that metadata contains a non-empty "options" array.
    /// Expected format: {"options": [{"label": "...", "value": "..."}, ...]}
    /// </summary>
    internal static bool HasValidOptions(string? metadata)
    {
        if (string.IsNullOrWhiteSpace(metadata))
            return false;

        try
        {
            using var doc = JsonDocument.Parse(metadata);
            if (doc.RootElement.TryGetProperty("options", out var options)
                && options.ValueKind == JsonValueKind.Array
                && options.GetArrayLength() > 0)
            {
                return true;
            }
        }
        catch (JsonException)
        {
            // Invalid JSON — treat as no options
        }

        return false;
    }

    /// <summary>
    /// Validates that metadata contains a "scaleOptions" array with at least 2 entries.
    /// Expected format: {"scaleOptions": [{"label": "Poor", "points": 0}, {"label": "Good", "points": 10}]}
    /// </summary>
    internal static bool HasValidScaleOptions(string? metadata)
    {
        if (string.IsNullOrWhiteSpace(metadata))
            return false;

        try
        {
            using var doc = JsonDocument.Parse(metadata);
            if (doc.RootElement.TryGetProperty("scaleOptions", out var scaleOptions)
                && scaleOptions.ValueKind == JsonValueKind.Array
                && scaleOptions.GetArrayLength() >= 2)
            {
                return true;
            }
        }
        catch (JsonException)
        {
            // Invalid JSON — treat as no scale options
        }

        return false;
    }
}
