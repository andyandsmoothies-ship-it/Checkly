namespace Checkly.Api.Common.Persistence.Entities;

/// <summary>
/// Owned entity for structured store address (Province, District, Ward, Street).
/// Maps to flat columns in the `stores` table via EF Core OwnsOne.
/// Column names: address_province, address_district, address_ward, address_street.
/// Province is the required identifying field (NOT NULL in DB).
/// District, Ward, Street remain optional (nullable).
/// </summary>
public sealed class StoreAddress
{
    public string Province { get; set; } = string.Empty;
    public string? District { get; set; }
    public string? Ward { get; set; }
    public string? Street { get; set; }
}

