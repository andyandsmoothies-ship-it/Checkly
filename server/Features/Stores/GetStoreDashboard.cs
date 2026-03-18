using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// GET /api/stores/{id}/dashboard — store-level metrics.
/// </summary>
public static class GetStoreDashboard
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AppDbContext db,
        CancellationToken ct)
    {
        var store = await db.Stores
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == id, ct);

        if (store is null)
            return TypedResults.NotFound(new { error = "Store not found" });

        var submissions = await db.Submissions
            .AsNoTracking()
            .Where(s => s.StoreId == id && s.Status == "completed" && s.ReviewStatus != "rejected")
            .OrderByDescending(s => s.CreatedAt)
            .Take(20)
            .Select(s => new
            {
                s.Id,
                s.TemplateTitle,
                s.TotalScore,
                s.AuditorName,
                s.CreatedAt,
            })
            .ToListAsync(ct);

        var scored = submissions.Where(s => s.TotalScore.HasValue).ToList();
        var avgScore = scored.Count > 0
            ? Math.Round(scored.Average(s => (double)s.TotalScore!.Value), 1)
            : 0.0;

        var openAPs = await db.ActionPlans
            .CountAsync(ap => ap.StoreId == id && ap.Status == "open", ct);

        // Fetch pre-computed snapshot (may not exist yet)
        var snapshot = await db.StoreAnalyticsSnapshots
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.StoreId == id, ct);

        return TypedResults.Ok(new
        {
            store = new { store.Id, store.Name, store.Address, store.AreaId },
            avgScore,
            totalAudits = submissions.Count,
            openActionPlans = openAPs,
            recentAudits = submissions,
            // Snapshot fields (S3.2)
            avgScore30d = snapshot?.AvgScore30d ?? 0m,
            lastAuditScore = snapshot?.LastAuditScore,
            overdueActionPlans = snapshot?.OverdueActionPlans ?? 0,
        });
    }
}
