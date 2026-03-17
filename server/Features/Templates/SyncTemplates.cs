using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/sync/templates?since={ISO_timestamp}
/// Returns templates, groups, and criteria modified after the given timestamp.
/// Key endpoint for mobile offline-first delta sync.
/// </summary>
public static class SyncTemplates
{
    public sealed record SyncResponse(
        List<TemplateDto> Templates,
        List<SyncGroupDto> Groups,
        List<CriterionDto> Criteria,
        DateTimeOffset SyncedAt);

    public sealed record SyncGroupDto(
        Guid Id,
        Guid TemplateId,
        Guid? ParentId,
        string Title,
        string? Description,
        decimal? Weight,
        decimal? MaxDeductionPoints,
        decimal? MinusPerFault,
        int OrderIndex,
        string? Metadata,
        bool IsActive,
        DateTimeOffset UpdatedAt);

    public static async Task<IResult> HandleAsync(
        DateTimeOffset since,
        AppDbContext db,
        CancellationToken ct)
    {
        var templates = await db.Templates
            .Where(t => t.UpdatedAt > since)
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.IsActive, t.CreatedAt, t.UpdatedAt))
            .ToListAsync(ct);

        var groups = await db.Groups
            .Where(g => g.UpdatedAt > since)
            .Select(g => new SyncGroupDto(
                g.Id, g.TemplateId, g.ParentId, g.Title, g.Description,
                g.Weight, g.MaxDeductionPoints, g.MinusPerFault, g.OrderIndex, g.Metadata,
                g.IsActive, g.UpdatedAt))
            .ToListAsync(ct);

        var criteria = await db.Criteria
            .Where(c => c.UpdatedAt > since)
            .Select(c => new CriterionDto(
                c.Id, c.Label, c.Description, c.InputType, c.PointsWeight,
                c.IsCcp, c.IsRisk, c.OrderIndex, c.Metadata))
            .ToListAsync(ct);

        return TypedResults.Ok(new SyncResponse(
            templates, groups, criteria, DateTimeOffset.UtcNow));
    }
}
