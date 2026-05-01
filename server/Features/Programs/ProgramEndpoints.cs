using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.Programs;

/// <summary>
/// Maps the /api/programs route group.
/// </summary>
public static class ProgramEndpoints
{
    public static void MapProgramEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/programs")
            .WithTags("Programs")
            .RequireAuthorization();

        group.MapPost("/", CreateProgram.HandleAsync)
            .WithName("CreateProgram")
            .RequireCapability(AppCapabilities.ProgramsCreate);

        group.MapGet("/", ListPrograms.HandleAsync)
            .WithName("ListPrograms_Programs")
            .RequireCapability(AppCapabilities.ProgramsList);

        // ── Slice 2A: SM Execution ────────────────────────────────────────────

        // GET /api/programs/assignments/my — SM syncs their own store's assignments
        group.MapGet("/assignments/my", GetMyAssignments.HandleAsync)
            .WithName("GetMyAssignments")
            .RequireCapability(AppCapabilities.ProgramsAssignmentsMy);

        // POST /api/programs/assignments/{id}/submit — role-guarded to store_manager ONLY
        // Admin → 403 by design (TC4). No PBAC capability: execution is role-exclusive.
        group.MapPost("/assignments/{id}/submit", SubmitProgramEvidence.HandleAsync)
            .WithName("SubmitProgramEvidence")
            .RequireAuthorization(policy => policy.RequireRole("store_manager"));

        // ── Slice 3: HQ Review ────────────────────────────────────────────────

        // GET /api/programs/{programId}/assignments — HQ views all store assignments
        group.MapGet("/{programId}/assignments", GetProgramAssignments.HandleAsync)
            .WithName("GetProgramAssignments")
            .RequireCapability(AppCapabilities.ProgramsAssignmentsList);

        // ── Slice 4: Verification & Rejection Engine ──────────────────────────

        // POST /api/programs/assignments/{id}/reject — HQ rejects a submitted assignment
        group.MapPost("/assignments/{id}/reject", RejectProgramAssignment.HandleAsync)
            .WithName("RejectProgramAssignment")
            .RequireCapability(AppCapabilities.ProgramsReview);

        // POST /api/programs/assignments/{id}/verify — HQ verifies a submitted assignment
        group.MapPost("/assignments/{id}/verify", VerifyProgramAssignment.HandleAsync)
            .WithName("VerifyProgramAssignment")
            .RequireCapability(AppCapabilities.ProgramsReview);

        // ── Slice 5: Analytics & Aggregation ──────────────────────────────────
        
        // GET /api/programs/{programId}/summary — HQ gets completion summary
        group.MapGet("/{programId}/summary", GetProgramSummary.Handle)
            .WithName("GetProgramSummary")
            .RequireCapability(AppCapabilities.ProgramsAssignmentsList);
    }
}
