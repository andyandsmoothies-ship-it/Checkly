using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/my-stats — auditor personal metrics.
/// </summary>
public static class GetMyStats
{
    public static async Task<IResult> HandleAsync(
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);
        var now = DateTimeOffset.UtcNow;
        var monthStart = new DateTimeOffset(now.Year, now.Month, 1, 0, 0, 0, TimeSpan.Zero);

        // Auditor's submissions this month (server-side aggregates)
        var myQuery = db.Submissions
            .AsNoTracking()
            .Where(s => s.AuditorId == userId
                && s.Status == "completed"
                && s.CreatedAt >= monthStart);

        var auditsThisMonth = await myQuery.CountAsync(ct);

        var myScoredQuery = myQuery.Where(s => s.TotalScore.HasValue);
        var myScoredCount = await myScoredQuery.CountAsync(ct);
        var avgScoreGiven = myScoredCount > 0
            ? Math.Round((double)await myScoredQuery.AverageAsync(s => s.TotalScore!.Value, ct), 1)
            : 0.0;

        // Company-wide average (server-side aggregate)
        var companyQuery = db.Submissions
            .AsNoTracking()
            .Where(s => s.Status == "completed"
                && s.TotalScore.HasValue
                && s.ScoringMode != "survey"
                && s.CreatedAt >= monthStart);

        var companyCount = await companyQuery.CountAsync(ct);
        var companyAvgScore = companyCount > 0
            ? Math.Round((double)await companyQuery.AverageAsync(s => s.TotalScore!.Value, ct), 1)
            : 0.0;

        return TypedResults.Ok(new
        {
            auditsThisMonth,
            avgScoreGiven,
            companyAvgScore
        });
    }
}
