namespace Checkly.Api.Features.Submissions;

/// <summary>
/// DTOs for submission API.
/// </summary>
public sealed record CreateSubmissionRequest(
    Guid TemplateId,
    Guid StoreId,
    decimal? ClientScore,
    string? SectionScores,
    string? Notes,
    decimal? GpsLat,
    decimal? GpsLng,
    List<AnswerInput>? Answers,
    string? IdempotencyKey = null,
    string? Status = null,
    DateTimeOffset? ScheduledAt = null);

public sealed record AnswerInput(
    Guid CriteriaId,
    string? Value,
    decimal? NumericValue,
    string? Note,
    string? PhotoUrl,
    bool IsRepeatedError);

public sealed record SubmissionDto(
    Guid Id,
    Guid? TemplateId,
    string? TemplateTitle,
    string? DisplayNoun,
    Guid? StoreId,
    string? StoreName,
    Guid? AuditorId,
    string? AuditorName,
    string Status,
    decimal? TotalScore,
    string? SectionScores,
    string? Notes,
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt,
    DateTimeOffset? ScheduledAt);

public sealed record SubmissionDetailDto(
    Guid Id,
    Guid? TemplateId,
    string? TemplateTitle,
    string? DisplayNoun,
    Guid? StoreId,
    string? StoreName,
    Guid? AuditorId,
    string? AuditorName,
    string Status,
    decimal? TotalScore,
    string? SectionScores,
    string? Notes,
    decimal? GpsLat,
    decimal? GpsLng,
    DateTimeOffset CreatedAt,
    DateTimeOffset? CompletedAt,
    List<AnswerDto> Answers);

public sealed record AnswerDto(
    Guid Id,
    Guid? CriteriaId,
    string? CriteriaLabel,
    string? Value,
    decimal? NumericValue,
    string? Note,
    string? PhotoUrl,
    bool IsRepeatedError);
