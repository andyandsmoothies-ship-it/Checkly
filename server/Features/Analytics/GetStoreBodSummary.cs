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
/// GET /api/analytics/stores/{storeId:guid}/bod-summary — Store BOD summary.
/// </summary>
public static class GetStoreBodSummary
{
    public static async Task<IResult> HandleAsync(
        Guid storeId,
        AppDbContext db,
        CancellationToken ct)
    {
        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == storeId, ct);

        if (store == null)
        {
            return TypedResults.NotFound();
        }

        var recentAudits = await db.Submissions
            .AsNoTracking()
            .Where(s => s.StoreId == storeId && s.Status == "completed")
            .OrderByDescending(s => s.CompletedAt)
            .Take(5)
            .Select(s => new RecentAuditEntry(
                s.CompletedAt ?? s.CreatedAt,
                s.TotalScore ?? 0m,
                s.AuditorName ?? "Unknown"
            ))
            .ToListAsync(ct);

        var categoryBreakdownRaw = await db.SubmissionSectionScores
            .AsNoTracking()
            .Where(ss => ss.StoreId == storeId && ss.MaxScore > 0)
            .GroupBy(ss => ss.SectionTitle)
            .Select(g => new
            {
                CategoryName = g.Key,
                TotalScore = g.Sum(ss => ss.Score),
                TotalMaxScore = g.Sum(ss => ss.MaxScore)
            })
            .ToListAsync(ct);

        var categoryBreakdown = categoryBreakdownRaw
            .Select(x => new CategoryScoreEntry(
                x.CategoryName,
                x.TotalMaxScore > 0 ? Math.Round(x.TotalScore / x.TotalMaxScore * 100.0m, 1) : 0m
            ))
            .ToList();

        return TypedResults.Ok(new StoreBodSummary(
            store.Name,
            recentAudits,
            categoryBreakdown
        ));
    }
}
