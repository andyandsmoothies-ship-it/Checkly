using System;
using System.Collections.Generic;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringScratchTest
{
    [Fact]
    public void TestCCPMath()
    {
        var criteria = new List<Criterion>
        {
            new Criterion { Id = Guid.NewGuid(), GroupId = Guid.NewGuid(), InputType = "single_choice", PointsWeight = 10, IsCcp = true }
        };

        var groups = new List<Group>
        {
            new Group { Id = criteria[0].GroupId, Weight = 100 }
        };

        var answers = new List<Answer>
        {
            new Answer { CriteriaId = criteria[0].Id, Value = "Choice A", NumericValue = 1 }
        };

        var verifier = new ScoringVerifier();
        var result = verifier.Verify(0m, answers, groups, criteria);

        Assert.Equal(0m, result.ServerScore);
    }
}
