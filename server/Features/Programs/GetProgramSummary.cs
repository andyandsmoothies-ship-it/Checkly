using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Auth;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace Checkly.Api.Features.Programs;

public static class GetProgramSummary
{
    public static async Task<IResult> Handle(Guid programId, AppDbContext db, ClaimsPrincipal user)
    {
        // 1. Validate Program exists & get deadline (for overdue calculation)
        var program = await db.Programs.AsNoTracking().FirstOrDefaultAsync(p => p.Id == programId);
        if (program == null)
        {
            return Results.NotFound(new { message = "Program not found." });
        }

        // 2. Fetch aggregated status counts from the database
        var statusCounts = await db.ProgramAssignments
            .AsNoTracking()
            .Where(a => a.ProgramId == programId)
            .GroupBy(a => a.Status)
            .Select(g => new { Status = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Status, x => x.Count);

        var total = statusCounts.Values.Sum();
        if (total == 0)
        {
            return Results.Ok(new ProgramSummaryResponse(0, 0, 0, 0, 0, 0, 0));
        }

        // 3. Extract counts
        var now = DateTimeOffset.UtcNow;
        var isProgramDeadlinePassed = program.Deadline < now;

        var rawPending = statusCounts.GetValueOrDefault("pending");
        int pendingCount = isProgramDeadlinePassed ? 0 : rawPending;
        int overdueCount = isProgramDeadlinePassed ? rawPending : 0;
        int submittedCount = statusCounts.GetValueOrDefault("submitted");
        int needsRevisionCount = statusCounts.GetValueOrDefault("needs_revision");
        int verifiedCount = statusCounts.GetValueOrDefault("verified");

        // 4. Calculate Completion Rate
        // Definition: (Submitted + NeedsRevision + Verified) / Total
        var completed = submittedCount + needsRevisionCount + verifiedCount;
        var completionRate = (completed * 100) / total;

        return Results.Ok(new ProgramSummaryResponse(
            total,
            pendingCount,
            overdueCount,
            submittedCount,
            needsRevisionCount,
            verifiedCount,
            completionRate
        ));
    }
}
