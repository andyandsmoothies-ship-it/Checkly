using Checkly.Api.Common.Persistence.Entities;
using System.Collections.Generic;

namespace Checkly.Api.Common.Scoring;

public record ScoringContext
{
    public decimal ClientScore { get; init; }
    public IReadOnlyList<Answer> Answers { get; init; }
    public IReadOnlyList<Criterion> Criteria { get; init; }
    public IReadOnlyList<Group> Groups { get; init; }
    public bool ProgressiveRepeatPenalty { get; init; }
    public bool IsWeighted { get; init; }
    public decimal Tolerance { get; init; }

    public ScoringContext(
        decimal clientScore,
        IReadOnlyList<Answer> answers,
        IReadOnlyList<Criterion> criteria,
        IReadOnlyList<Group> groups,
        bool progressiveRepeatPenalty,
        bool isWeighted,
        decimal tolerance)
    {
        ClientScore = clientScore;
        Answers = answers;
        Criteria = criteria;
        Groups = groups;
        ProgressiveRepeatPenalty = progressiveRepeatPenalty;
        IsWeighted = isWeighted;
        Tolerance = tolerance;
    }
}

public interface IScoringStrategy
{
    ScoringVerifier.VerificationResult Verify(ScoringContext context);
}
