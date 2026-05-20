namespace Checkly.Api.Features.Admin;

/// <summary>Admin endpoint DTOs.</summary>

public sealed record UserDto(
    Guid Id,
    string? FullName,
    string? Email,
    string? AvatarUrl,
    string Role,
    Guid? StoreId,
    string? StoreName,
    bool IsLocked,
    DateTimeOffset CreatedAt,
    Guid[]? AssignedStoreIds = null);

public sealed record BanUserResponse(Guid Id, bool IsBanned);
