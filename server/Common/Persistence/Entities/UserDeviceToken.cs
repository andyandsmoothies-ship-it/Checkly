using System;

namespace Checkly.Api.Common.Persistence.Entities;

public class UserDeviceToken
{
    public Guid Id { get; set; }
    public Guid UserId { get; set; }
    public string FcmToken { get; set; } = string.Empty;
    public string Platform { get; set; } = string.Empty;
    public DateTime LastUsedAt { get; set; }
    public DateTime CreatedAt { get; set; }
}
