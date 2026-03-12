using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;

namespace Checkly.Api.Tests;

/// <summary>
/// Pure unit tests for ScoringVerifier — no DB needed.
/// </summary>
public class ScoringVerifierTests
{
    private readonly ScoringVerifier _sut = new();

    // --- Helper factories ---
    private static Group MakeSection(Guid id, decimal? weight = 100, decimal? maxDeduction = null) =>
        new() { Id = id, ParentId = null, Weight = weight, MaxDeductionPoints = maxDeduction };

    private static Criterion MakeCriterion(Guid id, Guid groupId, decimal points,
        bool isRisk = false, bool isCcp = false) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsRisk = isRisk, IsCcp = isCcp };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue = null, string? value = null) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, Value = value };

    // ====================================================================
    // Gap 1: MaxDeductionPoints cap
    // ====================================================================

    [Fact]
    public void Weighted_Section_Deductions_Are_Capped_At_MaxDeductionPoints()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100, maxDeduction: 5m) };
        var criteria = new[]
        {
            MakeCriterion(c1, sectionId, points: 3m),
            MakeCriterion(c2, sectionId, points: 4m),
        };
        // Both criteria have 1 fault each → raw deduction = 3 + 4 = 7
        // But MaxDeductionPoints = 5, so capped at 5
        // Section: before=7, after=max(0, 7-5)=2, ratio=2/7
        // Score = (2/7) * 100 = 28.57
        var answers = new[]
        {
            MakeAnswer(c1, numericValue: 1),
            MakeAnswer(c2, numericValue: 1),
        };

        var result = _sut.Verify(28.57m, answers, groups, criteria);
        Assert.True(result.IsValid, $"Expected ~28.57 but got {result.ServerScore}");
    }

    [Fact]
    public void Without_MaxDeductionPoints_Full_Deduction_Applied()
    {
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100, maxDeduction: null) };
        var criteria = new[]
        {
            MakeCriterion(c1, sectionId, points: 3m),
            MakeCriterion(c2, sectionId, points: 4m),
        };
        // No cap → deduction = 7, before = 7, after = 0, score = 0
        var answers = new[]
        {
            MakeAnswer(c1, numericValue: 1),
            MakeAnswer(c2, numericValue: 1),
        };

        var result = _sut.Verify(0m, answers, groups, criteria);
        Assert.True(result.IsValid, $"Expected 0 but got {result.ServerScore}");
    }

    // ====================================================================
    // Gap 2: Pass/Fail non_conform detection
    // ====================================================================

    [Fact]
    public void Risk_Criterion_With_NonConform_Value_Triggers_Zero_Score()
    {
        var sectionId = Guid.NewGuid();
        var riskId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId) };
        var criteria = new[] { MakeCriterion(riskId, sectionId, points: 10m, isRisk: true) };
        // Pass/fail: no numeric value, but value="non_conform"
        var answers = new[] { MakeAnswer(riskId, numericValue: null, value: "non_conform") };

        var result = _sut.Verify(0m, answers, groups, criteria);
        Assert.True(result.IsValid, $"RISK non_conform should force score to 0, got {result.ServerScore}");
        Assert.Equal(0m, result.ServerScore);
    }

    [Fact]
    public void Ccp_Criterion_With_NonConform_Value_Zeros_Section()
    {
        var sectionId = Guid.NewGuid();
        var ccpId = Guid.NewGuid();
        var normalId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[]
        {
            MakeCriterion(ccpId, sectionId, points: 5m, isCcp: true),
            MakeCriterion(normalId, sectionId, points: 10m),
        };
        // CCP has non_conform → section score = 0, normal criterion is irrelevant
        var answers = new[]
        {
            MakeAnswer(ccpId, numericValue: null, value: "non_conform"),
            MakeAnswer(normalId, numericValue: 0),
        };

        var result = _sut.Verify(0m, answers, groups, criteria);
        Assert.True(result.IsValid, $"CCP non_conform should zero section, got {result.ServerScore}");
        Assert.Equal(0m, result.ServerScore);
    }

    [Fact]
    public void Conform_Value_Does_Not_Trigger_Faults()
    {
        var sectionId = Guid.NewGuid();
        var riskId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId) };
        var criteria = new[] { MakeCriterion(riskId, sectionId, points: 10m, isRisk: true) };
        // Pass/fail: value="conform" → no fault
        var answers = new[] { MakeAnswer(riskId, numericValue: null, value: "conform") };

        var result = _sut.Verify(100m, answers, groups, criteria);
        Assert.True(result.IsValid, $"conform should not trigger RISK, got {result.ServerScore}");
        Assert.Equal(100m, result.ServerScore);
    }

    // ====================================================================
    // C3: Progressive Repeat Penalty
    // Source: SCORING_LOGIC.md §2.A L17-19
    // "When enabled, repeated faults use quadratic escalation"
    // ====================================================================

    [Fact]
    public void C3_Progressive_Repeat_OFF_Uses_Linear_Deduction()
    {
        // When progressive_repeat_penalty = false, repeatedFaults are ignored.
        // Regular deduction: numericValue=3, pointsWeight=2 → 3 × 2 = 6
        // sectionBefore = 10 → ratio = (10-6)/10 = 0.40 → 40.00%
        var sectionId = Guid.NewGuid();
        var cId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[] { MakeCriterion(cId, sectionId, points: 2m) };
        // Add a second criterion to make sectionBefore = 10
        var c2 = Guid.NewGuid();
        var allCriteria = new[]
        {
            MakeCriterion(cId, sectionId, points: 2m),
            MakeCriterion(c2, sectionId, points: 8m),
        };
        var answers = new[] { MakeAnswer(cId, numericValue: 3) };

        var result = _sut.Verify(40.00m, answers, groups, allCriteria);
        Assert.True(result.IsValid, $"Linear deduction: expected 40.00 but got {result.ServerScore}");
    }

    [Fact]
    public void C3_Progressive_Repeat_ON_Uses_Quadratic_Deduction()
    {
        // When progressive_repeat_penalty = true:
        // base = numericValue × pointsWeight = 1 × 2 = 2
        // repeat = repeatedFaults² × pointsWeight = 2² × 2 = 8
        // total deduction = 2 + 8 = 10
        // sectionBefore = 10 → ratio = 0/10 = 0.00 → 0.00%
        var sectionId = Guid.NewGuid();
        var cId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var allCriteria = new[]
        {
            MakeCriterion(cId, sectionId, points: 2m),
            MakeCriterion(Guid.NewGuid(), sectionId, points: 8m),
        };
        var answers = new[] { new Answer
        {
            Id = Guid.NewGuid(),
            CriteriaId = cId,
            NumericValue = 1,
            RepeatedFaults = 2,
        }};

        var result = _sut.Verify(0.00m, answers, groups, allCriteria, progressiveRepeatPenalty: true);
        Assert.True(result.IsValid, $"C3 ON: expected 0.00 but got {result.ServerScore}");
    }

    [Fact]
    public void C3_Progressive_Repeat_Capped_At_MaxDeduction()
    {
        // progressive_repeat_penalty = true, maxDeductionPoints = 5
        // base = 1×2 = 2, repeat = 3²×2 = 18, raw total = 20, capped at 5
        // sectionBefore = 10 → (10-5)/10 = 0.50 → 50.00%
        var sectionId = Guid.NewGuid();
        var cId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100, maxDeduction: 5m) };
        var allCriteria = new[]
        {
            MakeCriterion(cId, sectionId, points: 2m),
            MakeCriterion(Guid.NewGuid(), sectionId, points: 8m),
        };
        var answers = new[] { new Answer
        {
            Id = Guid.NewGuid(),
            CriteriaId = cId,
            NumericValue = 1,
            RepeatedFaults = 3,
        }};

        var result = _sut.Verify(50.00m, answers, groups, allCriteria, progressiveRepeatPenalty: true);
        Assert.True(result.IsValid, $"C3 capped: expected 50.00 but got {result.ServerScore}");
    }

    // ====================================================================
    // C4: Minus Impact Override
    // Source: SCORING_LOGIC.md §2.A L20
    // "Per-criteria minus_impact overrides Minus Per Fault"
    // ====================================================================

    [Fact]
    public void C4_Criterion_With_MinusImpact_Overrides_PointsWeight()
    {
        // Criterion A: pointsWeight=5, minus_impact=1
        // Answer: numericValue=3
        // Deduction = 3 × 1 = 3 (NOT 3 × 5 = 15)
        // sectionBefore = 10 → ratio = (10-3)/10 = 0.70 → 70.00%
        var sectionId = Guid.NewGuid();
        var cId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var crit = MakeCriterion(cId, sectionId, points: 5m);
        crit.MinusImpact = 1m; // C4: override
        var allCriteria = new[]
        {
            crit,
            MakeCriterion(Guid.NewGuid(), sectionId, points: 5m),
        };
        var answers = new[] { MakeAnswer(cId, numericValue: 3) };

        var result = _sut.Verify(70.00m, answers, groups, allCriteria);
        Assert.True(result.IsValid, $"C4 with minusImpact=1: expected 70.00 but got {result.ServerScore}");
    }

    [Fact]
    public void C4_No_MinusImpact_Falls_Back_To_PointsWeight()
    {
        // Criteria with no minus_impact → use pointsWeight for deduction.
        // 1 fault × 5 points = 5 deduction → (5-5)/5 = 0.00 → 0%
        var sectionId = Guid.NewGuid();
        var cId = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var allCriteria = new[] { MakeCriterion(cId, sectionId, points: 5m) };
        var answers = new[] { MakeAnswer(cId, numericValue: 1) };

        var result = _sut.Verify(0.00m, answers, groups, allCriteria);
        Assert.True(result.IsValid, $"C4 fallback: expected 0.00 but got {result.ServerScore}");
    }
}
