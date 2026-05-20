namespace Checkly.Api.Common;

public readonly record struct ResourceScope(
    Guid? StoreId = null,
    Guid? OwnerId = null
);
