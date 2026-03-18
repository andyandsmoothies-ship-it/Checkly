using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions/survey-results?templateId={id}
/// Returns aggregated answer distributions per criterion for survey-mode templates.
/// Admin-only endpoint. Uses SQL GROUP BY for efficiency.
/// </summary>
public static class GetSurveyResults
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var role = user.FindFirstValue(ClaimTypes.Role) ?? "";
        if (role != "admin")
            return TypedResults.Forbid();

        var templateIdStr = httpContext.Request.Query["templateId"].FirstOrDefault();
        if (string.IsNullOrEmpty(templateIdStr) || !Guid.TryParse(templateIdStr, out var templateId))
            return TypedResults.BadRequest(new { error = "templateId query parameter is required" });

        // SQL GROUP BY on answers — no in-memory loading
        // Filter by scoring_mode instead of joining to templates
        var grouped = await db.Answers
            .AsNoTracking()
            .Where(a => a.Submission!.TemplateId == templateId
                     && a.Submission.Status == "completed"
                     && a.Submission.ScoringMode == "survey"
                     && a.Value != null
                     && a.Value != "")
            .GroupBy(a => new { a.CriteriaId, a.CriteriaLabel, a.Value })
            .Select(g => new
            {
                g.Key.CriteriaId,
                g.Key.CriteriaLabel,
                g.Key.Value,
                Count = g.Count()
            })
            .Take(500)
            .ToListAsync(ct);

        if (grouped.Count == 0)
            return TypedResults.Ok(Array.Empty<object>());

        // Post-process: handle multi-choice comma-separated values in C#
        // and aggregate into per-criterion results
        var criterionMap = new Dictionary<Guid, CriterionAggregator>();

        foreach (var row in grouped)
        {
            var key = row.CriteriaId ?? Guid.Empty;
            if (!criterionMap.TryGetValue(key, out var agg))
            {
                agg = new CriterionAggregator(row.CriteriaLabel ?? "Unknown");
                criterionMap[key] = agg;
            }

            // Split multi-choice comma-separated values
            var values = row.Value!.Contains(',')
                ? row.Value.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                : [row.Value];

            foreach (var v in values)
            {
                if (agg.OptionCounts.TryGetValue(v, out var existing))
                    agg.OptionCounts[v] = existing + row.Count;
                else
                    agg.OptionCounts[v] = row.Count;
            }

            agg.TotalResponses += row.Count;
        }

        var results = criterionMap.Select(kv => new
        {
            criterionId = kv.Key,
            label = kv.Value.Label,
            totalResponses = kv.Value.TotalResponses,
            options = kv.Value.OptionCounts
                .Select(o => new
                {
                    value = o.Key,
                    count = o.Value,
                    percentage = kv.Value.TotalResponses > 0
                        ? Math.Round(o.Value * 100.0 / kv.Value.TotalResponses, 1)
                        : 0.0
                })
                .OrderByDescending(o => o.count)
                .ToList()
        }).ToList();

        return TypedResults.Ok(results);
    }

    private sealed class CriterionAggregator(string label)
    {
        public string Label { get; } = label;
        public int TotalResponses { get; set; }
        public Dictionary<string, int> OptionCounts { get; } = new();
    }
}
