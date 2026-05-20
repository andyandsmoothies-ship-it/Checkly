using Checkly.Api.Common.Reference;

namespace Checkly.Api.Features.Stores;

/// <summary>
/// Item-16 / WARN-01: Centralizes province and street address validation that was
/// copy-pasted verbatim in CreateStore and UpdateStore.
/// This is business rule logic (not glue code) — the province list and max length
/// must stay in sync between both handlers.
/// </summary>
internal static class StoreAddressValidator
{
    /// <summary>
    /// Validates <paramref name="province"/> against the Vietnam province list and
    /// validates <paramref name="street"/> maximum length.
    /// Returns <c>null</c> when all inputs are valid. Returns a BadRequest result on failure.
    /// </summary>
    internal static IResult? Validate(string? province, string? street)
    {
        if (province is not null && !VietnamLocations.IsValidProvince(province))
            return Results.BadRequest(new { error = $"Province '{province}' is not a valid Vietnam administrative province." });

        if (street?.Length > 200)
            return Results.BadRequest(new { error = "Street must not exceed 200 characters" });

        return null; // null = all valid
    }
}
