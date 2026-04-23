using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// Server-side scoring verifier — C# port of the Flutter scoring engine.
/// Supports Penalty (weighted + checklist fallback), Accumulation, Checklist, and Survey modes.
/// Tolerance: |client - server| must be <= 0.01.
/// </summary>
public sealed class ScoringVerifier
{
    private const decimal Tolerance = 0.01m;

    /// <summary>
    /// Input types that can carry scoring points (measurable).
    /// Metadata types (text, signature, photo, header, date, image) are transparent to purity.
    /// Mirror of Flutter's ScoringEngine._kMeasurableTypes.
    /// </summary>
    private static readonly HashSet<string> MeasurableTypes =
        new(StringComparer.OrdinalIgnoreCase)
        { "pass_fail", "numeric", "scale", "single_choice", "multi_choice" };

    /// <summary>
    /// Returns true if every measurable criterion has a points weight > 0.
    /// One zero-weight measurable criterion anywhere = MIXED = null score.
    /// Mirror of Flutter's ScoringEngine._isPureAudit().
    /// </summary>
    private static bool IsPureAudit(IReadOnlyList<Criterion> criteria)
    {
        return criteria
            .Where(c => MeasurableTypes.Contains(c.InputType ?? string.Empty))
            .All(c => (c.PointsWeight ?? 0) > 0);
    }

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
            return (c.IsRisk || isExplicitOverride) && (isExplicitOverride || HasFaults(c, answers));
        });

        if (riskTriggered)
        {
            var serverScore = 0m;
            var allFailed = BuildFailedSet(criteria, answers);
            return new VerificationResult(
                Math.Abs(clientScore - serverScore) <= Tolerance,
                serverScore,
                "RISK criteria triggered — total score forced to 0%",
                allFailed);
        }

        // Purity gate: mirror of Flutter's _isPureAudit().
        // If any measurable criterion has no points, both client and server return null — no mismatch.
        if (scoringMode != "survey" && !IsPureAudit(criteria))
        {
            return new VerificationResult(true, null, "Mixed audit — purity gate suppressed score", []);
        }

        return scoringMode switch
        {
            "accumulation" => VerifyAccumulation(clientScore, answers, groups, criteria),
            "checklist" => VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty),
            "survey" => new VerificationResult(true, null, "Survey mode — no scoring", []),
            _ => VerifyPenalty(clientScore, answers, groups, criteria, progressiveRepeatPenalty),
        };
    }

    private VerificationResult VerifyPenalty(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenalty)
    {
        var rootGroups = groups.Where(g => g.ParentId == null).ToList();
        var totalWeight = rootGroups.Sum(g => g.Weight ?? 0);
        var isWeighted = totalWeight > 0;

        if (isWeighted)
        {
            var sectionResults = new List<(decimal ratio, decimal weight)>();

            foreach (var section in rootGroups)
            {
                var flatCriteria = criteria.Where(c => c.GroupId == section.Id).ToList();
                var subsections = groups.Where(g => g.ParentId == section.Id).ToList();

                var allCriteria = new List<Criterion>(flatCriteria);
                foreach (var sub in subsections)
                {
                    allCriteria.AddRange(criteria.Where(c => c.GroupId == sub.Id));
                }

                bool ccpTriggered = allCriteria.Any(c => c.IsCcp && HasFaults(c, answers));

                decimal sectionBefore = 0m;
                decimal sectionDeductions = 0m;

                foreach (var sub in subsections)
                {
                    var subCriteria = criteria.Where(c => c.GroupId == sub.Id).ToList();
                    var subBefore = subCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += subBefore;

                    if (subBefore == 0) continue;

                    var subDeductions = subCriteria.Sum(c => GetDeduction(c, answers, progressiveRepeatPenalty));

                    // Cap at MaxDeductionPoints OR subBefore
                    var cap = sub.MaxDeductionPoints ?? subBefore;
                    subDeductions = Math.Min(subDeductions, cap);

                    sectionDeductions += subDeductions;
                }

                if (flatCriteria.Any())
                {
                    var rootFlatBefore = flatCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += rootFlatBefore;

                    var rootFlatDeductions = flatCriteria.Sum(c => GetDeduction(c, answers, progressiveRepeatPenalty));
                    if (section.MaxDeductionPoints.HasValue)
                    {
                        rootFlatDeductions = Math.Min(rootFlatDeductions, section.MaxDeductionPoints.Value);
                    }
                    sectionDeductions += rootFlatDeductions;
                }

                if (sectionBefore == 0) continue;

                // CCP triggered → exclude this section from BOTH numerator and denominator.
                // Mirrors Flutter ScoringEngine._calculatePenalty which uses `continue` to skip the section.
                // Setting ratio=0 while keeping the weight in participatingWeight produces a different
                // weighted average than Flutter → score mismatch → 400. (See GEMINI.override.md)
                if (ccpTriggered) continue;

                var sectionAfter = Math.Max(0m, sectionBefore - sectionDeductions);
                var sectionRatio = sectionAfter / sectionBefore;
                sectionResults.Add((sectionRatio, section.Weight ?? 0));
            }

            var participatingWeight = sectionResults.Sum(p => p.weight);
            var finalScore = 0m;

            if (participatingWeight > 0)
            {
                foreach (var (ratio, weight) in sectionResults)
                {
                    finalScore += ratio * (weight / participatingWeight);
                }
            }

            var serverScore = finalScore * 100m;
            return new VerificationResult(
                Math.Abs(clientScore - Math.Round(serverScore, 2)) <= Tolerance,
                Math.Round(serverScore, 2),
                null,
                BuildFailedSet(criteria, answers),
                IsWeighted: true);
        }
        else
        {
            // Unweighted penalty falls back to checklist scoring.
            // Intercept result and stamp IsWeighted=false — VerifyChecklist must not be modified.
            var checklistResult = VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty);
            return checklistResult with { IsWeighted = false };
        }
    }

    private VerificationResult VerifyChecklist(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenalty)
    {
        // Mirror of Flutter ScoringEngine._calculateChecklist():
        //   score = max(0, 100 - Σ(faults × pointsWeight))
        // NOT a ratio — raw deductions from 100.
        var totalDeductions = criteria.Sum(c => GetDeduction(c, answers, progressiveRepeatPenalty));
        var serverScore = Math.Max(0, 100 - totalDeductions);

        return new VerificationResult(
            Math.Abs(clientScore - serverScore) <= Tolerance,
            Math.Round(serverScore, 2),
            null,
            BuildFailedSet(criteria, answers));
    }

    private VerificationResult VerifyAccumulation(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria)
    {
        var rootGroups = groups.Where(g => g.ParentId == null).ToList();
        decimal totalPossible = 0;
        decimal totalEarned = 0;

        foreach (var section in rootGroups)
        {
            var sectionCriteria = GetCriteriaForGroup(section.Id, groups, criteria);
            var ccpTriggered = sectionCriteria.Any(c => c.IsCcp && HasFaults(c, answers));

            var sectionPossible = sectionCriteria.Sum(c => c.PointsWeight ?? 0);
            var sectionEarned = 0m;

            if (!ccpTriggered)
            {
                foreach (var c in sectionCriteria)
                {
                    var answer = answers.FirstOrDefault(a => a.CriteriaId == c.Id);
                    if (answer is null) continue;

                    if (string.Equals(c.InputType, "scale", StringComparison.OrdinalIgnoreCase)
                        && answer.NumericValue.HasValue)
                    {
                        // Scale: numericValue IS earned points (partial credit)
                        sectionEarned += answer.NumericValue.Value;
                    }
                    else
                    {
                        var isNonConform = string.Equals(answer.Value, "non_conform", StringComparison.OrdinalIgnoreCase);
                        var isConform = string.Equals(answer.Value, "conform", StringComparison.OrdinalIgnoreCase);

                        if (answer.NumericValue.HasValue && answer.Value != null && !isNonConform && !isConform)
                        {
                            // Numeric answer with explicit value label (e.g. "input"): numericValue IS earned points
                            sectionEarned += answer.NumericValue.Value;
                        }
                        else
                        {
                            // Binary: full points if numericValue=0 (no faults), not non_conform, no repeated faults
                            var faults = answer.NumericValue ?? 0;
                            if (faults == 0 && !isNonConform && answer.RepeatedFaults == 0)
                                sectionEarned += c.PointsWeight ?? 0;
                        }
                    }
                }
            }

            totalPossible += sectionPossible;
            totalEarned += sectionEarned;
        }

        var serverScore = totalPossible > 0
            ? totalEarned / totalPossible * 100
            : 100m;

        return new VerificationResult(
            Math.Abs(clientScore - Math.Round(serverScore, 2)) <= Tolerance,
            Math.Round(serverScore, 2),
            null,
            BuildFailedSet(criteria, answers),
            RawEarned: totalEarned,
            RawMax: totalPossible);
    }

    /// <summary>
    /// Builds the set of criteria IDs that semantically failed.
    /// Excludes unscored input types (text, single_choice, multi_choice) — Gotcha #11.
    /// </summary>
    private static HashSet<Guid> BuildFailedSet(
        IReadOnlyList<Criterion> criteria,
        IReadOnlyList<Answer> answers)
    {
        var unscoredTypes = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            { "text", "single_choice", "multi_choice" };

        return criteria
            .Where(c => !unscoredTypes.Contains(c.InputType) && HasFaults(c, answers))
            .Select(c => c.Id)
            .ToHashSet();
    }

    /// <summary>
    /// Gets all criteria belonging to a group and its descendants.
    /// </summary>
    private static List<Criterion> GetCriteriaForGroup(
        Guid groupId,
        IReadOnlyList<Group> allGroups,
        IReadOnlyList<Criterion> allCriteria)
    {
        var result = allCriteria.Where(c => c.GroupId == groupId).ToList();
        var childGroups = allGroups.Where(g => g.ParentId == groupId);
        foreach (var child in childGroups)
        {
            result.AddRange(GetCriteriaForGroup(child.Id, allGroups, allCriteria));
        }
        return result;
    }

    private static bool HasFaults(Criterion criterion, IReadOnlyList<Answer> answers)
    {
        var answer = answers.FirstOrDefault(a => a.CriteriaId == criterion.Id);
        if (answer is null) return false;
        // Pass/fail mode: explicit conform/na → no fault
        if (string.Equals(answer.Value, "conform", StringComparison.OrdinalIgnoreCase)
            || string.Equals(answer.Value, "na", StringComparison.OrdinalIgnoreCase))
            return false;
        // Pass/fail mode: non_conform → fault
        if (string.Equals(answer.Value, "non_conform", StringComparison.OrdinalIgnoreCase))
            return true;
        // Scale mode: numericValue IS earned points (higher = better).
        // A score of 0 earned = fault. Mirror of Flutter ScoringEngine._kScaleType check.
        if (string.Equals(criterion.InputType, "scale", StringComparison.OrdinalIgnoreCase))
            return (answer.NumericValue ?? 0) == 0;
        // Numeric mode (Value is null): numericValue > 0 → fault
        return (answer.NumericValue ?? 0) > 0;
    }

    private static decimal GetDeduction(Criterion criterion, IReadOnlyList<Answer> answers, bool progressiveRepeatPenalty = false)
    {
        var answer = answers.FirstOrDefault(a => a.CriteriaId == criterion.Id);
        if (answer is null) return 0;
        // Pass/fail mode: explicit conform/na → no deduction
        if (string.Equals(answer.Value, "conform", StringComparison.OrdinalIgnoreCase)
            || string.Equals(answer.Value, "na", StringComparison.OrdinalIgnoreCase))
            return 0;
        // C4: minus_impact overrides pointsWeight for deduction
        var impact = criterion.MinusImpact ?? criterion.PointsWeight ?? 0;

        // Numeric mode: faults × impact
        var faults = answer.NumericValue;
        if ((faults == null || faults == 0) && string.Equals(answer.Value, "non_conform", StringComparison.OrdinalIgnoreCase))
        {
            faults = 1;
        }
        var baseDeduction = (faults ?? 0) * impact;
        // C3: progressive repeat penalty (n² × impact)
        if (progressiveRepeatPenalty && answer.RepeatedFaults > 0)
        {
            var repeatDeduction = (decimal)(answer.RepeatedFaults * answer.RepeatedFaults) * impact;
            return baseDeduction + repeatDeduction;
        }
        // Linear repeat penalty (n × impact) — applied even when progressive is OFF
        if (answer.RepeatedFaults > 0)
        {
            return baseDeduction + (answer.RepeatedFaults * impact);
        }
        return baseDeduction;
    }
}
