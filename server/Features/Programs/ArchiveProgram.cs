using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// DELETE /api/programs/{id} — Soft-archive a program by setting Status = 'cancelled'.
/// Security: Requires programs:manage capability (admin only).
///
/// Design decisions:
///   - Soft-delete only. Hard-delete is prohibited: ProgramAssignments have a FK
///     with Restrict on delete which would cause a DB exception.
///   - Existing in-flight assignments are NOT cascaded to 'cancelled' (out of scope).
///   - The guard against double-archive (TC-A4) prevents idempotency abuse.
///
/// Business rules:
///   - Program must exist (404).
///   - Program must not already be 'cancelled' (400).
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
}
