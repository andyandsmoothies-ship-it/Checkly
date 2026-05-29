using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Common.Scoring;

/// <summary>
/// SC-5: Extracted from ScoringVerifier.cs — pure math helpers.
/// Contains the answer-level analysis functions shared by all scoring modes.
/// These are internal implementation details; callers use ScoringVerifier.Verify().
/// </summary>
internal static class ScoringHelpers
{
    /// <summary>
    /// Input types that can carry scoring points (measurable).
    /// Metadata types (text, signature, photo, header, date, image) are transparent to purity.
    /// Mirror of Flutter's ScoringEngine._kMeasurableTypes.
    /// </summary>
    internal static readonly HashSet<string> MeasurableTypes =
        new(StringComparer.OrdinalIgnoreCase)
        { "pass_fail", "numeric", "scale", "single_choice", "multi_choice" };

    /// <summary>
    /// Returns true if every measurable criterion has a points weight > 0.
    /// One zero-weight measurable criterion anywhere = MIXED = null score.
    /// Mirror of Flutter's ScoringEngine._isPureAudit().
    /// </summary>
    internal static bool IsPureAudit(IReadOnlyList<Criterion> criteria)
    {
        return criteria
            .Where(c => MeasurableTypes.Contains(c.InputType ?? string.Empty))
            .All(c => (c.PointsWeight ?? 0) > 0);
    }

    /// <summary>
    /// Builds the set of criteria IDs that semantically failed.
    /// Excludes unscored input types (text, single_choice, multi_choice) — Gotcha #11.
    /// </summary>
    internal static HashSet<Guid> BuildFailedSet(
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
    internal static List<Criterion> GetCriteriaForGroup(
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

    internal static bool HasFaults(Criterion criterion, IReadOnlyList<Answer> answers)
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
        // All other widgets (including numeric, single_choice, etc):
        // Flutter sends the explicit fault count in NumericValue.
        return (answer.NumericValue ?? 0) > 0;
    }

    internal static decimal GetDeduction(Criterion criterion, IReadOnlyList<Answer> answers, bool progressiveRepeatPenalty = false)
    {
        var answer = answers.FirstOrDefault(a => a.CriteriaId == criterion.Id || (criterion.Id == Guid.Empty && (a.CriteriaId == null || a.CriteriaId == Guid.Empty)));
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

        decimal rawDeduction;
        // C3: progressive repeat penalty (n² × impact)
        if (progressiveRepeatPenalty && answer.RepeatedFaults > 0)
        {
            var repeatDeduction = (decimal)answer.RepeatedFaults * (decimal)answer.RepeatedFaults * impact;
            rawDeduction = baseDeduction + repeatDeduction;
        }
        // Linear repeat penalty (n × impact) — applied even when progressive is OFF
        else if (answer.RepeatedFaults > 0)
        {
            rawDeduction = baseDeduction + (answer.RepeatedFaults * impact);
        }
        else
        {
            rawDeduction = baseDeduction;
        }

        // Phase 1A: per-criterion MaxDeductionPoints cap (TC-2).
        // Null = no cap → backward compatible with all existing templates.
        if (criterion.MaxDeductionPoints.HasValue)
            rawDeduction = Math.Min(rawDeduction, criterion.MaxDeductionPoints.Value);

        return rawDeduction;
    }
}
