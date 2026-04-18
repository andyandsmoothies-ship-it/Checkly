using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Services;

namespace Checkly.Api.Tests;

/// <summary>
/// Pure unit tests for ActionPlanEvaluator — no DB needed.
///
/// Tests the "Smart Trigger" rules:
///   Rule 1 — Criticality Override: any CCP/RISK criterion with a negative signal MUST trigger.
///   Rule 2 — Auditor manual override: answer.IsRisk or answer.IsCcp set at response time.
///   Rule 3 — Legacy fallback: pass_fail + non_conform triggers when no trigger metadata exists.
///   Rule 4 — Cap: maximum 10 action plans per submission.
/// </summary>
public class ActionPlanEvaluatorTests
{
    // --- Helper factories ---

    private static Criterion MakeCriterion(
        Guid id,
        string inputType = "pass_fail",
        bool isRisk = false,
        bool isCcp = false,
        string? metadata = null) =>
        new()
        {
            Id = id,
            GroupId = Guid.NewGuid(),
            Label = "Test",
            InputType = inputType,
            IsRisk = isRisk,
            IsCcp = isCcp,
            Metadata = metadata,
        };

    private static Answer MakeAnswer(
        Guid criteriaId,
        string? value = "conform",
        string? note = null,
        string? photoUrl = null,
        bool isRepeatedError = false,
        bool isRisk = false,
        bool isCcp = false,
        decimal? numericValue = null) =>
        new()
        {
            Id = Guid.NewGuid(),
            CriteriaId = criteriaId,
            Value = value,
            Note = note,
            PhotoUrl = photoUrl,
            IsRepeatedError = isRepeatedError,
            IsRisk = isRisk,
            IsCcp = isCcp,
            NumericValue = numericValue,
        };

    // ============================================================
    // Rule 1a — Criterion.IsRisk + non_conform answer → triggers
    // ============================================================

    [Fact]
    public void RiskCriterion_With_NonConform_Answer_Triggers()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, isRisk: true) };
        var answers = new List<Answer> { MakeAnswer(cId, value: "non_conform") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Single(result);
        Assert.Equal(cId, result[0].CriteriaId);
    }

    // ============================================================
    // Rule 1b — Criterion.IsCcp + note (negative signal) → triggers
    // ============================================================

    [Fact]
    public void CcpCriterion_With_Note_Triggers()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, isCcp: true) };
        // Answer value is "conform" but auditor added a note — that IS a negative signal
        var answers = new List<Answer> { MakeAnswer(cId, value: "conform", note: "Packaging damage noticed") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Single(result);
    }

    // ============================================================
    // Rule 1c — Criterion.IsRisk + photo uploaded → triggers
    // ============================================================

    [Fact]
    public void RiskCriterion_With_PhotoUrl_Triggers()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, isRisk: true) };
        var answers = new List<Answer> { MakeAnswer(cId, value: "conform", photoUrl: "https://cdn.example.com/photo.jpg") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Single(result);
    }

    // ============================================================
    // Rule 1d — Criterion.IsRisk + IsRepeatedError → triggers
    // ============================================================

    [Fact]
    public void RiskCriterion_With_RepeatedError_Triggers()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, isRisk: true) };
        var answers = new List<Answer> { MakeAnswer(cId, value: "conform", isRepeatedError: true) };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Single(result);
    }

    // ============================================================
    // Rule 1e (boundary) — Criterion.IsRisk + clean conform → does NOT trigger
    // ============================================================

    [Fact]
    public void RiskCriterion_With_CleanConformAnswer_DoesNotTrigger()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, isRisk: true) };
        // Perfectly clean conform: no note, no photo, no repeated error
        var answers = new List<Answer> { MakeAnswer(cId, value: "conform") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Empty(result);
    }

    // ============================================================
    // Rule 2 — Answer.IsRisk manual override (criterion not flagged) → triggers
    // ============================================================

    [Fact]
    public void AnswerOverride_IsRisk_With_NonConform_Triggers()
    {
        var cId = Guid.NewGuid();
        // Template criterion is a plain pass_fail with no risk flag
        var criteria = new List<Criterion> { MakeCriterion(cId, isRisk: false, isCcp: false) };
        // But the auditor flagged THIS specific answer as a risk at submission time
        var answers = new List<Answer> { MakeAnswer(cId, value: "non_conform", isRisk: true) };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        // Falls through to legacy fallback: pass_fail + non_conform → triggers
        Assert.Single(result);
    }

    // ============================================================
    // Rule 3 — Legacy fallback: pass_fail non_conform triggers
    // ============================================================

    [Fact]
    public void Legacy_PassFail_NonConform_Triggers_Without_Metadata()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, inputType: "pass_fail") };
        var answers = new List<Answer> { MakeAnswer(cId, value: "non_conform") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Single(result);
    }

    // ============================================================
    // Rule 3 boundary — Legacy pass_fail conform does NOT trigger
    // ============================================================

    [Fact]
    public void Legacy_PassFail_Conform_DoesNotTrigger()
    {
        var cId = Guid.NewGuid();
        var criteria = new List<Criterion> { MakeCriterion(cId, inputType: "pass_fail") };
        var answers = new List<Answer> { MakeAnswer(cId, value: "conform") };

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answers, criteria);

        Assert.Empty(result);
    }

    // ============================================================
    // Rule 4 — Cap: never exceeds 10 action plans
    // ============================================================

    [Fact]
    public void Cap_LimitsTriggersTo10_Even_When_MoreMatch()
    {
        var criteriaList = new List<Criterion>();
        var answerList = new List<Answer>();

        for (var i = 0; i < 15; i++)
        {
            var cId = Guid.NewGuid();
            criteriaList.Add(MakeCriterion(cId, isRisk: true));
            answerList.Add(MakeAnswer(cId, value: "non_conform"));
        }

        var result = ActionPlanEvaluator.GetTriggeredAnswers(answerList, criteriaList);

        Assert.Equal(10, result.Count);
    }
}
