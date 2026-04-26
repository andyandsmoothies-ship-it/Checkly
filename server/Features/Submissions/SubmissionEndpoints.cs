using Checkly.Api.Common.Auth;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Maps the /api/submissions route group (requires authentication).
/// </summary>
public static class SubmissionEndpoints
{
    public static IEndpointConventionBuilder MapSubmissionEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/submissions")
            .WithTags("Submissions")
            .RequireAuthorization();

        group.MapPost("/", CreateSubmission.HandleAsync)
            .WithName("CreateSubmission")
            .RequireCapability(AppCapabilities.SubmissionsCreate);

        group.MapGet("/", ListSubmissions.HandleAsync)
            .WithName("ListSubmissions")
            .RequireCapability(AppCapabilities.SubmissionsList);


        group.MapGet("/survey-results", GetSurveyResults.HandleAsync)
            .WithName("GetSurveyResults")
            .RequireCapability(AppCapabilities.AnalyticsAdmin);

        group.MapGet("/{id}", GetSubmission.HandleAsync)
            .WithName("GetSubmission");

        group.MapPut("/{id}", UpdateSubmission.HandleAsync)
            .WithName("UpdateSubmission");

        group.MapPut("/{id}/review", ReviewSubmission.HandleAsync)
            .WithName("ReviewSubmission")
            .RequireCapability(AppCapabilities.SubmissionsReview);

        group.MapPut("/{id}/finalize", FinalizeSubmission.HandleAsync)
            .WithName("FinalizeSubmission");

        group.MapPost("/{id}/void", VoidSubmission.HandleAsync)
            .WithName("VoidSubmission");

        return group;
    }
}
