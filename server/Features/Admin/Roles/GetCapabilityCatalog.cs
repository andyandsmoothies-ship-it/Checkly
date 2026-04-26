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
        "analytics:view",
        "analytics:area",
        "submissions:list",
        "submissions:create",
        "submissions:review",
        "action_plans:write",
        "action_plans:verify",
        "admin:manage_roles",
        "admin:access",
    ];

    public static readonly Dictionary<string, CapabilityMeta> CapabilityMetadata = new()
    {
        { "templates:create", new("Create Templates", "Templates", "Create new template structures") },
        { "templates:update", new("Edit Templates", "Templates", "Modify existing templates") },
        { "templates:delete", new("Delete Templates", "Templates", "Archive/Delete templates") },
        { "stores:write", new("Manage Stores", "Stores", "Create or edit store locations") },
        { "areas:write", new("Manage Areas", "Areas", "Create or edit areas") },
        { "users:manage", new("Manage Users", "Users", "Add/remove users and change assignments") },
        { "analytics:admin", new("Admin Analytics", "Analytics", "View cross-area global analytics") },
        { "analytics:view", new("View Analytics", "Analytics", "Access the analytics dashboard") },
        { "analytics:area", new("Area Analytics", "Analytics", "View analytics for assigned areas") },
        { "submissions:list", new("View Submissions", "Submissions", "View audit submissions") },
        { "submissions:create", new("Create Submissions", "Submissions", "Submit new audits") },
        { "submissions:review", new("Review Submissions", "Submissions", "Review and grade audits") },
        { "action_plans:write", new("Write Action Plans", "Action Plans", "Create and submit action plans") },
        { "action_plans:verify", new("Verify Action Plans", "Action Plans", "Approve or reject action plans") },
        { "admin:manage_roles", new("Manage Roles", "Admin", "Assign capabilities to roles") },
        { "admin:access", new("Admin Console Access", "Admin", "Access the web admin panel") }
    };

    public static IResult HandleAsync()
        => TypedResults.Ok(new CatalogResponse(Catalog, CapabilityMetadata));
}

/// <summary>DTO for GET /api/admin/capabilities/catalog response.</summary>
public sealed record CatalogResponse(
    string[] Capabilities,
    Dictionary<string, CapabilityMeta> CapabilityMetadata
);

public sealed record CapabilityMeta(string Label, string Group, string Description);
