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
        bool isRisk = false, bool isCcp = false) =>
        new() { Id = id, GroupId = groupId, PointsWeight = points, IsRisk = isRisk, IsCcp = isCcp };

    private static Answer MakeAnswer(Guid criteriaId, decimal? numericValue = null, string? value = null) =>
        new() { Id = Guid.NewGuid(), CriteriaId = criteriaId, NumericValue = numericValue, Value = value };

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
}
