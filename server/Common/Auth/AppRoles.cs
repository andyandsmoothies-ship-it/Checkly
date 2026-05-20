namespace Checkly.Api.Common.Auth;

/// <summary>
/// Item-14 / CRIT-02: Centralized role name constants.
/// Mirrors the pattern of <see cref="AppCapabilities"/> for capability strings.
/// Use these constants everywhere a role string is compared. NEVER use raw string literals.
/// IMPORTANT: These values must exactly match the strings stored in the database
/// role column and issued in JWT claims. Do NOT rename these without a matching migration.
/// </summary>
public static class AppRoles
{
    public const string Admin = "admin";
    public const string Auditor = "auditor";
    public const string StoreManager = "store_manager";
    public const string AreaManager = "area_manager";
}
