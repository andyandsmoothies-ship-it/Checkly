using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// POST /api/templates/{templateId}/groups — create a group (AdminOnly).
/// </summary>
public static class CreateGroup
{
    public record Request(
        string Title,
        string? Description,
        decimal? Weight,
        decimal? MaxDeductionPoints,
        decimal? MinusPerFault,
        int? OrderIndex,
        Guid? ParentId,
        string? Metadata);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Request request,
        AppDbContext db,
        CancellationToken ct)
    {
        // Verify template exists and is active
        var template = await db.Templates.FindAsync([templateId], ct);
        if (template is null || !template.IsActive)
            return Results.NotFound();

        if (string.IsNullOrWhiteSpace(request.Title))
            return Results.BadRequest(new { error = "Group title is required" });

        var now = DateTimeOffset.UtcNow;
        var group = new Group
        {
            Id = Guid.NewGuid(),
            TemplateId = templateId,
            Title = request.Title.Trim(),
            Description = request.Description?.Trim(),
            Weight = request.Weight,
            MaxDeductionPoints = request.MaxDeductionPoints,
            MinusPerFault = request.MinusPerFault,
            OrderIndex = request.OrderIndex ?? 0,
            ParentId = request.ParentId,
            Metadata = request.Metadata,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        };

        db.Groups.Add(group);
        template.UpdatedAt = now; // Bump template UpdatedAt for sync
        await db.SaveChangesAsync(ct);

        // Weight sum validation warning
        string? weightWarning = await ValidateWeightSum(db, templateId, ct);

        return Results.Created($"/api/templates/{templateId}/groups/{group.Id}", new
        {
            id = group.Id,
            templateId,
            title = group.Title,
            weightWarning,
        });
    }

    /// <summary>
    /// Checks if top-level groups with non-null weights sum to 100%.
    /// Returns a warning message if they don't, or null if weights are valid or unused.
    /// </summary>
    internal static async Task<string?> ValidateWeightSum(
        AppDbContext db, Guid templateId, CancellationToken ct)
    {
        var topLevelWeights = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == templateId
                     && g.IsActive
                     && g.ParentId == null
                     && g.Weight != null)
            .Select(g => g.Weight!.Value)
            .ToListAsync(ct);

        if (topLevelWeights.Count == 0)
            return null; // No weighted sections — density not enabled

        var sum = topLevelWeights.Sum();
        if (sum != 100m)
            return $"Section weights sum to {sum}%, expected 100%";

        return null;
    }
}
