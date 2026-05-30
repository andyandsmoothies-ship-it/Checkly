using System;
using System.Collections.Generic;
using System.Linq;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringVerifierDispatchTests
{
    private readonly ScoringVerifier _verifier = new();
    private readonly List<Answer> _emptyAnswers = new();
    private readonly List<Group> _emptyGroups = new();
    private readonly List<Criterion> _emptyCriteria = new();

    [Fact]
    public void Verify_With_Down_And_Weighted_True_Dispatches_To_VerifyPenalty()
    {
        // For VerifyPenalty to consider itself weighted, we need at least one root group with weight > 0
        var groupId = Guid.NewGuid();
        var groups = new List<Group>
        {
            new() { Id = groupId, ParentId = null, Weight = 10 }
        };
        var criteria = new List<Criterion>
        {
            new() { Id = Guid.NewGuid(), GroupId = groupId, PointsWeight = 10 }
        };

        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "down",
            isWeighted: true
        );

        // VerifyPenalty returns a result with IsWeighted = true
        Assert.True(result.IsWeighted);
        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
    }

    [Fact]
    public void Verify_With_Down_And_Weighted_False_Dispatches_To_VerifyChecklist()
    {
        var groupId = Guid.NewGuid();
        var groups = new List<Group>
        {
            new() { Id = groupId, ParentId = null, Weight = 10 }
        };
        var criteria = new List<Criterion>
        {
            new() { Id = Guid.NewGuid(), GroupId = groupId, PointsWeight = 10 }
        };

        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "down",
            isWeighted: false
        );

        // VerifyChecklist result (or penalty fallback) has IsWeighted = false
        Assert.False(result.IsWeighted);
        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
    }

    [Fact]
    public void Verify_With_Up_Dispatches_To_VerifyAccumulation()
    {
        var groupId = Guid.NewGuid();
        var groups = new List<Group>
        {
            new() { Id = groupId, ParentId = null }
        };
        var criteria = new List<Criterion>
        {
            new() { Id = Guid.NewGuid(), GroupId = groupId, PointsWeight = 10 }
        };

        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: false
        );

        // VerifyAccumulation returns RawEarned and RawMax properties
        Assert.NotNull(result.RawEarned);
        Assert.NotNull(result.RawMax);
        Assert.Null(result.IsWeighted);
    }

    [Fact]
    public void Verify_With_None_Returns_Survey_Null_Score()
    {
        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: _emptyGroups,
            criteria: _emptyCriteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "none",
            isWeighted: false
        );

        Assert.True(result.IsValid);
        Assert.Null(result.ServerScore);
        Assert.Equal("Survey mode — no scoring", result.Reason);
    }

    [Fact]
    public void Verify_With_Invalid_Direction_Falls_Back_To_Down_And_Weighted_False()
    {
        // Gap Analysis AC 1: Invalid direction should default to down + unweighted (Checklist fallback)
        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: _emptyGroups,
            criteria: _emptyCriteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "invalid-direction-xyz",
            isWeighted: true // Even if true, default direction with empty groups defaults to unweighted checklist
        );

        Assert.False(result.IsWeighted);
        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
    }

    [Fact]
    public void Verify_With_Up_And_Weighted_True_Dispatches_To_VerifyAccumulationWeighted()
    {
        // Arrange
        var groupId = Guid.NewGuid();
        var groups = new List<Group>
        {
            new() { Id = groupId, ParentId = null, Weight = 10 }
        };
        var criteria = new List<Criterion>
        {
            new() { Id = Guid.NewGuid(), GroupId = groupId, PointsWeight = 10 }
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 100m,
            answers: _emptyAnswers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsWeighted);
        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
    }
}
