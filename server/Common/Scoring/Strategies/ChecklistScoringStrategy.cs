using Checkly.Api.Common.Persistence.Entities;
using System;
using System.Collections.Generic;
using System.Linq;

namespace Checkly.Api.Common.Scoring;

public class ChecklistScoringStrategy : IScoringStrategy
{
    public ScoringVerifier.VerificationResult Verify(ScoringContext context)
    {
        var ccpTriggered = context.Criteria.Any(c =>
            (context.Answers.FirstOrDefault(a => a.CriteriaId == c.Id)?.IsCcp == true) ||
            (c.IsCcp && ScoringHelpers.HasFaults(c, context.Answers)));

        var totalDeductions = context.Criteria.Sum(c => ScoringHelpers.GetDeduction(c, context.Answers, context.ProgressiveRepeatPenalty));
        var serverScore = Math.Max(0, 100 - totalDeductions);

        if (ccpTriggered)
        {
            serverScore = 0m;
        }

        return new ScoringVerifier.VerificationResult(
            Math.Abs(context.ClientScore - serverScore) <= context.Tolerance,
            Math.Round(serverScore, 2),
            null,
            ScoringHelpers.BuildFailedSet(context.Criteria, context.Answers),
            IsWeighted: false);
    }
}
