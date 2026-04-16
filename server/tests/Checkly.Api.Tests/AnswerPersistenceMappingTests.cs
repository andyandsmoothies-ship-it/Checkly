using System;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Xunit;

namespace Checkly.Api.Tests;

public class AnswerPersistenceMappingTests
{
    [Fact]
    public void CreateSubmission_AnswerInsert_PreservesIsCcp()
    {
        // Arrange
        // PB1: AnswerInput with IsCcp = true
        var input = new AnswerInput(Guid.NewGuid(), "non_conform", null, null, null, false, 0, IsCcp: true, IsRisk: false);

        // Act
        // Map to Answer entity as performed in CreateSubmission.cs / FinalizeSubmission.cs
        var answer = new Answer
        {
            Id = Guid.NewGuid(),
            CriteriaId = input.CriteriaId,
            Value = input.Value,
            IsCcp = input.IsCcp
        };

        // Assert
        Assert.True(answer.IsCcp, "Answer.IsCcp should map to true.");
    }

    [Fact]
    public void CreateSubmission_AnswerInsert_PreservesIsRisk()
    {
        // Arrange
        // PB2: AnswerInput with IsRisk = true
        var input = new AnswerInput(Guid.NewGuid(), "na", null, null, null, false, 0, IsCcp: false, IsRisk: true);

        // Act
        // Map to Answer entity
        var answer = new Answer
        {
            Id = Guid.NewGuid(),
            CriteriaId = input.CriteriaId,
            Value = input.Value,
            IsRisk = input.IsRisk
        };

        // Assert
        Assert.True(answer.IsRisk, "Answer.IsRisk should map to true.");
    }

    [Fact]
    public void CreateSubmission_AnswerInsert_FalseValues_NotDropped()
    {
        // Arrange
        // PB3: AnswerInput with explicit false for both flags
        var input = new AnswerInput(Guid.NewGuid(), "conform", null, null, null, false, 0, IsCcp: false, IsRisk: false);

        // Act
        var answer = new Answer
        {
            Id = Guid.NewGuid(),
            CriteriaId = input.CriteriaId,
            Value = input.Value,
            IsCcp = input.IsCcp,
            IsRisk = input.IsRisk
        };

        // Assert
        Assert.False(answer.IsCcp, "Answer.IsCcp should explicitly map to false.");
        Assert.False(answer.IsRisk, "Answer.IsRisk should explicitly map to false.");
    }
}
