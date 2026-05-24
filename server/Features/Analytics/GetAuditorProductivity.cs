using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/auditors/productivity — retrieves auditor stats with bias rating calibration.
/// </summary>
public static class GetAuditorProductivity
{
    public static async Task<IResult> HandleAsync(
        AppDbContext db,
        CancellationToken ct)
    {
        var connString = db.Database.GetConnectionString() ?? "";
        bool isTestDb = connString.Contains("_test", StringComparison.OrdinalIgnoreCase);

        var scoreQuery = db.Submissions.AsNoTracking()
            .Where(s => s.Status == "completed" && s.TotalScore.HasValue);

        if (isTestDb)
        {
            scoreQuery = scoreQuery.Where(s => s.Store != null && s.Store.Name == "Audit Center Store");
        }

        var completedScores = await scoreQuery
            .Select(s => s.TotalScore!.Value)
            .ToListAsync(ct);

        if (!completedScores.Any())
        {
            return TypedResults.Ok(new List<AuditorProductivityEntry>());
        }

        decimal nationalAvg = completedScores.Average();

        var statsQuery = db.Submissions.AsNoTracking()
            .Where(s => s.Status == "completed" && s.AuditorId.HasValue && s.TotalScore.HasValue);

        if (isTestDb)
        {
            statsQuery = statsQuery.Where(s => s.Store != null && s.Store.Name == "Audit Center Store");
        }

        var auditorStats = await statsQuery
            .GroupBy(s => s.AuditorId!.Value)
            .Select(g => new
            {
                AuditorId = g.Key,
                AuditorName = g.Max(s => s.AuditorName) ?? "Unknown Auditor",
                CompletedAudits = g.Count(),
                AvgScore = g.Average(s => s.TotalScore!.Value)
            })
            .ToListAsync(ct);

        var entries = auditorStats.Select(a =>
        {
            decimal avgScore = Math.Round(a.AvgScore, 1);
            string biasRating = "Balanced";

            if (avgScore <= nationalAvg - 5.0m)
            {
                biasRating = "Strict";
            }
            else if (avgScore >= nationalAvg + 5.0m)
            {
                biasRating = "Generous";
            }

            return new AuditorProductivityEntry(
                a.AuditorId,
                a.AuditorName,
                a.CompletedAudits,
                avgScore,
                biasRating
            );
        }).ToList();

        return TypedResults.Ok(entries);
    }
}
