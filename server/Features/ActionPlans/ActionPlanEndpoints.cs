namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// Maps the /api/action-plans route group.
/// </summary>
public static class ActionPlanEndpoints
{
    public static void MapActionPlanEndpoints(this WebApplication app)
    {
        var group = app.MapGroup("/api/action-plans")
            .WithTags("Action Plans")
            .RequireAuthorization();

        group.MapPost("/", CreateActionPlan.HandleAsync)
            .WithName("CreateActionPlan");

        group.MapGet("/", ListActionPlans.HandleAsync)
            .WithName("ListActionPlans");

        group.MapPut("/{id}", UpdateActionPlan.HandleAsync)
            .WithName("UpdateActionPlan");

        group.MapPost("/{id}/comments", AddComment.HandleAsync)
            .WithName("AddComment");
    }
}
