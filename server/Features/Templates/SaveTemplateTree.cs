using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Templates;

/// <summary>
/// PUT /api/templates/{id}/tree — atomic upsert of the full template tree.
/// Replaces the N+1 sequential group/criterion saves with a single transactional write.
/// Includes delete reconciliation: items removed from the payload are soft-deleted.
/// </summary>
public static class SaveTemplateTree
{
    // Hard caps to prevent abuse
    private const int MaxGroups = 200;
    private const int MaxCriteria = 2000;

    public record SaveTreeRequest(
        string Title,
        string Type,
        string? Description,
        string? ScoringLogicConfig,
        string? DisplayNoun,
        int Version,
        string? CategoryTag,
        List<SaveGroupRequest> Groups);

    public record SaveGroupRequest(
        Guid? Id,
        string Title,
        string? Description,
        decimal? Weight,
        decimal? MaxDeductionPoints,
        decimal? MinusPerFault,
        int OrderIndex,
        string? Metadata,
        List<string>? CategoryTags,
        List<SaveGroupRequest> Children,
        List<SaveCriterionRequest> Criteria);

    public record SaveCriterionRequest(
        Guid? Id,
        string Label,
        string? Description,
        string InputType,
        decimal? PointsWeight,
        bool IsCcp,
        bool IsRisk,
        decimal? MinusImpact,
        decimal? MaxDeductionPoints,
        int OrderIndex,
        string? Metadata,
        List<string>? CategoryTags);

    public static async Task<IResult> HandleAsync(
        Guid id,
        SaveTreeRequest request,
        AppDbContext db,
        ClaimsPrincipal user,
        CancellationToken ct)
    {
        // 1. Load and verify template exists
        var template = await db.Templates
            .FirstOrDefaultAsync(t => t.Id == id, ct);

        if (template is null)
            return TypedResults.NotFound();

        // 1.5 IDOR Tenant Ownership Authorization Check
        var userIdStr = user.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userIdStr != null)
        {
            var currentUserId = Guid.Parse(userIdStr);
            if (template.CreatedBy.HasValue && template.CreatedBy.Value != currentUserId)
            {
                return TypedResults.Forbid();
            }
        }

        // 2. Optimistic concurrency check via Version column
        if (template.Version != request.Version)
        {
            return TypedResults.Conflict(new
            {
                error = "Template was modified by another user. Please reload and try again.",
                currentVersion = template.Version,
                requestedVersion = request.Version
            });
        }

        // 3. Count totals and enforce hard caps
        var (groupCount, criterionCount) = CountAll(request.Groups);
        if (groupCount > MaxGroups)
            return TypedResults.BadRequest(new { error = $"Too many groups ({groupCount}). Maximum is {MaxGroups}." });
        if (criterionCount > MaxCriteria)
            return TypedResults.BadRequest(new { error = $"Too many criteria ({criterionCount}). Maximum is {MaxCriteria}." });
        if (groupCount + criterionCount > 500)
            return TypedResults.BadRequest(new { error = $"Template tree contains too many nodes ({groupCount + criterionCount}). The maximum allowed combined total is 500." });

        // 3.5 Run Template Linter validation rules
        var lintResult = TemplateLinter.Run(request, template.Type);
        if (lintResult.Errors.Any())
        {
            return TypedResults.UnprocessableEntity(new
            {
                errors = new { lintResult = lintResult.Errors }
            });
        }

        // 4. Load existing groups + criteria for this template
        var existingGroups = await db.Groups
            .Where(g => g.TemplateId == id)
            .ToListAsync(ct);

        var existingCriteria = await db.Criteria
            .Where(c => existingGroups.Select(g => g.Id).Contains(c.GroupId))
            .ToListAsync(ct);

        var existingGroupMap = existingGroups.ToDictionary(g => g.Id);
        var existingCriterionMap = existingCriteria.ToDictionary(c => c.Id);

        // 5. Collect all incoming IDs for reconciliation
        var incomingGroupIds = new HashSet<Guid>();
        var incomingCriterionIds = new HashSet<Guid>();
        CollectIncomingIds(request.Groups, incomingGroupIds, incomingCriterionIds);

