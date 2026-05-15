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

        // POST /api/programs/assignments/{id}/submit — PBAC-gated program execution
        group.MapPost("/assignments/{id}/submit", SubmitProgramEvidence.HandleAsync)
            .WithName("SubmitProgramEvidence")
            .RequireCapability(AppCapabilities.ProgramsExecute);

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

        // ── Slice CM05: Area Manager Campaign Reporting ────────────────────────

        // GET /api/programs/area-progress — AM views campaign completion for their assigned stores
        // NOTE: Must be declared BEFORE /{id} catch-all to prevent interception.
        group.MapGet("/area-progress", GetAreaCampaignProgress.HandleAsync)
            .WithName("GetAreaCampaignProgress")
            .RequireCapability(AppCapabilities.ProgramsAssignmentsList);

        // ── Slice 6: CRUD Parity ───────────────────────────────────────────────

        // PUT /api/programs/{id} — Admin updates mutable fields on an active program
        group.MapPut("/{id}", UpdateProgram.HandleAsync)
            .WithName("UpdateProgram")
            .RequireCapability(AppCapabilities.ProgramsManage);

        // DELETE /api/programs/{id} — Admin soft-archives a program
        group.MapDelete("/{id}", ArchiveProgram.HandleAsync)
            .WithName("ArchiveProgram")
            .RequireCapability(AppCapabilities.ProgramsManage);

        // GET /api/programs/{id} — Retrieve a single program by ID
        // NOTE: Must be declared AFTER all more-specific sub-path routes (e.g. /{id}/assignments)
        // to prevent the catch-all parameter from intercepting them.
        group.MapGet("/{id}", GetProgram.HandleAsync)
            .WithName("GetProgram")
            .RequireCapability(AppCapabilities.ProgramsList);
    }
}
