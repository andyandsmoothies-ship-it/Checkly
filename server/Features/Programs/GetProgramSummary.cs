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

        // 2. Fetch all assignments for this program
        // We only need the statuses to aggregate. We project it to avoid loading full entities.
        var statuses = await db.ProgramAssignments
            .AsNoTracking()
            .Where(a => a.ProgramId == programId)
            .Select(a => a.Status)
            .ToListAsync();

        var total = statuses.Count;
        if (total == 0)
        {
            return Results.Ok(new ProgramSummaryResponse(0, 0, 0, 0, 0, 0, 0));
        }

        // 3. Aggregate counts
        var now = DateTimeOffset.UtcNow;
        var isProgramDeadlinePassed = program.Deadline < now;

        int pendingCount = 0;
        int overdueCount = 0;
        int submittedCount = 0;
        int needsRevisionCount = 0;
        int verifiedCount = 0;

        foreach (var status in statuses)
        {
            switch (status)
            {
                case "pending":
                    if (isProgramDeadlinePassed)
                    {
                        overdueCount++;
                    }
                    else
                    {
                        pendingCount++;
                    }
                    break;
                case "submitted":
                    submittedCount++;
                    break;
                case "needs_revision":
                    needsRevisionCount++;
                    break;
                case "verified":
                    verifiedCount++;
                    break;
            }
        }

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