        // 6. Update template metadata
        var now = DateTimeOffset.UtcNow;
        template.Title = request.Title;
        template.Type = request.Type;
        template.Description = request.Description;
        template.ScoringLogicConfig = request.ScoringLogicConfig;
        template.DisplayNoun = request.DisplayNoun;
        template.CategoryTag = request.CategoryTag;
        template.Version++;
        template.UpdatedAt = now;

        // 7. Upsert groups and criteria recursively
        UpsertGroups(db, request.Groups, id, parentId: null, now,
            existingGroupMap, existingCriterionMap);

        // 8. Soft-delete removed groups
        foreach (var existing in existingGroups)
        {
            if (existing.IsActive && !incomingGroupIds.Contains(existing.Id))
            {
                existing.IsActive = false;
                existing.UpdatedAt = now;
            }
        }

        // 9. Soft-delete removed criteria
        foreach (var existing in existingCriteria)
        {
            if (existing.IsActive && !incomingCriterionIds.Contains(existing.Id))
            {
                existing.IsActive = false;
                existing.UpdatedAt = now;
            }
        }

        // 10. Audit log
        AuditLogger.Log(db, user, "template_tree_saved",
            "template", template.Id, "Template tree saved");

        // 11. Single atomic save (catch xmin-based concurrency violations)
        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            return TypedResults.Conflict(new
            {
                error = "Template was modified by another user. Please reload and try again.",
                currentVersion = template.Version - 1, // undo the in-memory increment
                requestedVersion = request.Version
            });
        }

        // 12. Return the updated tree (reuse GetTemplate's tree builder)
        var groups = await db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == id && g.IsActive)
            .OrderBy(g => g.OrderIndex)
            .Include(g => g.Criteria.Where(c => c.IsActive).OrderBy(c => c.OrderIndex))
            .ToListAsync(ct);

        var tree = GetTemplate.BuildGroupTree(groups, parentId: null);

        var dto = new TemplateTreeDto(
            template.Id, template.Title, template.Description, template.Type,
            template.Version, template.ScoringLogicConfig, template.DisplayNoun,
            template.CategoryTag,
            template.IsActive, template.CreatedAt, template.UpdatedAt, tree,
            lintResult);

        return TypedResults.Ok(dto);
    }

    private static void UpsertGroups(
        AppDbContext db,
        List<SaveGroupRequest> groups,
        Guid templateId,
        Guid? parentId,
        DateTimeOffset now,
        Dictionary<Guid, Group> existingGroupMap,
        Dictionary<Guid, Criterion> existingCriterionMap)
    {
        foreach (var g in groups)
        {
            Guid groupId;

            if (g.Id is null || g.Id == Guid.Empty)
            {
                // New group
                groupId = Guid.NewGuid();
                var entity = new Group
                {
                    Id = groupId,
                    TemplateId = templateId,
                    ParentId = parentId,
                    Title = g.Title,
                    Description = g.Description,
                    Weight = g.Weight,
                    MaxDeductionPoints = g.MaxDeductionPoints,
                    MinusPerFault = g.MinusPerFault,
                    OrderIndex = g.OrderIndex,
                    Metadata = g.Metadata,
                    CategoryTags = g.CategoryTags,
                    IsActive = true,
                    CreatedAt = now,
                    UpdatedAt = now,
                };
                db.Groups.Add(entity);
            }
            else
            {
                groupId = g.Id.Value;
                if (existingGroupMap.TryGetValue(groupId, out var existing))
                {
                    // Update existing group
                    existing.Title = g.Title;
                    existing.Description = g.Description;
                    existing.Weight = g.Weight;
                    existing.MaxDeductionPoints = g.MaxDeductionPoints;
                    existing.MinusPerFault = g.MinusPerFault;
                    existing.OrderIndex = g.OrderIndex;
                    existing.Metadata = g.Metadata;
                    existing.CategoryTags = g.CategoryTags;
                    existing.ParentId = parentId;
                    existing.IsActive = true;
                    existing.UpdatedAt = now;
                }
                else
                {
                    // ID provided but not found — treat as new
                    var entity = new Group
                    {
                        Id = groupId,
                        TemplateId = templateId,
                        ParentId = parentId,
                        Title = g.Title,
                        Description = g.Description,
                        Weight = g.Weight,
                        MaxDeductionPoints = g.MaxDeductionPoints,
                        MinusPerFault = g.MinusPerFault,
                        OrderIndex = g.OrderIndex,
                        Metadata = g.Metadata,
                        CategoryTags = g.CategoryTags,
                        IsActive = true,
                        CreatedAt = now,
                        UpdatedAt = now,
                    };
                    db.Groups.Add(entity);
                }
            }

            // Upsert criteria for this group
            foreach (var c in g.Criteria)
            {
                if (c.Id is null || c.Id == Guid.Empty)
                {
                    // New criterion
                    db.Criteria.Add(new Criterion
                    {
                        Id = Guid.NewGuid(),
                        GroupId = groupId,
                        Label = c.Label,
                        Description = c.Description,
                        InputType = c.InputType,
                        PointsWeight = c.PointsWeight,
                        IsCcp = c.IsCcp,
                        IsRisk = c.IsRisk,
                        MinusImpact = c.MinusImpact,
                        MaxDeductionPoints = c.MaxDeductionPoints,
                        OrderIndex = c.OrderIndex,
                        Metadata = c.Metadata,
                        CategoryTags = c.CategoryTags,
                        IsActive = true,
                        CreatedAt = now,
                        UpdatedAt = now,
                    });
                }
                else if (existingCriterionMap.TryGetValue(c.Id.Value, out var existingC))
                {
                    // Update existing criterion
                    existingC.GroupId = groupId;
                    existingC.Label = c.Label;
                    existingC.Description = c.Description;
                    existingC.InputType = c.InputType;
                    existingC.PointsWeight = c.PointsWeight;
                    existingC.IsCcp = c.IsCcp;
                    existingC.IsRisk = c.IsRisk;
                    existingC.MinusImpact = c.MinusImpact;
                    existingC.MaxDeductionPoints = c.MaxDeductionPoints;
                    existingC.OrderIndex = c.OrderIndex;
                    existingC.Metadata = c.Metadata;
                    existingC.CategoryTags = c.CategoryTags;
                    existingC.IsActive = true;
                    existingC.UpdatedAt = now;
                }
                else
                {
                    // ID provided but not found — treat as new
                    db.Criteria.Add(new Criterion
                    {
                        Id = c.Id.Value,
                        GroupId = groupId,
                        Label = c.Label,
                        Description = c.Description,
                        InputType = c.InputType,
                        PointsWeight = c.PointsWeight,
                        IsCcp = c.IsCcp,
                        IsRisk = c.IsRisk,
                        MinusImpact = c.MinusImpact,
                        MaxDeductionPoints = c.MaxDeductionPoints,
                        OrderIndex = c.OrderIndex,
                        Metadata = c.Metadata,
                        CategoryTags = c.CategoryTags,
                        IsActive = true,
                        CreatedAt = now,
                        UpdatedAt = now,
                    });
                }
            }

            // Recurse into children
            UpsertGroups(db, g.Children, templateId, groupId, now,
                existingGroupMap, existingCriterionMap);
        }
    }

    private static (int groups, int criteria) CountAll(List<SaveGroupRequest> groups)
    {
        int g = 0, c = 0;
        foreach (var group in groups)
        {
            g++;
            c += group.Criteria.Count;
            var (childG, childC) = CountAll(group.Children);
            g += childG;
            c += childC;
        }
        return (g, c);
    }

    private static void CollectIncomingIds(
        List<SaveGroupRequest> groups,
        HashSet<Guid> groupIds,
        HashSet<Guid> criterionIds)
    {
        foreach (var g in groups)
        {
            if (g.Id is not null && g.Id != Guid.Empty)
                groupIds.Add(g.Id.Value);

            foreach (var c in g.Criteria)
            {
                if (c.Id is not null && c.Id != Guid.Empty)
                    criterionIds.Add(c.Id.Value);
            }

            CollectIncomingIds(g.Children, groupIds, criterionIds);
        }
    }
}
