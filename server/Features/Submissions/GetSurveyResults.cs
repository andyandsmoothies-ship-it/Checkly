using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// GET /api/submissions/survey-results?templateId={id}
/// Returns aggregated answer distributions per criterion for survey-mode templates.
/// Admin-only endpoint.
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

        // Load all completed submissions for this template with their answers
        var answers = await db.Submissions
            .AsNoTracking()
            .Where(s => s.TemplateId == templateId && s.Status == "completed")
            .SelectMany(s => s.Answers)
            .Select(a => new { a.CriteriaId, a.CriteriaLabel, a.Value })
            .ToListAsync(ct);

        if (answers.Count == 0)
            return TypedResults.Ok(Array.Empty<object>());

        // Group by criterion, then count each value
        var results = answers
            .GroupBy(a => new { a.CriteriaId, a.CriteriaLabel })
            .Select(g =>
            {
                // For multi_choice, values are comma-separated — split them
                var allValues = g
                    .Where(a => !string.IsNullOrEmpty(a.Value))
                    .SelectMany(a => a.Value!.Contains(',')
                        ? a.Value.Split(',', StringSplitOptions.TrimEntries | StringSplitOptions.RemoveEmptyEntries)
                        : [a.Value])
                    .ToList();

                var totalResponses = g.Count();
                var optionCounts = allValues
                    .GroupBy(v => v)
                    .Select(og => new
                    {
                        value = og.Key,
                        count = og.Count(),
                        percentage = totalResponses > 0
                            ? Math.Round(og.Count() * 100.0 / totalResponses, 1)
                            : 0.0
                    })
                    .OrderByDescending(o => o.count)
                    .ToList();

                return new
                {
                    criterionId = g.Key.CriteriaId,
                    label = g.Key.CriteriaLabel ?? "Unknown",
                    totalResponses,
                    options = optionCounts
                };
            })
            .ToList();

        return TypedResults.Ok(results);
    }
}
