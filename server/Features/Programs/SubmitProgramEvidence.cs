using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// POST /api/programs/assignments/{id}/submit
/// Stores evidence items and transitions the assignment status to "submitted".
/// Security:
///   - Endpoint is restricted via PBAC capability (programs:execute).
///   - IDOR guard: assignment.StoreId MUST match the caller's Profile.StoreId → 404 on mismatch.
/// Idempotency: Double-submit on a non-pending assignment → 400 BadRequest.
/// </summary>
public static class SubmitProgramEvidence
{
    public static async Task<IResult> HandleAsync(
        Guid id,
        SubmitEvidenceRequest request,
        ClaimsPrincipal user,
        AppDbContext db,
        CancellationToken ct)
    {
        // Validation: evidence array must not be empty
        if (request.EvidenceItems is null || request.EvidenceItems.Length == 0)
            return TypedResults.BadRequest(new { error = "evidenceItems must not be empty." });

        var userId = Guid.Parse(user.FindFirstValue(ClaimTypes.NameIdentifier)!);

        // Resolve caller's store from Profile — never trust request data for scoping
        var profile = await db.Profiles
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == userId, ct);

        if (profile?.StoreId is null)
            return TypedResults.NotFound(new { error = "Caller has no assigned store." });

        // Load assignment — scoped to caller's store (IDOR protection: 404 on cross-store)
        var assignment = await db.ProgramAssignments
            .FirstOrDefaultAsync(a => a.Id == id && a.StoreId == profile.StoreId.Value, ct);

        if (assignment is null)
            return TypedResults.NotFound(new { error = "Assignment not found." });

        // Idempotency guard: only pending or needs_revision assignments can be (re-)submitted.
        // GapAC1: needs_revision is also a valid source state — SM is resubmitting after HQ rejection.
        if (assignment.Status != "pending" && assignment.Status != "needs_revision")
            return TypedResults.BadRequest(new { error = "Assignment has already been submitted." });

        // Persist evidence items
        var evidenceItems = request.EvidenceItems.Select(item => new ProgramEvidence
        {
            AssignmentId = assignment.Id,
            CriteriaId = item.CriteriaId,
            CriteriaLabel = string.Empty, // Populated from criteria snapshot when criteria entity is linked
            Value = item.Value,
            PhotoLocalKey = item.PhotoLocalKey,
            CreatedAt = DateTimeOffset.UtcNow
        }).ToList();

        db.ProgramEvidence.AddRange(evidenceItems);

        // Transition status and clear the rejection comment (GapAC1)
        assignment.Status = "submitted";
        assignment.CompletedAt = DateTimeOffset.UtcNow;
        assignment.UpdatedAt = DateTimeOffset.UtcNow;
        assignment.RejectionComment = null;  // GapAC1: clear rejection on resubmit

        AuditLogger.Log(db, user, "program_submitted", "ProgramAssignment", assignment.Id,
            $"SM submitted {evidenceItems.Count} evidence item(s) for assignment {assignment.Id}.",
            $"/api/programs/assignments/{assignment.Id}/submit");

        await db.SaveChangesAsync(ct);

        return TypedResults.Ok(new { newStatus = "submitted" });
    }
}
