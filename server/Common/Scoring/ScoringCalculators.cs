using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// SC-5: Extracted from ScoringVerifier.cs — the three scoring mode implementations.
/// Each method is a pure function: same inputs → same output. No side effects.
/// Callers use ScoringVerifier.Verify() which selects the correct mode.
/// </summary>
internal static class ScoringCalculators
{
    internal static ScoringVerifier.VerificationResult VerifyPenalty(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenalty,
        decimal tolerance)
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

                bool ccpTriggered = allCriteria.Any(c =>
                    (answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
                    (c.IsCcp && ScoringHelpers.HasFaults(c, answers)));

                decimal sectionBefore = 0m;
                decimal sectionDeductions = 0m;

                foreach (var sub in subsections)
                {
                    var subCriteria = criteria.Where(c => c.GroupId == sub.Id).ToList();
                    var subBefore = subCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += subBefore;

                    if (subBefore == 0) continue;

                    var subDeductions = subCriteria.Sum(c => ScoringHelpers.GetDeduction(c, answers, progressiveRepeatPenalty));

                    // Cap at MaxDeductionPoints OR subBefore
                    var cap = sub.MaxDeductionPoints ?? subBefore;
                    subDeductions = Math.Min(subDeductions, cap);

                    sectionDeductions += subDeductions;
                }

                if (flatCriteria.Any())
                {
                    var rootFlatBefore = flatCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += rootFlatBefore;

                    var rootFlatDeductions = flatCriteria.Sum(c => ScoringHelpers.GetDeduction(c, answers, progressiveRepeatPenalty));
                    if (section.MaxDeductionPoints.HasValue)
                    {
                        rootFlatDeductions = Math.Min(rootFlatDeductions, section.MaxDeductionPoints.Value);
                    }
                    sectionDeductions += rootFlatDeductions;
                }

                if (sectionBefore == 0) continue;

                // CCP triggered → exclude this section's score (0%), but MUST keep its weight in the denominator!
                // Previously, this used `continue;` which ignored the section entirely, resulting in high overall scores
                // even when a critical failure occurred.
                if (ccpTriggered)
                {
                    sectionResults.Add((0m, section.Weight ?? 0));
                    continue;
                }

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
            return new ScoringVerifier.VerificationResult(
                Math.Abs(clientScore - Math.Round(serverScore, 2)) <= tolerance,
                Math.Round(serverScore, 2),
                null,
                ScoringHelpers.BuildFailedSet(criteria, answers),
                IsWeighted: true);
        }
        else
        {
            // Unweighted penalty falls back to checklist scoring.
            // Intercept result and stamp IsWeighted=false — VerifyChecklist must not be modified.
            var checklistResult = VerifyChecklist(clientScore, answers, criteria, progressiveRepeatPenalty, tolerance);
            return checklistResult with { IsWeighted = false };
        }
    }

    internal static ScoringVerifier.VerificationResult VerifyChecklist(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Criterion> criteria,
        bool progressiveRepeatPenalty,
        decimal tolerance)
    {
        // Mirror of Flutter ScoringEngine._calculateChecklist():
        //   score = max(0, 100 - Σ(faults × pointsWeight))
        // NOT a ratio — raw deductions from 100.
        var ccpTriggered = criteria.Any(c =>
            (answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
            (c.IsCcp && ScoringHelpers.HasFaults(c, answers)));

        var totalDeductions = criteria.Sum(c => ScoringHelpers.GetDeduction(c, answers, progressiveRepeatPenalty));
        var serverScore = Math.Max(0, 100 - totalDeductions);

        if (ccpTriggered)
        {
            serverScore = 0m;
        }

        return new ScoringVerifier.VerificationResult(
            Math.Abs(clientScore - serverScore) <= tolerance,
            Math.Round(serverScore, 2),
            null,
            ScoringHelpers.BuildFailedSet(criteria, answers));
    }

    internal static ScoringVerifier.VerificationResult VerifyAccumulation(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria,
        decimal tolerance)
    {
        var rootGroups = groups.Where(g => g.ParentId == null).ToList();
        decimal totalPossible = 0;
        decimal totalEarned = 0;

        foreach (var section in rootGroups)
        {
            var sectionCriteria = ScoringHelpers.GetCriteriaForGroup(section.Id, groups, criteria);
            var ccpTriggered = sectionCriteria.Any(c =>
                (answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
                (c.IsCcp && ScoringHelpers.HasFaults(c, answers)));

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

                        // Binary: full points if numericValue=0 (no faults), not non_conform, no repeated faults
                        var faults = answer.NumericValue ?? 0;
                        if (faults == 0 && !isNonConform && answer.RepeatedFaults == 0)
                            sectionEarned += c.PointsWeight ?? 0;
                    }
                }
            }

            totalPossible += sectionPossible;
            totalEarned += sectionEarned;
        }

        var serverScore = totalPossible > 0
            ? totalEarned / totalPossible * 100
            : 100m;

        return new ScoringVerifier.VerificationResult(
            Math.Abs(clientScore - Math.Round(serverScore, 2)) <= tolerance,
            Math.Round(serverScore, 2),
            null,
            ScoringHelpers.BuildFailedSet(criteria, answers),
            RawEarned: totalEarned,
            RawMax: totalPossible);
    }
}
