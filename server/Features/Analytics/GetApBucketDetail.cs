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
/// GET /api/analytics/bod/ap/{bucket} — retrieves the detailed open action plans for a specific aging bucket.
/// </summary>
public static class GetApBucketDetail
{
    private static readonly HashSet<string> ValidBuckets = new(StringComparer.OrdinalIgnoreCase)
    {
        "0-7d",
        "8-30d",
        "31-90d",
        "90d+"
    };

    public static async Task<IResult> HandleAsync(
        string bucket,
        AppDbContext db,
        CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(bucket) || !ValidBuckets.Contains(bucket))
        {
            return TypedResults.BadRequest(new { error = "Invalid bucket value. Allowed values: 0-7d, 8-30d, 31-90d, 90d+" });
        }

        var now = DateTimeOffset.UtcNow;
        var query = db.ActionPlans
            .Include(ap => ap.Store)
            .AsNoTracking()
            .Where(ap => ap.Status == "open");

        if (bucket.Equals("0-7d", StringComparison.OrdinalIgnoreCase))
        {
            var cutoff = now.AddDays(-7);
            query = query.Where(ap => ap.CreatedAt >= cutoff && ap.CreatedAt <= now);
        }
        else if (bucket.Equals("8-30d", StringComparison.OrdinalIgnoreCase))
        {
            var start = now.AddDays(-30);
            var end = now.AddDays(-7);
            query = query.Where(ap => ap.CreatedAt >= start && ap.CreatedAt < end);
        }
        else if (bucket.Equals("31-90d", StringComparison.OrdinalIgnoreCase))
        {
            var start = now.AddDays(-90);
            var end = now.AddDays(-30);
            query = query.Where(ap => ap.CreatedAt >= start && ap.CreatedAt < end);
        }
        else if (bucket.Equals("90d+", StringComparison.OrdinalIgnoreCase))
        {
            var cutoff = now.AddDays(-90);
            query = query.Where(ap => ap.CreatedAt < cutoff);
        }

        var results = await query.ToListAsync(ct);

        var entries = results.Select(ap => new ApDetailEntry(
            ap.Id,
            ap.CriteriaLabel,
            ap.Store?.Name ?? ap.StoreName ?? "Unknown Store",
            ap.StoreManagerName ?? "Unknown Manager",
            (int)Math.Max(0, (now - ap.CreatedAt).TotalDays)
        )).ToList();

        return TypedResults.Ok(entries);
    }
}
