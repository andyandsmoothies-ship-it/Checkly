using System;

namespace Checkly.Api.Common.Scoring;

public static class ScoringEngineFactory
{
    public static IScoringStrategy GetStrategy(string? scoreDirection, bool isWeighted)
    {
        if (string.Equals(scoreDirection, "up", StringComparison.OrdinalIgnoreCase))
        {
            return new AccumulationScoringStrategy();
        }
        else if (string.Equals(scoreDirection, "down", StringComparison.OrdinalIgnoreCase) && isWeighted)
        {
            return new PenaltyScoringStrategy();
        }
        else
        {
            return new ChecklistScoringStrategy();
        }
    }
}
