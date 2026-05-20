using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions/survey-results?templateId={id}[&amp;inputTypes=single_choice,multi_choice]
/// Returns aggregated answer distributions per criterion for ANY template type.
/// Auth: RequireCapability(analytics:admin) enforced at route level.
///
/// Phase B (Analytics V2): Removed ScoringMode == "survey" gate.
/// Now works for all scoring modes, enabling distribution analytics for
/// choice/scale inputs on scored (penalty/accumulation/checklist) templates.
/// </summary>
public static class GetSurveyResults
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        HttpContext httpContext,
        CancellationToken ct)
    {
        var templateIdStr = httpContext.Request.Query["templateId"].FirstOrDefault();
        if (string.IsNullOrEmpty(templateIdStr) || !Guid.TryParse(templateIdStr, out var templateId))
            return TypedResults.BadRequest(new { error = "templateId query parameter is required" });

        // Optional: filter by one or more input types (e.g. "single_choice,multi_choice")
        var inputTypesParam = httpContext.Request.Query["inputTypes"].FirstOrDefault();
        var inputTypeFilter = string.IsNullOrWhiteSpace(inputTypesParam)
            ? null
            : inputTypesParam.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                             .Select(t => t.ToLowerInvariant())
                             .ToHashSet();

        // SQL GROUP BY on answers — no in-memory loading.
        // Phase B: removed ScoringMode == "survey" filter to support universal distributions.
        var query = db.Answers
            .AsNoTracking()
            .Where(a => a.Submission!.TemplateId == templateId
                     && a.Submission.Status == SubmissionStatus.Completed
                     && a.Value != null
                     && a.Value != "");

        // If caller specified inputTypes, join to criteria and filter by input_type
        if (inputTypeFilter is { Count: > 0 })
        {
            query = query.Where(a => a.Criterion != null
                && inputTypeFilter.Contains(a.Criterion.InputType));
        }

        var grouped = await query
            .GroupBy(a => new { a.CriteriaId, a.CriteriaLabel, a.Value })
            .Select(g => new
            {
                g.Key.CriteriaId,
                g.Key.CriteriaLabel,
                g.Key.Value,
                Count = g.Count()
            })
            .OrderByDescending(x => x.Count)
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

