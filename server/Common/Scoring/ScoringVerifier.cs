using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// Server-side scoring verifier — C# port of the Flutter scoring engine.
/// Supports Penalty (weighted + checklist fallback), Accumulation, Checklist, and Survey modes.
/// Tolerance: |client - server| must be &lt;= 0.01.
///
/// SC-5: Math helpers extracted to ScoringHelpers.cs. Mode implementations in ScoringCalculators.cs.
/// </summary>
public sealed class ScoringVerifier
{
    private const decimal Tolerance = 0.01m;

    public sealed record VerificationResult(
        bool IsValid,
        decimal? ServerScore,
        string? Reason,
        HashSet<Guid> FailedCriteriaIds,
        decimal? RawEarned = null,
        decimal? RawMax = null,
        bool? IsWeighted = null);

    /// <summary>
    /// Verifies the client-submitted score against a server-side recalculation.
    /// </summary>
    public VerificationResult Verify(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenalty = false,
        string scoringMode = "penalty",
        HashSet<Guid>? explicitRiskAnswerIds = null,
        bool hasGlobalRisk = false)
    {
        // Check for RISK — three paths:
        //   1. Template-level RISK (c.IsRisk=true from template) → requires a fault (HasFaults)
        //   2. Answer-level override (auditor explicitly set isRisk=true) → unconditional trigger
        //   3. Global Risk Domain (hasGlobalRisk=true) → unconditional trigger
        var riskTriggered = hasGlobalRisk || criteria.Any(c =>
        {
            var isExplicitOverride = explicitRiskAnswerIds?.Contains(c.Id) ?? false;
            return (c.IsRisk || isExplicitOverride) && (isExplicitOverride || ScoringHelpers.HasFaults(c, answers));
        });

        if (riskTriggered)
        {
            var serverScore = 0m;
            var allFailed = ScoringHelpers.BuildFailedSet(criteria, answers);
            return new VerificationResult(
                Math.Abs(clientScore - serverScore) <= Tolerance,
                serverScore,
                "RISK criteria triggered — total score forced to 0%",
                allFailed);
        }

        // Purity gate: mirror of Flutter's _isPureAudit().
        // If any measurable criterion has no points, both client and server return null — no mismatch.
        if (scoringMode != "survey" && !ScoringHelpers.IsPureAudit(criteria))
        {
            return new VerificationResult(true, null, "Mixed audit — purity gate suppressed score", []);
        }

        return scoringMode switch
        {
            "accumulation" => ScoringCalculators.VerifyAccumulation(clientScore, answers, groups, criteria, Tolerance),
            "checklist" => ScoringCalculators.VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty, Tolerance),
            "survey" => new VerificationResult(true, null, "Survey mode — no scoring", []),
            _ => ScoringCalculators.VerifyPenalty(clientScore, answers, groups, criteria, progressiveRepeatPenalty, Tolerance),
        };
    }
}
