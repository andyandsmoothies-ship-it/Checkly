using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/top-failures?templateId={templateId}
/// Returns most frequently failed criteria for a template.
/// </summary>
public static class GetTopFailures
{
    public static async Task<IResult> HandleAsync(
        HttpContext httpContext,
        AppDbContext db,
        CancellationToken ct)
    {
        var templateIdStr = httpContext.Request.Query["templateId"].FirstOrDefault();
        if (string.IsNullOrEmpty(templateIdStr) || !Guid.TryParse(templateIdStr, out var templateId))
            return TypedResults.BadRequest(new { error = "templateId query parameter is required" });

        // Subquery: criteria IDs for this template (stays in SQL, no materialization)
        var criteriaQuery = db.Groups
            .AsNoTracking()
            .Where(g => g.TemplateId == templateId)
            .Join(db.Criteria.AsNoTracking(),
                g => g.Id, c => c.GroupId,
                (g, c) => c.Id);

        // Count failures per criterion using the semantic IsFailure flag (Analytics V2 Phase A)
        var failures = await db.Answers
            .AsNoTracking()
            .Where(a => a.CriteriaId.HasValue
                && a.IsFailure
                && criteriaQuery.Contains(a.CriteriaId.Value))
            .GroupBy(a => new { a.CriteriaId, a.CriteriaLabel })
            .Select(g => new
            {
                criterionLabel = g.Key.CriteriaLabel ?? "Unknown",
                failCount = g.Count()
            })
            .OrderByDescending(x => x.failCount)
            .Take(20)
            .ToListAsync(ct);

        // Total answered for this template (basis for fail rate %)
        var totalAnswers = await db.Answers
            .AsNoTracking()
            .CountAsync(a => a.CriteriaId.HasValue
                && criteriaQuery.Contains(a.CriteriaId.Value), ct);

        var result = failures.Select(f => new
        {
            f.criterionLabel,
            f.failCount,
            failRate = totalAnswers > 0
                ? Math.Round((double)f.failCount / totalAnswers * 100, 1)
                : 0.0
        });

        return TypedResults.Ok(result);
    }
}
