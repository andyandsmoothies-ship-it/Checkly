using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// GET /api/templates/{id} — single template with nested groups/criteria tree.
/// Groups are ordered by OrderIndex, supports parent/child hierarchy.
/// </summary>
public static class GetTemplate
{
    public static async Task<IResult> HandleAsync(Guid id, AppDbContext db, CancellationToken ct)
    {
        var template = await db.Templates
            .AsNoTracking()
            .Where(t => t.Id == id)
            .Select(t => new
            {
                t.Id, t.Title, t.Description, t.Type, t.Version,
                t.ScoringLogicConfig, t.IsActive, t.CreatedAt, t.UpdatedAt
            })
            .FirstOrDefaultAsync(ct);

        if (template is null)
            return TypedResults.NotFound();

        // Load all groups + criteria for this template
        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == id && g.IsActive)
            .OrderBy(g => g.OrderIndex)
            .Include(g => g.Criteria.Where(c => c.IsActive).OrderBy(c => c.OrderIndex))
            .ToListAsync(ct);

        // Build tree: root groups (ParentId == null) with nested children
        var tree = BuildGroupTree(groups, parentId: null);

        var dto = new TemplateTreeDto(
            template.Id, template.Title, template.Description, template.Type,
            template.Version, template.ScoringLogicConfig, template.IsActive,
            template.CreatedAt, template.UpdatedAt, tree);

        return TypedResults.Ok(dto);
    }

    private static List<GroupDto> BuildGroupTree(List<Group> allGroups, Guid? parentId)
    {
        return allGroups
            .Where(g => g.ParentId == parentId)
            .Select(g => new GroupDto(
                g.Id, g.Title, g.Description, g.Weight, g.MaxDeductionPoints, g.MinusPerFault,
                g.OrderIndex, g.Metadata,
                BuildGroupTree(allGroups, g.Id),
                g.Criteria.Select(c => new CriterionDto(
                    c.Id, c.Label, c.Description, c.InputType, c.PointsWeight,
                    c.IsCcp, c.IsRisk, c.OrderIndex, c.Metadata)).ToList()))
            .ToList();
    }
}
