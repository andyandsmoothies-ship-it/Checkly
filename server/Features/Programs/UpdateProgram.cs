using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// PUT /api/programs/{id} — Update mutable fields on an active program.
/// Security: Requires programs:manage capability (admin only).
///
/// Mutable fields: Title, Deadline, Category.
/// Immutable: TemplateId, StoreIds (changing these would corrupt existing assignments).
///
/// Business rules:
///   - Program must exist (404).
///   - Program must be 'active' — cannot update a cancelled program (400).
///   - Deadline must be in the future (400).
///   - Title cannot be empty (400).
///   - Concurrent updates are safe via EF Core's xmin-based optimistic concurrency (409).
/// </summary>
public static class UpdateProgram
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        UpdateProgramRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Guard: title cannot be empty
        if (string.IsNullOrWhiteSpace(request.Title))
            return TypedResults.BadRequest(new { error = "Title cannot be empty." });

        // Guard: deadline must be in the future
        if (request.Deadline <= DateTimeOffset.UtcNow)
            return TypedResults.BadRequest(new { error = "Deadline must be in the future." });

        var program = await db.Programs
            .FirstOrDefaultAsync(p => p.Id == id, ct);

        if (program is null)
            return TypedResults.NotFound(new { error = "Program not found." });

        // Guard: cannot update a cancelled program
        if (program.Status == ProgramStatus.Cancelled)
            return TypedResults.BadRequest(new { error = "Cannot update a cancelled program." });

        var before = $"Title='{program.Title}', Deadline={program.Deadline:O}, Category='{program.Category}'";

        program.Title = request.Title;
        program.Deadline = request.Deadline;
        program.Category = request.Category;
        program.UpdatedAt = DateTimeOffset.UtcNow;

        var after = $"Title='{program.Title}', Deadline={program.Deadline:O}, Category='{program.Category}'";

        AuditLogger.Log(db, user, "program_updated", "Program", program.Id,
            $"Program updated. Before: [{before}]. After: [{after}].",
            $"/api/programs/{id}");

        try
        {
            await db.SaveChangesAsync(ct);
        }
        catch (DbUpdateConcurrencyException)
        {
            return TypedResults.Conflict(new { error = "Program was modified by another request. Please retry." });
        }

        return TypedResults.Ok(new ProgramSummaryDto(
            program.Id,
            program.Title,
            program.Category,
            program.Deadline,
            program.Status,
            0, // TotalAssigned not re-fetched — caller can refresh from ListPrograms
            program.CreatedAt));
    }
}
