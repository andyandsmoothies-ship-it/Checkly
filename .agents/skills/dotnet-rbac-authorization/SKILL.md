---
name: dotnet-rbac-authorization
description: >
  Advanced Role-Based Access Control (RBAC) and Permission-based authorization for ASP.NET Core. 
  Make sure to load and use this skill whenever the user asks to implement permissions, roles, custom authorization policies, [RequirePermission] attributes, or mentions solving large JWT token bloat using IClaimsTransformation in .NET.
---

# Role-Based Access Control (RBAC) in ASP.NET Core

> [!NOTE]
> **Performance Context:** This skill focuses on the "Users -> Roles -> Permissions" architecture. It replaces hardcoded role strings (`[Authorize(Roles="Admin")]`) with fine-grained, policy-driven permission checks.

## Core Strategy

Do not check what role a user has. Check what **permission** they have. A user might have a `Manager` role, but the code should only care if they possess the `users:delete` permission. 

Roles are simply buckets that hold multiple permissions. This allows roles to be modified in the database without recompiling the application.

## Implementation Patterns

### 1. The Dynamic Permission Handler
Instead of creating a separate Authorization Handler for every single policy, create a single dynamic handler that accepts an array of permissions and checks if the user possesses at least one of them.

```csharp
public class PermissionAuthorizationRequirement(params string[] allowedPermissions) 
    : AuthorizationHandler<PermissionAuthorizationRequirement>, IAuthorizationRequirement
{
    public string[] AllowedPermissions { get; } = allowedPermissions;

    protected override Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionAuthorizationRequirement requirement)
    {
        // OR operational check: Succeed if user has AT LEAST ONE matching permission claim
        foreach (var permission in requirement.AllowedPermissions)
        {
            if (context.User.HasClaim("permission", permission))
            {
                context.Succeed(requirement);
                break;
            }
        }
        return Task.CompletedTask;
    }
}
```

### 2. Clean Extensions (Minimal APIs)
To avoid polluting route definitions with verbose policy builders, extract an extension method:

```csharp
public static class PermissionExtensions
{
    public static void RequirePermission(this AuthorizationPolicyBuilder builder, params string[] allowedPermissions)
    {
        builder.AddRequirements(new PermissionAuthorizationRequirement(allowedPermissions));
    }
}

// Usage in Minimal API:
app.MapDelete("/users/{id}", DeleteUserHandler)
   .RequireAuthorization(policy => policy.RequirePermission("users:delete"));
```

### 3. Clean Extensions (MVC Controllers)
For attribute-based routing, subclass `AuthorizeAttribute`:

```csharp
[AttributeUsage(AttributeTargets.Method | AttributeTargets.Class)]
public class RequirePermissionAttribute : AuthorizeAttribute
{
    public RequirePermissionAttribute(params string[] permissions) 
        // Generates a policy name like "users:delete,users:update"
        : base(policy: string.Join(",", permissions)) { }
}

// You MUST register the dynamic policy provider or explicitly register the policies in DI:
builder.Services.AddAuthorizationBuilder()
    .AddPolicy("users:delete", policy => policy.RequirePermission("users:delete"));
```

### 4. Server-Side Resolution (IClaimsTransformation)
Storing dozens of permissions in a JWT causes "Token Bloat" which can break HTTP header size limits. The solution is to fetch permissions from the database dynamically via `IClaimsTransformation`.

```csharp
public class PermissionClaimsTransformation(IPermissionService permissionService) : IClaimsTransformation
{
    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        if (principal.Identity?.IsAuthenticated != true) return principal;

        var userId = principal.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userId == null) return principal;

        // FETCH FROM CACHE (Critical step!)
        var permissions = await permissionService.GetUserPermissionsAsync(userId);
        var claimsIdentity = (ClaimsIdentity)principal.Identity;

        foreach (var permission in permissions)
        {
            claimsIdentity.AddClaim(new Claim("permission", permission));
        }

        return principal;
    }
}
```

## Gotchas & Edge Cases

* **IClaimsTransformation DB DDoS:** The `TransformAsync` method runs on **EVERY SINGLE HTTP REQUEST**. If you query the database directly inside this method without a caching layer (`IDistributedCache` or `IMemoryCache`), you will DDoS your own database and drastically tank application throughput. 
* **Header Size Limits (Token Bloat):** If you decide to pack permissions into the JWT (`..permissions.Select(p => new Claim("permission", p))`), be warned that IIS, Kestrel, and Nginx have strict header size limits (usually 8KB - 16KB). Users with many permissions will get `431 Request Header Fields Too Large` errors. Use `IClaimsTransformation` to resolve this.
* **AND vs OR Permission Checks:** The default `PermissionAuthorizationRequirement` implementation shown above executes an **OR** check (user only needs one of the array's permissions). If a feature requires the user to have **ALL** permissions provided, you must rewrite the handler logic to enforce an `AND` state.
* **Type Safety with Enums:** Using string constants (`"users:read"`) works, but mapping to `public enum Permission { UsersRead }` offers compile-time safety. However, beware of the serialization overhead when translating enums to strings inside claims loops.
