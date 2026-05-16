namespace Checkly.Api.Features.ActionPlans;

/// <summary>
/// Canonical action key constants for Action Plan HATEOAS responses.
/// These strings are the server-side mirror of lib/_shared/constants/action_plan_actions.dart.
/// Both sides MUST stay in sync. Do not use plain strings elsewhere.
/// </summary>
public static class ActionPlanActions
{
    public const string View = "view";
    public const string SubmitEvidence = "submit_evidence";
    public const string VerifyClose = "verify_close";
    public const string RejectEvidence = "reject_evidence";
}
