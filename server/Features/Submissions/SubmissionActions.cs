namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Canonical string constants for Submission action keys.
/// These mirror the Dart SubmissionActions constants in lib/_shared/constants/submission_actions.dart.
/// RULE: Never use raw strings — always reference these constants.
/// </summary>
public static class SubmissionActions
{
    public const string View = "view";
    public const string Edit = "edit";
    public const string Finalize = "finalize";
    public const string Void = "void";
}
