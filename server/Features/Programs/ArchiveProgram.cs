using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// Handles both DELETE /api/programs/{id} and POST /api/programs/{id}/archive.
/// Security: Requires programs:manage capability (admin only).
/// </summary>
public static class ArchiveProgram
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var program = await db.Programs
            .FirstOrDefaultAsync(p => p.Id == id, ct);

        if (program is null)
            return TypedResults.NotFound(new { error = "Program not found." });

        // Guard: cannot archive an already-cancelled program (idempotency guard)
        if (program.Status == ProgramStatus.Cancelled)
            return TypedResults.BadRequest(new { error = "Program is already cancelled." });

        program.Status = ProgramStatus.Cancelled;
        program.UpdatedAt = DateTimeOffset.UtcNow;

        AuditLogger.Log(db, user, "program_archived", "Program", program.Id,
            $"Program '{program.Title}' archived (status set to cancelled).",
            $"/api/programs/{id}");

        await db.SaveChangesAsync(ct);

        return TypedResults.NoContent();
    }

    public static async Task<IResult> HandlePostArchiveAsync(
        Guid id,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        var program = await db.Programs
            .FirstOrDefaultAsync(p => p.Id == id, ct);

        if (program is null)
            return TypedResults.NotFound(new { error = "Program not found." });

        if (program.Status == ProgramStatus.Cancelled)
            return TypedResults.Conflict(new { error = "Program is already archived." });

        program.Status = ProgramStatus.Cancelled;
        program.UpdatedAt = DateTimeOffset.UtcNow;

        AuditLogger.Log(db, user, "program_archived", "Program", program.Id,
            $"Program '{program.Title}' archived (status set to cancelled).",
            $"/api/programs/{id}");

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { status = "archived" });
    }
}
