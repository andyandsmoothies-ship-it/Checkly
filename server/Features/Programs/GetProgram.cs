using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// GET /api/programs/{id} — Retrieve a single program by ID.
/// Security: Requires programs:list capability (admin only).
///
/// Returns the same ProgramSummaryDto shape as ListPrograms.
/// TotalAssigned is computed inline to keep the handler simple.
/// </summary>
public static class GetProgram
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        AppDbContext db,
        CancellationToken ct)
    {
        var program = await db.Programs
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, ct);

        if (program is null)
            return TypedResults.NotFound(new { error = "Program not found." });

        var totalAssigned = await db.ProgramAssignments
            .CountAsync(a => a.ProgramId == id, ct);

        return TypedResults.Ok(new ProgramSummaryDto(
            program.Id,
            program.Title,
            program.Category,
            program.Deadline,
            program.Status,
            totalAssigned,
            program.CreatedAt));
    }
}
