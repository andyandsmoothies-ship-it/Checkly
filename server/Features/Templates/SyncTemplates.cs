using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/sync/templates?since={ISO_timestamp}
/// Returns templates, groups, and criteria modified after the given timestamp.
/// Key endpoint for mobile offline-first delta sync.
///
/// Access control: non-admin users only see templates that are either
/// unassigned (global) or assigned to a group they belong to.
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
        List<string>? CategoryTags,
        bool IsActive,
        DateTimeOffset UpdatedAt);

    public static async Task<IResult> HandleAsync(
        DateTimeOffset since,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct,
        int syncLimit = 500)
    {
        // Clamp syncLimit to a safe maximum to prevent accidental OOM on initial sync
        var limit = Math.Clamp(syncLimit, 1, 2000);

        var isAdmin = user.IsInRole("admin");

        // Base query
        var query = db.Templates.Where(t => t.UpdatedAt > since);

        // Non-admin: filter by group membership
        if (!isAdmin)
        {
            var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

            var userGroupIds = await db.UserGroupMembers
                .Where(m => m.ProfileId == userId)
                .Select(m => m.UserGroupId)
                .ToListAsync(ct);

            query = query.Where(t =>
                !t.Assignments.Any() ||
                t.Assignments.Any(a => userGroupIds.Contains(a.UserGroupId)));
        }

        var templates = await query
            .Select(t => new TemplateDto(
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.DisplayNoun, t.CategoryTag, t.IsActive, t.CreatedAt, t.UpdatedAt))
            .Take(limit)
            .ToListAsync(ct);

        var groups = await db.Groups
            .Where(g => g.UpdatedAt > since)
            .Select(g => new SyncGroupDto(
                g.Id, g.TemplateId, g.ParentId, g.Title, g.Description,
                g.Weight, g.MaxDeductionPoints, g.MinusPerFault, g.OrderIndex, g.Metadata,
                g.CategoryTags, g.IsActive, g.UpdatedAt))
            .Take(limit)
            .ToListAsync(ct);

        var criteria = await db.Criteria
            .Where(c => c.UpdatedAt > since)
            .Select(c => new CriterionDto(
                c.Id, c.Label, c.Description, c.InputType, c.PointsWeight,
                c.IsCcp, c.IsRisk, c.MinusImpact, c.MaxDeductionPoints, c.OrderIndex, c.Metadata,
                c.CategoryTags))
            .Take(limit)
            .ToListAsync(ct);

        return TypedResults.Ok(new SyncResponse(
            templates, groups, criteria, DateTimeOffset.UtcNow));
    }
}
