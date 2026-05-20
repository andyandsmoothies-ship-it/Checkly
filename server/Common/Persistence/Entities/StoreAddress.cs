namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Owned entity for structured store address (Province, District, Ward, Street).
/// Maps to flat columns in the `stores` table via EF Core OwnsOne.
/// Column names: address_province, address_district, address_ward, address_street.
/// SL-1: All fields nullable — additive only. Old `Address` string is NOT removed.
/// </summary>
public sealed class StoreAddress
{
    public string? Province { get; set; }
    public string? District { get; set; }
    public string? Ward { get; set; }
    public string? Street { get; set; }
}
