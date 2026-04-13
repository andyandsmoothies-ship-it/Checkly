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

    /// <summary>
    /// Gotcha 18 regression — CCP weight normalization parity between C# and Flutter.
    /// Template: 2 sections, weights [60, 40]. CCP on section-1 triggered.
    /// Flutter: participatingWeight=40 → score=(ratio2 × 40/40)×100 = sectionRatio2 × 100
    /// Old C#:  totalWeight=100 → score=(ratio2 × 40/100)×100 = sectionRatio2 × 40  ← WRONG
    /// New C#:  participatingWeight=40 → score=(ratio2 × 40/40)×100 = sectionRatio2 × 100 ✅
    ///
    /// With section-2 all-pass: ratio2=1.0 → expected score = 100.
    /// This test would have FAILED against the old C# engine (returned 40).
    /// </summary>
    [Fact]
    public void Ccp_TriggeredSection_ExcludedFromWeightDenominator_MatchesFlutter()
    {
        var section1Id = Guid.NewGuid();
        var section2Id = Guid.NewGuid();
        var ccpId     = Guid.NewGuid();
        var normalId  = Guid.NewGuid();

        // Two root sections: weights 60 and 40
        var groups = new[]
        {
            MakeSection(section1Id, weight: 60),
            MakeSection(section2Id, weight: 40),
        };

        var criteria = new[]
        {
            MakeCriterion(ccpId,    section1Id, points: 5m, isCcp: true),
            MakeCriterion(normalId, section2Id, points: 10m),
        };

        // Section-1 CCP triggered → excluded. Section-2 all-pass.
        // participatingWeight = 40 → score = (10/10) × (40/40) × 100 = 100
        var answers = new[]
        {
            MakeAnswer(ccpId,    numericValue: null, value: "non_conform"),
            MakeAnswer(normalId, numericValue: 0),
        };

        var result = _sut.Verify(100m, answers, groups, criteria);
        Assert.True(result.IsValid,
            $"Gotcha 18 CCP normalization: expected 100 (Flutter parity) but server gave {result.ServerScore}");
        Assert.Equal(100m, result.ServerScore);
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

    // ====================================================================
    // C3 RED: Linear repeat penalty when progressive is OFF — MISSING FIX
    // ====================================================================

    [Fact]
    public void C3_Linear_Repeat_Penalty_Applied_When_Progressive_OFF_And_RepeatedFaults_GT_Zero()
    {
        // When progressive_repeat_penalty = false but RepeatedFaults > 0:
        // base = numericValue × pointsWeight = 1 × 2 = 2
        // linear repeat = repeatedFaults × pointsWeight = 2 × 2 = 4
        // total deduction = 2 + 4 = 6
        // sectionBefore = 10 → ratio = (10-6)/10 = 0.40 → 40.00%
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

        // progressive OFF → linear repeat penalty (not quadratic, not ignored)
        var result = _sut.Verify(40.00m, answers, groups, allCriteria, progressiveRepeatPenalty: false);
        Assert.True(result.IsValid, $"C3 linear repeat: expected 40.00 but got {result.ServerScore}");
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

        var result = _sut.Verify(100m, answers, groups, criteria);

        // This will fail (RED) compiling until FailedCriteriaIds is added to VerificationResult
        Assert.Contains(c1, result.FailedCriteriaIds);
        Assert.Contains(c3, result.FailedCriteriaIds);
        Assert.DoesNotContain(c2, result.FailedCriteriaIds);
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

        var result = _sut.Verify(0m, answers, groups, criteria, scoringMode: "survey");

        // This will fail (RED) compiling until FailedCriteriaIds is added
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

        var result = _sut.Verify(100m, answers, groups, criteria);

        // This will fail (RED) compiling until FailedCriteriaIds is added
        Assert.DoesNotContain(c1, result.FailedCriteriaIds);
    }

    // ====================================================================
    // RED: Accumulation mode ignores RepeatedFaults — MISSING FIX
    // ====================================================================

    [Fact]
    public void Accumulation_RepeatedFault_Denies_Points_Even_With_Zero_Base_Faults()
    {
        // In accumulation mode, a criterion with 0 numericValue but RepeatedFaults=1
        // must NOT earn its points — the repeat fault signals previous non-conformance.
        // c1: faults=0, repeatedFaults=1 → denied → earned=0 (out of 10)
        // c2: faults=0, repeatedFaults=0 → earns 5
        // sectionBefore = 15, sectionEarned = 5 → score = 5/15 × 100 = 33.33%
        var sectionId = Guid.NewGuid();
        var c1 = Guid.NewGuid();
        var c2 = Guid.NewGuid();

        var groups = new[] { MakeSection(sectionId, weight: 100) };
        var criteria = new[]
        {
            MakeCriterion(c1, sectionId, points: 10m),
            MakeCriterion(c2, sectionId, points: 5m),
        };
        var answers = new[]
        {
            new Answer { Id = Guid.NewGuid(), CriteriaId = c1, NumericValue = 0, RepeatedFaults = 1 },
            new Answer { Id = Guid.NewGuid(), CriteriaId = c2, NumericValue = 0, RepeatedFaults = 0 },
        };

        var result = _sut.Verify(33.33m, answers, groups, criteria, scoringMode: "accumulation");
        Assert.True(result.IsValid, $"Accumulation repeated fault: expected 33.33 but got {result.ServerScore}");
    }
}
