using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// Server-side scoring verifier — C# port of the Unified Penalty-First algorithm.
/// Recalculates the audit score and compares to the client-submitted value.
/// Tolerance: |client - server| must be <= 0.01.
/// </summary>
public sealed class ScoringVerifier
{
    private const decimal Tolerance = 0.01m;

    public sealed record VerificationResult(bool IsValid, decimal ServerScore, string? Reason);

    /// <summary>
    /// Verifies the client-submitted score against a server-side recalculation.
    /// </summary>
    public VerificationResult Verify(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Group> groups,
        IReadOnlyList<Criterion> criteria)
    {
        // Check for RISK — any RISK criteria with faults → total score = 0
        var riskTriggered = criteria
            .Where(c => c.IsRisk)
            .Any(c => HasFaults(c, answers));

        if (riskTriggered)
        {
            var serverScore = 0m;
            return new VerificationResult(
                Math.Abs(clientScore - serverScore) <= Tolerance,
                serverScore,
                riskTriggered ? "RISK criteria triggered — total score forced to 0%" : null);
        }

        // Get root groups (sections) — ParentId == null
        var rootGroups = groups.Where(g => g.ParentId == null).ToList();

        // Check if weighted density is active (all roots have weight > 0 and sum ~100)
        var totalWeight = rootGroups.Sum(g => g.Weight ?? 0);
        var isWeighted = totalWeight > 0;

        if (isWeighted)
        {
            // Weighted penalty mode: sum((sectionAfter / sectionBefore) * sectionWeight)
            var finalScore = 0m;

            foreach (var section in rootGroups)
            {
                var sectionCriteria = GetCriteriaForGroup(section.Id, groups, criteria);
                var ccpTriggered = sectionCriteria.Any(c => c.IsCcp && HasFaults(c, answers));

                if (ccpTriggered)
                {
                    // CCP: section score = 0, contributes 0 to weighted total
                    continue;
                }

                var sectionBefore = sectionCriteria.Sum(c => c.PointsWeight ?? 0);
                if (sectionBefore == 0) continue;

                var sectionDeductions = sectionCriteria.Sum(c => GetDeduction(c, answers));

                // Cap deductions at MaxDeductionPoints if set (per SCORING_LOGIC.md)
                if (section.MaxDeductionPoints.HasValue)
                    sectionDeductions = Math.Min(sectionDeductions, section.MaxDeductionPoints.Value);

                var sectionAfter = Math.Max(0, sectionBefore - sectionDeductions);
                var sectionRatio = sectionAfter / sectionBefore;
                var sectionWeight = (section.Weight ?? 0) / 100m;

                finalScore += sectionRatio * sectionWeight;
            }

            var serverScore = finalScore * 100;
            return new VerificationResult(
                Math.Abs(clientScore - serverScore) <= Tolerance,
                Math.Round(serverScore, 2),
                null);
        }
        else
        {
            // Checklist fallback: max(0, 100 - totalDeductions)
            var totalDeductions = criteria.Sum(c => GetDeduction(c, answers));
            var serverScore = Math.Max(0, 100 - totalDeductions);

            return new VerificationResult(
                Math.Abs(clientScore - serverScore) <= Tolerance,
                Math.Round(serverScore, 2),
                null);
        }
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
        // Numeric faults OR pass/fail non-conformance
        return (answer.NumericValue ?? 0) > 0
            || string.Equals(answer.Value, "non_conform", StringComparison.OrdinalIgnoreCase);
    }

    private static decimal GetDeduction(Criterion criterion, IReadOnlyList<Answer> answers)
    {
        var answer = answers.FirstOrDefault(a => a.CriteriaId == criterion.Id);
        if (answer is null) return 0;
        var faults = answer.NumericValue ?? 0;
        var impact = criterion.PointsWeight ?? 0;
        return faults * impact;
    }
}
