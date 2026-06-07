using Checkly.Api.Common.Persistence.Entities;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Checkly.Api.Common.Scoring;

public class AccumulationScoringStrategy : IScoringStrategy
{
    public ScoringVerifier.VerificationResult Verify(ScoringContext context)
    {
        var rootGroups = context.Groups.Where(g => g.ParentId == null).ToList();
        var totalWeight = rootGroups.Sum(g => g.Weight ?? 0m);
        var isWeightedReal = context.IsWeighted && totalWeight > 0;

        if (isWeightedReal)
        {
            var sectionResults = new List<(decimal ratio, decimal weight)>();

            foreach (var section in rootGroups)
            {
                var sectionCriteria = ScoringHelpers.GetCriteriaForGroup(section.Id, context.Groups, context.Criteria);
                var sectionPossible = sectionCriteria.Sum(c => c.PointsWeight ?? 0m);
                if (sectionPossible == 0) continue;

                var ccpTriggered = sectionCriteria.Any(c =>
                    (context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
                    (c.IsCcp && ScoringHelpers.HasFaults(c, context.Answers)));

                var sectionEarned = 0m;
                if (!ccpTriggered)
                {
                    foreach (var c in sectionCriteria)
                    {
                        var answer = context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id);
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

                var sectionRatio = ccpTriggered ? 0m : sectionEarned / sectionPossible;
                sectionResults.Add((sectionRatio, section.Weight ?? 0m));
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
                Math.Abs(context.ClientScore - Math.Round(serverScore, 2)) <= context.Tolerance,
                Math.Round(serverScore, 2),
                null,
                ScoringHelpers.BuildFailedSet(context.Criteria, context.Answers),
                RawEarned: null,
                RawMax: null,
                IsWeighted: true);
        }
        else
        {
            decimal totalPossible = 0;
            decimal totalEarned = 0;

            foreach (var section in rootGroups)
            {
                var sectionCriteria = ScoringHelpers.GetCriteriaForGroup(section.Id, context.Groups, context.Criteria);
                var ccpTriggered = sectionCriteria.Any(c =>
                    (context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
                    (c.IsCcp && ScoringHelpers.HasFaults(c, context.Answers)));

                var sectionPossible = sectionCriteria.Sum(c => c.PointsWeight ?? 0);
                var sectionEarned = 0m;

                if (!ccpTriggered)
                {
                    foreach (var c in sectionCriteria)
                    {
                        var answer = context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id);
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
                Math.Abs(context.ClientScore - Math.Round(serverScore, 2)) <= context.Tolerance,
                Math.Round(serverScore, 2),
                null,
                ScoringHelpers.BuildFailedSet(context.Criteria, context.Answers),
                RawEarned: totalEarned,
                RawMax: totalPossible,
                IsWeighted: context.IsWeighted ? false : null);
        }
    }
}
