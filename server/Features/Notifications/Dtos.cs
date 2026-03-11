namespace Checkly.Api.Features.Notifications;

/// <summary>
/// DTOs for notification API.
/// </summary>
public sealed record NotificationDto(
    Guid Id,
    Guid UserId,
    string Type,
    string Title,
    string? Message,
    DateTimeOffset? ReadAt,
    string? ActionUrl,
    string? Metadata,
    DateTimeOffset CreatedAt);
