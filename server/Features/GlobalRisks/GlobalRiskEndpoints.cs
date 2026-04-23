using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.GlobalRisks;

/// <summary>
/// Maps the /api/global-risks route group (admin CRUD).
/// Maps the /api/submissions/{submissionId}/risks route group (auditor trigger/list/remove).
/// </summary>
public static class GlobalRiskEndpoints
{
    public static void MapGlobalRiskEndpoints(this WebApplication app)
    {
        // ── Admin CRUD: /api/global-risks ─────────────────────────────────────
        var group = app.MapGroup("/api/global-risks")
            .WithTags("GlobalRisks")
            .RequireAuthorization();

        group.MapPost("/", CreateGlobalRisk.HandleAsync)
            .WithName("CreateGlobalRisk")
            .RequireCapability(AppCapabilities.GlobalRisksManage);

        group.MapGet("/", ListGlobalRisks.HandleAsync)
            .WithName("ListGlobalRisks");
        // No RequireCapability — any authenticated user can read global risks

        group.MapPut("/{id}", UpdateGlobalRisk.HandleAsync)
            .WithName("UpdateGlobalRisk")
            .RequireCapability(AppCapabilities.GlobalRisksManage);

        group.MapDelete("/{id}", DeleteGlobalRisk.HandleAsync)
            .WithName("DeleteGlobalRisk")
            .RequireCapability(AppCapabilities.GlobalRisksManage);

        // ── Submission-scoped: /api/submissions/{submissionId}/risks ──────────
        var riskGroup = app.MapGroup("/api/submissions/{submissionId}/risks")
            .WithTags("SubmissionRisks")
            .RequireAuthorization();

        riskGroup.MapPost("/", TriggerSubmissionRisk.HandleAsync)
            .WithName("TriggerSubmissionRisk");

        riskGroup.MapGet("/", ListSubmissionRisks.HandleAsync)
            .WithName("ListSubmissionRisks");

        riskGroup.MapDelete("/{globalRiskId}", RemoveSubmissionRisk.HandleAsync)
            .WithName("RemoveSubmissionRisk");
    }
}

