using Checkly.Api.Common.Persistence.Entities;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Checkly.Api.Common.Scoring;

public class PenaltyScoringStrategy : IScoringStrategy
{
    public ScoringVerifier.VerificationResult Verify(ScoringContext context)
    {
        var rootGroups = context.Groups.Where(g => g.ParentId == null).ToList();
        var totalWeight = rootGroups.Sum(g => g.Weight ?? 0);
        var isWeighted = totalWeight > 0;

        if (isWeighted)
        {
            var sectionResults = new List<(decimal ratio, decimal weight)>();

            foreach (var section in rootGroups)
            {
                var flatCriteria = context.Criteria.Where(c => c.GroupId == section.Id).ToList();
                var subsections = context.Groups.Where(g => g.ParentId == section.Id).ToList();

                var allCriteria = new List<Criterion>(flatCriteria);
                foreach (var sub in subsections)
                {
                    allCriteria.AddRange(context.Criteria.Where(c => c.GroupId == sub.Id));
                }

                bool ccpTriggered = allCriteria.Any(c =>
                    (context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
                    (c.IsCcp && ScoringHelpers.HasFaults(c, context.Answers)));

                decimal sectionBefore = 0m;
                decimal sectionDeductions = 0m;

                foreach (var sub in subsections)
                {
                    var subCriteria = context.Criteria.Where(c => c.GroupId == sub.Id).ToList();
                    var subBefore = subCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += subBefore;

                    if (subBefore == 0) continue;

                    var subDeductions = subCriteria.Sum(c => ScoringHelpers.GetDeduction(c, context.Answers, context.ProgressiveRepeatPenalty));

                    // Cap at MaxDeductionPoints OR subBefore
                    var cap = sub.MaxDeductionPoints ?? subBefore;
                    subDeductions = Math.Min(subDeductions, cap);

                    sectionDeductions += subDeductions;
                }

                if (flatCriteria.Any())
                {
                    var rootFlatBefore = flatCriteria.Sum(c => c.PointsWeight ?? 0);
                    sectionBefore += rootFlatBefore;

                    var rootFlatDeductions = flatCriteria.Sum(c => ScoringHelpers.GetDeduction(c, context.Answers, context.ProgressiveRepeatPenalty));
                    if (section.MaxDeductionPoints.HasValue)
                    {
                        rootFlatDeductions = Math.Min(rootFlatDeductions, section.MaxDeductionPoints.Value);
                    }
                    sectionDeductions += rootFlatDeductions;
                }

                if (sectionBefore == 0) continue;

                // CCP triggered → exclude this section's score (0%), but MUST keep its weight in the denominator!
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
                Math.Abs(context.ClientScore - Math.Round(serverScore, 2)) <= context.Tolerance,
                Math.Round(serverScore, 2),
                null,
                ScoringHelpers.BuildFailedSet(context.Criteria, context.Answers),
                IsWeighted: true);
        }
        else
        {
            // Unweighted penalty falls back to checklist scoring.
            var checklistStrategy = new ChecklistScoringStrategy();
            var checklistResult = checklistStrategy.Verify(context);
            return checklistResult with { IsWeighted = false };
        }
    }
}
