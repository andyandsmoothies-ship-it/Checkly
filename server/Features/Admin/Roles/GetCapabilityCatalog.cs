namespace Checkly.Api.Features.Admin.Roles;

/// <summary>
/// GET /api/admin/capabilities/catalog
/// Returns the static canonical list of valid capability strings.
/// This list is the single source of truth. Flutter uses it to build the checkbox grid,
/// preventing free-text typos from reaching the DB.
/// Auth: RequireAuthorization("AdminOnly") from group (no extra capability gate — read-only).
/// </summary>
public static class GetCapabilityCatalog
{
    /// <summary>
    /// All 15 valid capability strings. Hardcoded (YAGNI — stable V2 set).
    /// Adding a new capability here requires a coordinated deploy.
    /// </summary>
    public static readonly string[] Catalog =
    [
        "templates:create",
        "templates:update",
        "templates:delete",
        "stores:write",
        "areas:write",
        "users:manage",
        "analytics:admin",
        "analytics:area",
        "submissions:list",
        "submissions:create",
        "submissions:review",
        "action_plans:write",
        "action_plans:verify",
        "admin:manage_roles",
        "admin:access",
    ];

    public static IResult HandleAsync()
        => TypedResults.Ok(new CatalogResponse(Catalog));
}

/// <summary>DTO for GET /api/admin/capabilities/catalog response.</summary>
public sealed record CatalogResponse(string[] Capabilities);
