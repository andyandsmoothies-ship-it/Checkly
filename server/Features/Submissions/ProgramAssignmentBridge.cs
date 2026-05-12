using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Validates and links a POST /api/submissions request to a ProgramAssignment.
/// Called only when CreateSubmissionRequest.ProgramAssignmentId is non-null.
///
/// Enforces a 3-condition IDOR guard (must all pass):
///   1. Caller has programs:execute capability  → 403 if missing
///   2. Assignment exists                        → 404 if missing
///   3. Assignment belongs to caller's store     → 403 if mismatch (IDOR)
///   4. Assignment's Program template matches    → 400 if mismatch
/// </summary>
public static class ProgramAssignmentBridge
{
    /// <summary>
    /// Validates the 3-condition IDOR guard and returns the loaded assignment on success,
    /// or an IResult error on failure. Never throws.
    /// </summary>
    public static async Task<(ProgramAssignment? Assignment, IResult? Error)> ValidateAndLinkAsync(
        Guid assignmentId,
        Guid requestTemplateId,
        Guid callerStoreId,
        ClaimsPrincipal user,
        PbacDictionaryCache pbac,
        AppDbContext db,
        CancellationToken ct)
    {
        // Guard 1: Caller must have programs:execute (mirrors CapabilityAuthorizationHandler pattern)
        var role = user.FindFirstValue(ClaimTypes.Role);
        if (role is null || !pbac.IsReady)
            return (null, TypedResults.Forbid());

        var capabilities = pbac.GetCapabilities(role);
        if (!capabilities.Contains(AppCapabilities.ProgramsExecute))
            return (null, TypedResults.Forbid());

        // Guard 2: Assignment must exist (with its parent Program for template check)
        var assignment = await db.ProgramAssignments
            .Include(a => a.Program)
            .FirstOrDefaultAsync(a => a.Id == assignmentId, ct);

        if (assignment is null)
            return (null, TypedResults.NotFound());

        // Guard 3: IDOR — assignment must belong to caller's store
        if (assignment.StoreId != callerStoreId)
            return (null, TypedResults.Forbid());

        // Guard 4: Template must match the program's configured template
        if (assignment.Program!.TemplateId != requestTemplateId)
            return (null, TypedResults.BadRequest(new { error = "Template mismatch: the supplied templateId does not match the program's template." }));

        return (assignment, null);
    }
}
