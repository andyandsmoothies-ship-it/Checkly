namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Admin audit trail — records admin actions for observability.
/// Maps to: public.system_logs
/// </summary>
public sealed class SystemLog
{
    public Guid Id { get; set; }
    public Guid? UserId { get; set; }
    public string Action { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public string? Message { get; set; }
    public string? Path { get; set; }
    public string Level { get; set; } = "info"; // info, warning, error
    public string? EntityType { get; set; }
    public Guid? EntityId { get; set; }
    public string? TraceId { get; set; }
    public string? UserEmail { get; set; }
    public DateTimeOffset CreatedAt { get; set; }
}
