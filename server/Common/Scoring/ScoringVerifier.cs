using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// Server-side scoring verifier — C# port of the Flutter scoring engine.
/// Dispatches on two fields: scoreDirection ("up"/"down"/"none") and isWeighted (bool).
/// Dispatch matrix:
///   "none"              → Survey (no score)
///   "up"  + any         → Accumulation
///   "down" + weighted   → Penalty (group-weighted)
///   "down" + unweighted → Checklist (flat)
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
        string scoreDirection = "down",
        bool isWeighted = false,
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
        if (scoreDirection != "none" && !ScoringHelpers.IsPureAudit(criteria))
        {
            return new VerificationResult(true, null, "Mixed audit — purity gate suppressed score", []);
        }

        // 2-D dispatch: direction first, then weight flag.
        return scoreDirection switch
        {
            "none" => new VerificationResult(true, null, "Survey mode — no scoring", []),
            "up" => ScoringCalculators.VerifyAccumulation(clientScore, answers, groups, criteria, Tolerance),
            "down" when isWeighted
                   => ScoringCalculators.VerifyPenalty(clientScore, answers, groups, criteria, progressiveRepeatPenalty, Tolerance),
            "down" =>
                   ScoringCalculators.VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty, Tolerance)
                       with
                   { IsWeighted = false },
            _ =>
                   ScoringCalculators.VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty, Tolerance)
                       with
                   { IsWeighted = false },
        };
    }
}
