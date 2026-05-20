using System;
using System.Linq;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.ActionPlans;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

public static class StoreAnalyticsUpdater
{
    public static async Task UpdateMetricsAsync(Guid? storeId, Submission submission, AppDbContext db, DateTimeOffset now, CancellationToken ct)
    {
        if (!storeId.HasValue)
            return;

        var thirtyDaysAgo = now.AddDays(-30);
        var storeIdVal = storeId.Value;

        // Recalculate 30-day metrics from live data
        var query = db.Submissions
            .Where(s => s.StoreId == storeIdVal
                && s.Status == SubmissionStatus.Completed
                && s.CompletedAt >= thirtyDaysAgo
                && s.TotalScore.HasValue);

        var totalAudits = await query.CountAsync(ct);
        var avgScoreRaw = totalAudits > 0 ? await query.AverageAsync(s => s.TotalScore!.Value, ct) : 0m;
        var avgScore = Math.Round(avgScoreRaw, 1);

        var openAPs = await db.ActionPlans
            .CountAsync(ap => ap.StoreId == storeIdVal && ap.Status == ActionPlanStatus.Open, ct);
        var overdueAPs = await db.ActionPlans
            .CountAsync(ap => ap.StoreId == storeIdVal
                && ap.Status == ActionPlanStatus.Open
                && ap.Deadline.HasValue
                && ap.Deadline < now, ct);

        var snapshot = await db.StoreAnalyticsSnapshots
            .FirstOrDefaultAsync(s => s.StoreId == storeIdVal, ct);

        if (snapshot is null)
        {
            snapshot = new StoreAnalyticsSnapshot { StoreId = storeIdVal };
            db.StoreAnalyticsSnapshots.Add(snapshot);
        }

        snapshot.AvgScore30d = avgScore;
        snapshot.TotalAudits30d = totalAudits;
        snapshot.OpenActionPlans = openAPs;
        snapshot.OverdueActionPlans = overdueAPs;
        snapshot.LastAuditScore = submission.TotalScore;
        snapshot.LastAuditAt = submission.CompletedAt;
        snapshot.UpdatedAt = now;

        await db.SaveChangesAsync(ct);
    }
}
