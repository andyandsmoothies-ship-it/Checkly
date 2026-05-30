using System;
using System.Collections.Generic;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// Unit tests for the new C# Weighted Accumulation scoring logic (VerifyAccumulationWeighted).
/// Follows Detroit Classical TDD patterns testing public API boundaries.
/// Implements TC-01 through TC-07.
/// </summary>
public class WeightedAccumulationVerifierTests
{
    private readonly ScoringVerifier _verifier = new();

    private static Group MakeSection(Guid id, decimal? weight) =>
        new() { Id = id, ParentId = null, Weight = weight };

    private static Criterion MakeCriterion(Guid id, Guid groupId, decimal points, bool isCcp = false) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsCcp = isCcp, InputType = "scale" };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue, bool isCcp = false) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, IsCcp = isCcp };

    [Fact]
    public void TC01_HappyPath_TwoSections_CalculatesCorrectWeightedScore()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 60),
            MakeSection(secBId, weight: 40)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8), // 8/10 points earned
            MakeAnswer(critBId, numericValue: 5)  // 5/10 points earned
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 68.0m,
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(68.0m, result.ServerScore);
        Assert.True(result.IsWeighted);
    }

    [Fact]
    public void TC02_CcpTriggered_ZerosSectionEarnedButDenominatorRetained()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 60),
            MakeSection(secBId, weight: 40)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10, isCcp: true),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8, isCcp: true), // CCP Fault triggered
            MakeAnswer(critBId, numericValue: 5)
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 20.0m,
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(20.0m, result.ServerScore);
        Assert.True(result.IsWeighted);
    }

    [Fact]
    public void TC03_PerfectScore_Returns100Percent()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 70),
            MakeSection(secBId, weight: 30)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 10), // Perfect score
            MakeAnswer(critBId, numericValue: 10)  // Perfect score
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 100.0m,
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(100.0m, result.ServerScore);
        Assert.True(result.IsWeighted);
    }

    [Fact]
    public void TC05_Regression_UnweightedAccumulationUnchanged()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 60),
            MakeSection(secBId, weight: 40)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8),
            MakeAnswer(critBId, numericValue: 5)
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 65.0m, // Unweighted flat score: 13 / 20 * 100 = 65%
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: false // Flat unweighted scoring
        );

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(65.0m, result.ServerScore);
        Assert.Null(result.IsWeighted); // Unweighted returns null for IsWeighted
        Assert.Equal(13m, result.RawEarned);
        Assert.Equal(20m, result.RawMax);
    }

    [Fact]
    public void TC05b_ZeroWeightsFallback_CalculatesUnweightedScore()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: null), // Null weight
            MakeSection(secBId, weight: 0)     // Zero weight
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8),
            MakeAnswer(critBId, numericValue: 5)
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 65.0m, // Falls back to unweighted flat scoring: 13 / 20 * 100 = 65%
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(65.0m, result.ServerScore);
        Assert.False(result.IsWeighted); // Fallback stamps false
    }

    [Fact]
    public void TC06_ToleranceBoundary_ClientWithinLimit_IsValid()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 60),
            MakeSection(secBId, weight: 40)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8),
            MakeAnswer(critBId, numericValue: 5)
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 68.005m, // Within ±0.01 of 68.0m
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.True(result.IsValid);
    }

    [Fact]
    public void TC07_ToleranceBoundary_ClientExceedsLimit_IsInvalid()
    {
        // Arrange
        var secAId = Guid.NewGuid();
        var secBId = Guid.NewGuid();
        var critAId = Guid.NewGuid();
        var critBId = Guid.NewGuid();

        var groups = new[]
        {
            MakeSection(secAId, weight: 60),
            MakeSection(secBId, weight: 40)
        };

        var criteria = new[]
        {
            MakeCriterion(critAId, secAId, points: 10),
            MakeCriterion(critBId, secBId, points: 10)
        };

        var answers = new[]
        {
            MakeAnswer(critAId, numericValue: 8),
            MakeAnswer(critBId, numericValue: 5)
        };

        // Act
        var result = _verifier.Verify(
            clientScore: 68.02m, // Exceeds ±0.01 of 68.0m
            answers: answers,
            groups: groups,
            criteria: criteria,
            progressiveRepeatPenalty: false,
            scoreDirection: "up",
            isWeighted: true
        );

        // Assert
        Assert.False(result.IsValid);
        Assert.Equal(68.0m, result.ServerScore);
    }
}
