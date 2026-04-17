using System.Text.Json.Serialization;

namespace Checkly.Api.Tests;

public sealed record VectorFile(
    [property: JsonPropertyName("vectors")] List<TestVector> Vectors);

public sealed record TestVector(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("description")] string Description,
    [property: JsonPropertyName("scoringMode")] string ScoringMode,
    [property: JsonPropertyName("progressiveRepeatPenalty")] bool ProgressiveRepeatPenalty,
    [property: JsonPropertyName("isPurityGateTriggered")] bool IsPurityGateTriggered,
    [property: JsonPropertyName("expectedError")] string? ExpectedError,
    [property: JsonPropertyName("sections")] List<SectionDto> Sections,
    [property: JsonPropertyName("answers")] List<AnswerDto> Answers,
    [property: JsonPropertyName("expectedScore")] decimal ExpectedScore);

public sealed record SectionDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("weight")] decimal Weight,
    [property: JsonPropertyName("maxDeductionPoints")] decimal? MaxDeductionPoints,
    [property: JsonPropertyName("criteria")] List<CriterionDto> Criteria,
    [property: JsonPropertyName("subsections")] List<SubsectionDto>? Subsections);

public sealed record SubsectionDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("title")] string Title,
    [property: JsonPropertyName("maxPoints")] decimal MaxPoints,
    [property: JsonPropertyName("criteria")] List<CriterionDto> Criteria);

public sealed record CriterionDto(
    [property: JsonPropertyName("id")] string Id,
    [property: JsonPropertyName("groupId")] string GroupId,
    [property: JsonPropertyName("pointsWeight")] decimal? PointsWeight,
    [property: JsonPropertyName("isCcp")] bool IsCcp,
    [property: JsonPropertyName("isRisk")] bool IsRisk,
    [property: JsonPropertyName("minusImpact")] decimal? MinusImpact,
    [property: JsonPropertyName("inputType")] string InputType);

public sealed record AnswerDto(
    [property: JsonPropertyName("criteriaId")] string CriteriaId,
    [property: JsonPropertyName("numericValue")] decimal? NumericValue,
    [property: JsonPropertyName("value")] string? Value,
    [property: JsonPropertyName("repeatedFaults")] int RepeatedFaults,
    [property: JsonPropertyName("isExplicitRiskOverride")] bool IsExplicitRiskOverride);
