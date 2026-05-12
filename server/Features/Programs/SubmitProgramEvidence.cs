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
    public static Task<IResult> HandleAsync(Guid id)
    {
        return Task.FromResult<IResult>(TypedResults.Problem(
            statusCode: 410,
            title: "Gone",
            detail: "Use POST /api/submissions with programAssignmentId instead."));
    }
}
