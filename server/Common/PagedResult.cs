namespace Checkly.Api.Common;

/// <summary>
/// Shared pagination envelope for all list endpoints.
/// </summary>
public sealed record PagedResult<T>(
    List<T> Items,
    int Total,
    int Page,
    int PageSize);
