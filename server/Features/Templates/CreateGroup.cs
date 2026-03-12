using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

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
        int? OrderIndex,
        Guid? ParentId);

    public static async Task<IResult> HandleAsync(
        Guid templateId,
        Request request,
        AppDbContext db)
    {
        // Verify template exists and is active
        var template = await db.Templates.FindAsync(templateId);
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
            Weight = request.Weight ?? 1.0m,
            MaxDeductionPoints = request.MaxDeductionPoints,
            OrderIndex = request.OrderIndex ?? 0,
            ParentId = request.ParentId,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        };

        db.Groups.Add(group);
        template.UpdatedAt = now; // Bump template UpdatedAt for sync
        await db.SaveChangesAsync();

        return Results.Created($"/api/templates/{templateId}/groups/{group.Id}", new
        {
            id = group.Id,
            templateId,
            title = group.Title,
        });
    }
}
