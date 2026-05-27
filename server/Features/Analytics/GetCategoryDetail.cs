using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace Checkly.Api.Features.Analytics;

/// <summary>
/// GET /api/analytics/bod/category/{name} — Category detail showing worst-performing stores.
/// </summary>
public static class GetCategoryDetail
{
    public static async Task<IResult> HandleAsync(
        string name,
        AppDbContext db,
        IMemoryCache cache,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(name))
        {
            return TypedResults.BadRequest();
        }

        var trimmedName = name.Trim();
        var cacheKey = $"bod_category_detail_{trimmedName.ToLowerInvariant()}";

        if (!cache.TryGetValue(cacheKey, out List<CategoryStoreEntry>? entries))
        {
            var rawItems = await db.SubmissionSectionScores
                .AsNoTracking()
                .Where(ss => ss.SectionTitle == trimmedName && ss.Submission != null && ss.Submission.Status == "completed" && ss.MaxScore > 0)
                .GroupBy(ss => new { ss.StoreId, ss.Submission!.StoreName })
                .Select(g => new
                {
                    StoreName = g.Key.StoreName ?? "Unknown Store",
                    TotalScore = g.Sum(ss => ss.Score),
                    TotalMaxScore = g.Sum(ss => ss.MaxScore),
                    AuditCount = g.Select(ss => ss.SubmissionId).Distinct().Count(),
                    FailureCount = g.Count(ss => ss.IsCcpFailed)
                })
                .OrderBy(x => x.TotalMaxScore > 0 ? (x.TotalScore / x.TotalMaxScore) : 0m)
                .Take(50)
                .ToListAsync(ct);

            entries = rawItems.Select(x => new CategoryStoreEntry(
                x.StoreName,
                x.TotalMaxScore > 0 ? Math.Round(x.TotalScore / x.TotalMaxScore * 100.0m, 1) : 0m,
                x.AuditCount,
                x.FailureCount
            )).ToList();

            cache.Set(cacheKey, entries, TimeSpan.FromSeconds(120));
        }

        return TypedResults.Ok(entries);
    }
}
