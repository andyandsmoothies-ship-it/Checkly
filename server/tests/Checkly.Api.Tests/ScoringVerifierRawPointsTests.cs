using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringVerifierRawPointsTests
{
    private readonly ScoringVerifier _sut = new();

    private static Group MakeSection(Guid id, decimal? weight = 100, decimal? maxDeduction = null) =>
        new() { Id = id, ParentId = null, Weight = weight, MaxDeductionPoints = maxDeduction };

    private static Criterion MakeCriterion(Guid id, Guid groupId, decimal points, bool isRisk = false, bool isCcp = false) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsRisk = isRisk, IsCcp = isCcp };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue = null, string? value = null, int repeatedFaults = 0) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, Value = value, RepeatedFaults = repeatedFaults };

    // TC-S1-08
    [Fact]
    public void VerifyAccumulation_ReturnsRawFields()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 0) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 15m) };
        var answers = new[] { MakeAnswer(c1, numericValue: 10m, value: "input") };

        dynamic result = _sut.Verify(66.67m, answers, groups, criteria, scoringMode: "accumulation");

        Assert.Equal(10m, result.RawEarned);
        Assert.Equal(15m, result.RawMax);
        Assert.Null(result.IsWeighted);
    }

    // TC-S1-09
    [Fact]
    public void VerifyPenalty_Weighted_RawFieldsNullPlusIsWeightedFlagTrue()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "conform") };

        dynamic result = _sut.Verify(100m, answers, groups, criteria, scoringMode: "penalty");

        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
        Assert.True(result.IsWeighted);
    }

    [Fact]
    public void VerifyPenalty_Unweighted_RawFieldsNullPlusIsWeightedFlagFalse()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 0) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "conform") };

        dynamic result = _sut.Verify(100m, answers, groups, criteria, scoringMode: "penalty");

        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
        Assert.False(result.IsWeighted);
    }

    [Fact]
    public void VerifyChecklist_RawFieldsNull()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 0) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "conform") };

        dynamic result = _sut.Verify(100m, answers, groups, criteria, scoringMode: "checklist");

        Assert.Null(result.RawEarned);
        Assert.Null(result.RawMax);
        Assert.Null(result.IsWeighted);
    }
}
