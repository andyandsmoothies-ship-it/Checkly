using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using System;
using System.Collections.Generic;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringEngineAbstractionTests
{
    private static Group MakeSection(Guid id, decimal? weight = 100, decimal? maxDeduction = null) =>
        new() { Id = id, ParentId = null, Weight = weight, MaxDeductionPoints = maxDeduction };

    private static Criterion MakeCriterion(Guid id, Guid groupId, decimal points,
        bool isRisk = false, bool isCcp = false, decimal? minusImpact = null, decimal? maxDeductionPoints = null) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsRisk = isRisk, IsCcp = isCcp, MinusImpact = minusImpact, MaxDeductionPoints = maxDeductionPoints };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue = null, string? value = null, int repeatedFaults = 0) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, Value = value, RepeatedFaults = repeatedFaults };

    [Fact]
    public void ScoringContext_Initialization_PropertiesAreAssigned()
    {
        // Arrange
        var clientScore = 95m;
        var answers = new List<Answer>();
        var criteria = new List<Criterion>();
        var groups = new List<Group>();
        var progressiveRepeatPenalty = true;
        var isWeighted = false;
        var tolerance = 0.01m;

        // Act
        var context = new ScoringContext(
            clientScore,
            answers,
            criteria,
            groups,
            progressiveRepeatPenalty,
            isWeighted,
            tolerance
        );

        // Assert
        Assert.Equal(clientScore, context.ClientScore);
        Assert.Same(answers, context.Answers);
        Assert.Same(criteria, context.Criteria);
        Assert.Same(groups, context.Groups);
        Assert.Equal(progressiveRepeatPenalty, context.ProgressiveRepeatPenalty);
        Assert.Equal(isWeighted, context.IsWeighted);
        Assert.Equal(tolerance, context.Tolerance);
    }

    [Theory]
    [InlineData("up", true, typeof(AccumulationScoringStrategy))]
    [InlineData("up", false, typeof(AccumulationScoringStrategy))]
    [InlineData("down", true, typeof(PenaltyScoringStrategy))]
    [InlineData("down", false, typeof(ChecklistScoringStrategy))]
    [InlineData("none", false, typeof(ChecklistScoringStrategy))]
    [InlineData("", false, typeof(ChecklistScoringStrategy))]
    [InlineData(null, false, typeof(ChecklistScoringStrategy))]
    public void ScoringEngineFactory_GetStrategy_ResolvesCorrectStrategy(string? scoreDirection, bool isWeighted, Type expectedType)
    {
        // Arrange
        // (Parameters are in the InlineData)

        // Act
        var strategy = ScoringEngineFactory.GetStrategy(scoreDirection, isWeighted);

        // Assert
        Assert.NotNull(strategy);
        Assert.IsType(expectedType, strategy);
    }

    [Fact]
    public void ChecklistScoringStrategy_Verify_CalculatesCorrectScore()
    {
        // Arrange
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: 1, value: "non_conform", repeatedFaults: 0) };

        var context = new ScoringContext(
            95m,
            answers,
            criteria,
            groups,
            progressiveRepeatPenalty: false,
            isWeighted: false,
            tolerance: 0.01m
        );
        var strategy = new ChecklistScoringStrategy();

        // Act
        var result = strategy.Verify(context);

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(95m, result.ServerScore);
        Assert.False(result.IsWeighted);
    }

    [Fact]
    public void PenaltyScoringStrategy_Verify_CalculatesCorrectScore()
    {
        // Arrange
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 100m, minusImpact: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: 1, value: "non_conform", repeatedFaults: 0) };

        var context = new ScoringContext(
            95m,
            answers,
            criteria,
            groups,
            progressiveRepeatPenalty: false,
            isWeighted: true,
            tolerance: 0.01m
        );
        var strategy = new PenaltyScoringStrategy();

        // Act
        var result = strategy.Verify(context);

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(95m, result.ServerScore);
        Assert.True(result.IsWeighted);
    }

    [Fact]
    public void AccumulationScoringStrategy_Verify_CalculatesCorrectScore()
    {
        // Arrange
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: 0, value: "conform", repeatedFaults: 0) };

        var context = new ScoringContext(
            100m,
            answers,
            criteria,
            groups,
            progressiveRepeatPenalty: false,
            isWeighted: true,
            tolerance: 0.01m
        );
        var strategy = new AccumulationScoringStrategy();

        // Act
        var result = strategy.Verify(context);

        // Assert
        Assert.True(result.IsValid);
        Assert.Equal(100m, result.ServerScore);
        Assert.True(result.IsWeighted);
    }
}
