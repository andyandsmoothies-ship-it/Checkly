using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;

namespace Checkly.Api.Tests;

/// <summary>
/// Pure unit tests for ScoringVerifier — no DB needed.
/// Note: Most tests have been migrated to JSON parity tests (ScoringVerifierJsonTests.cs).
/// The tests remaining here are ONLY those that assert FailedCriteriaIds, which require in-memory Guid matching.
/// </summary>
public class ScoringVerifierTests
{
    private readonly ScoringVerifier _sut = new();

    // --- Helper factories ---
    private static Group MakeSection(Guid id, decimal? weight = 100, decimal? maxDeduction = null) =>
        new() { Id = id, ParentId = null, Weight = weight, MaxDeductionPoints = maxDeduction };

    private static Criterion MakeCriterion(Guid id, Guid groupId, decimal points,
        bool isRisk = false, bool isCcp = false, decimal? minusImpact = null, decimal? maxDeductionPoints = null) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsRisk = isRisk, IsCcp = isCcp, MinusImpact = minusImpact, MaxDeductionPoints = maxDeductionPoints };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue = null, string? value = null, int repeatedFaults = 0) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, Value = value, RepeatedFaults = repeatedFaults };

    // ====================================================================
    // ATDD SC-A1: FailedCriteriaIds populated for faulted criteria only
    // ====================================================================

    [Fact]
    public void Verify_Populates_FailedCriteriaIds_Only_For_Faults()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();
        var c3 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[]
        {
            MakeCriterion(c1, sectionId, points: 5m),
            MakeCriterion(c2, sectionId, points: 5m),
            MakeCriterion(c3, sectionId, points: 5m)
        };

        var answers = new[]
        {
            MakeAnswer(c1, numericValue: null, value: "non_conform"), // Fault
            MakeAnswer(c2, numericValue: null, value: "conform"),     // No fault
            MakeAnswer(c3, numericValue: 1, value: null)              // Fault (numeric > 0)
        };

        // Act
        var result = _sut.Verify(100m, answers, groups, criteria);

        Assert.Contains(c1, result.FailedCriteriaIds);
        Assert.Contains(c3, result.FailedCriteriaIds);
        Assert.DoesNotContain(c2, result.FailedCriteriaIds);
    }

    // ====================================================================
    // ATDD: Global Risk Forces Score to Zero
    // ====================================================================

    [Fact]
    public void Verify_With_HasGlobalRisk_True_Forces_ServerScore_To_Zero()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };

        // Perfect score natively
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "conform") };

        // Act
        var result = _sut.Verify(0m, answers, groups, criteria, hasGlobalRisk: true);

        Assert.True(result.IsValid); // Client sent 0m, server calculated 0m
        Assert.Equal(0m, result.ServerScore);
        Assert.Contains("forced to 0%", result.Reason);
    }

    // ====================================================================
    // ATDD SC-A2: Survey mode produces empty FailedCriteriaIds
    // ====================================================================

    [Fact]
    public void Survey_Mode_Returns_Empty_FailedCriteriaIds()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 5m) };

        // Even with a fault answer, survey mode should bypass scoring
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "non_conform") };

        // Act
        var result = _sut.Verify(0m, answers, groups, criteria, scoringMode: "survey");

        Assert.Empty(result.FailedCriteriaIds);
    }

    // ====================================================================
    // ATDD SC-A3: Unscored input types are never in FailedCriteriaIds
    // ====================================================================

    [Theory]
    [InlineData("single_choice")]
    [InlineData("multi_choice")]
    [InlineData("text")]
    public void Unscored_Inputs_Are_Excluded_From_FailedCriteriaIds(string inputType)
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };

        // Data-collection inputs typically have null pointsWeight
        var crit = MakeCriterion(c1, sectionId, points: 0m);
        crit.InputType = inputType;
        crit.PointsWeight = null;
        var criteria = new[] { crit };

        // Some answer value
        var answers = new[] { MakeAnswer(c1, numericValue: null, value: "Option A") };

        // Act
        var result = _sut.Verify(100m, answers, groups, criteria);

        Assert.DoesNotContain(c1, result.FailedCriteriaIds);
    }

    // ====================================================================
    // Scoring Logic Parity Tests (Slice 1 - Early Return Fix)
    // ====================================================================

    [Fact]
    public void NonConform_With_RepeatedFaults_Applies_Linear_Penalty()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 1m) };

        // Flutter sends numericValue = 1 for non_conform answers
        var answers = new[] { MakeAnswer(c1, numericValue: 1, value: "non_conform", repeatedFaults: 2) };

        // Act - checklist mode score = 100 - deductions
        // Expected deduction: 1 (base impact) + (2 * 1) (linear penalty) = 3
        // Expected Score: 100 - 3 = 97
        var result = _sut.Verify(97m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: false);

        Assert.Equal(97m, result.ServerScore);
    }

    [Fact]
    public void NonConform_With_ProgressiveRepeat_Applies_Quadratic_Penalty()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 1m) };

        // Flutter sends numericValue = 1 for non_conform answers
        var answers = new[] { MakeAnswer(c1, numericValue: 1, value: "non_conform", repeatedFaults: 2) };

        // Act - checklist mode score = 100 - deductions
        // Expected deduction: 1 (base impact) + (2^2 * 1) (quadratic penalty) = 5
        // Expected Score: 100 - 5 = 95
        var result = _sut.Verify(95m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: true);

        Assert.Equal(95m, result.ServerScore);
    }

    [Fact]
    public void NonConform_Without_RepeatedFaults_Returns_Impact_Only()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 1m) };

        var answers = new[] { MakeAnswer(c1, numericValue: 1, value: "non_conform", repeatedFaults: 0) };

        // Act - checklist mode score = 100 - deductions
        // Expected deduction: 1
        // Expected Score: 100 - 1 = 99
        var result = _sut.Verify(99m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: false);

        Assert.Equal(99m, result.ServerScore);
    }
    // ====================================================================
    // Phase 1A: Visual Folders Math (TC-1, TC-2, TC-3)
    // ====================================================================

    [Fact]
    public void TC1_Should_Calculate_Deduction_Using_MinusImpact_When_Set()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };

        // Setup: PointsWeight = 1, but MinusImpact = 5.
        // The deduction per fault should be 5, not 1.
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 1m, minusImpact: 5m) };

        // 2 faults
        var answers = new[] { MakeAnswer(c1, numericValue: 2, value: null) };

        // Act
        // 2 faults * 5 impact = 10 deduction. Score = 100 - 10 = 90.
        var result = _sut.Verify(90m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: false);

        Assert.Equal(90m, result.ServerScore);
    }

    [Fact]
    public void TC2_Should_Cap_Individual_Criterion_Deduction_At_MaxDeductionPoints()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };

        // Setup: MinusImpact = 5, but MaxDeductionPoints = 8.
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 1m, minusImpact: 5m, maxDeductionPoints: 8m) };

        // 2 faults
        var answers = new[] { MakeAnswer(c1, numericValue: 2, value: null) };

        // Act
        // 2 faults * 5 impact = 10 deduction.
        // Cap is 8. So deduction is 8. Score = 100 - 8 = 92.
        var result = _sut.Verify(92m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: false);

        Assert.Equal(92m, result.ServerScore);
    }

    [Fact]
    public void TC3_Should_Fallback_To_PointsWeight_When_MinusImpact_Is_Null()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var groups = new[] { MakeSection(sectionId, weight: 100) };

        // Setup: PointsWeight = 3, MinusImpact = null.
        var criteria = new[] { MakeCriterion(c1, sectionId, points: 3m, minusImpact: null) };

        // 2 faults
        var answers = new[] { MakeAnswer(c1, numericValue: 2, value: null) };

        // Act
        // 2 faults * 3 impact (fallback) = 6 deduction. Score = 100 - 6 = 94.
        var result = _sut.Verify(94m, answers, groups, criteria, scoringMode: "checklist", progressiveRepeatPenalty: false);

        Assert.Equal(94m, result.ServerScore);
    }
}
