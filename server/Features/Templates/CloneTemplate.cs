using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// POST /api/templates/{id}/clone — deep-copies a template tree as a new draft.
/// Uses a two-pass GUID mapping algorithm to preserve parent-child group relations.
/// TemplateAssignments are NOT copied — the clone starts with zero store access.
/// </summary>
public static class CloneTemplate
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // 1. Load source template — must exist and be active.
        var source = await db.Templates
            .AsNoTracking()
            .FirstOrDefaultAsync(t => t.Id == id && t.IsActive, ct);

        if (source is null)
            return TypedResults.NotFound();

        // 2. Load all source groups and criteria (flat lists, no tracking).
        var sourceGroups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == id && g.IsActive)
            .ToListAsync(ct);

        var sourceGroupIds = sourceGroups.Select(g => g.Id).ToHashSet();

        var sourceCriteria = await db.Criteria
            .AsNoTracking()
            .Where(c => sourceGroupIds.Contains(c.GroupId) && c.IsActive)
            .ToListAsync(ct);

        var now = DateTimeOffset.UtcNow;
        var newTemplateId = Guid.NewGuid();

        // 3. Build the new Template entity (draft, version reset).
        var newTemplate = new Template
        {
            Id = newTemplateId,
            Title = $"{source.Title} (Copy)",
            Type = source.Type,
            Description = source.Description,
            ScoringLogicConfig = source.ScoringLogicConfig,
            DisplayNoun = source.DisplayNoun,
            Version = 1,
            IsActive = true,
            CreatedBy = Guid.TryParse(user.FindFirstValue(ClaimTypes.NameIdentifier), out var uid) ? uid : null,
            CreatedAt = now,
            UpdatedAt = now,
        };

        // 4. Pass 1: Build GUID map — oldGroupId -> newGroupId.
        var idMap = sourceGroups.ToDictionary(g => g.Id, _ => Guid.NewGuid());

        // 5. Pass 2: Create new Group entities using the map for parent resolution.
        var newGroups = sourceGroups.Select(g => new Group
        {
            Id = idMap[g.Id],
            TemplateId = newTemplateId,
            ParentId = g.ParentId.HasValue ? idMap[g.ParentId.Value] : null,
            Title = g.Title,
            Description = g.Description,
            Weight = g.Weight,
            MaxDeductionPoints = g.MaxDeductionPoints,
            MinusPerFault = g.MinusPerFault,
            OrderIndex = g.OrderIndex,
            Metadata = g.Metadata,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        }).ToList();

        // 6. Pass 3: Create new Criterion entities using the group id map.
        var newCriteria = sourceCriteria.Select(c => new Criterion
        {
            Id = Guid.NewGuid(),
            GroupId = idMap[c.GroupId],
            Label = c.Label,
            Description = c.Description,
            InputType = c.InputType,
            PointsWeight = c.PointsWeight,
            IsCcp = c.IsCcp,
            IsRisk = c.IsRisk,
            MinusImpact = c.MinusImpact,
            OrderIndex = c.OrderIndex,
            Metadata = c.Metadata,
            IsActive = true,
            CreatedAt = now,
            UpdatedAt = now,
        }).ToList();

        // 7. Persist everything in one transaction.
        db.Templates.Add(newTemplate);
        db.Groups.AddRange(newGroups);
        db.Criteria.AddRange(newCriteria);

        AuditLogger.Log(db, user, "template_cloned", "template", newTemplateId,
            $"Cloned template '{source.Title}' (source: {source.Id})", $"/api/templates/{id}/clone");

        await db.SaveChangesAsync(ct);

        return TypedResults.Created(
            $"/api/templates/{newTemplateId}",
            new TemplateDto(
                newTemplate.Id, newTemplate.Title, newTemplate.Description, newTemplate.Type,
                newTemplate.Version, newTemplate.ScoringLogicConfig, newTemplate.DisplayNoun,
                newTemplate.IsActive, newTemplate.CreatedAt, newTemplate.UpdatedAt));
    }
}
