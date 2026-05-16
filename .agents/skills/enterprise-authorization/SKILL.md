---
name: enterprise-authorization
description: >
  Advanced enterprise-grade authorization architecture for ANY full-stack application (Node.js, Python, Java, .NET, Go). Combines Role-Based Access Control (RBAC) and Policy-Based Access Control (PBAC) using the Strict Bimodal (Hybrid) pattern. Load this skill whenever the user asks to implement permissions, roles, PBAC, UI access control, solve JWT token bloat, write authorization handlers/guards, or map backend capabilities to frontend allowedActions.
---

# Enterprise Authorization (RBAC + PBAC Continuum)

## Agent Execution Instructions
When you are tasked with implementing or modifying authorization, you MUST:
1. **Identify the Scope**: Determine if the requirement needs Global Access (RBAC) or Contextual Access (PBAC).
2. **Compute on Backend**: Never write local `if/else` capability checks in the frontend UI (Flutter, React, Vue, etc.). You must compute outcomes in the backend and project them as strings.
3. **Prevent Token Bloat**: Never pack raw permissions into the JWT token. Always resolve them dynamically at runtime using caching (Redis, In-Memory) via Middleware, Interceptors, or Claims Transformations.
4. **Default to Deny**: Ensure the frontend `ActionGuard` always fails closed if the `allowedActions` array is missing.

> [!IMPORTANT]
> **The Authorization Continuum:** RBAC and PBAC are not competing systems; they are two phases of the same pipeline. This skill enforces a **Strict Bimodal Architecture** that handles global navigation via RBAC capabilities, and contextual UI operations via PBAC rules.

## Phase 1: The RBAC Foundation (Global Scope)

RBAC controls global access: *"Is this user allowed to view the 'Action Plans' module?"*

### 1. Solving JWT Token Bloat (Server-Side Resolution)
Do not pack dozens of permissions into the JWT, which causes `431 Request Header Fields Too Large` errors. Use Server-Side Resolution (like `IClaimsTransformation` in .NET, or custom Middleware in Node/Express) to fetch flat permissions from the database on every request.

*(.NET Example)*
```csharp
public class PermissionClaimsTransformation(IPermissionService permissionService) : IClaimsTransformation
{
    public async Task<ClaimsPrincipal> TransformAsync(ClaimsPrincipal principal)
    {
        // FETCH FROM CACHE (Critical: Use IDistributedCache or MemoryCache to prevent DB DDoS)
        var permissions = await permissionService.GetUserPermissionsAsync(userId);
        // Map to standard claims...
    }
}
```

## Phase 2: The PBAC Engine (Contextual Scope & State-Based Symmetry)

PBAC controls contextual access: *"Is this user allowed to edit **this specific** Action Plan **right now**?"*

Unlike RBAC which focuses on the User (leading to exponential role bloat), PBAC focuses on the **Resource**. When rules depend on the entity's state (e.g., "Draft" vs "Published") or ownership, use Resource-Based Authorization. 

This enforces **State-Based Symmetry**: access is evaluated dynamically against observable states in real-time, rather than being granted/revoked by point-in-time events. This guarantees immediate revocation of access the millisecond a resource's state changes.

*(.NET Example)*
```csharp
public class ActionPlanAuthorizationHandler : AuthorizationHandler<EditActionPlanRequirement, ActionPlan>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, EditActionPlanRequirement requirement, ActionPlan resource)
    {
        var hasEditPermission = context.User.HasClaim("permission", "action_plans:edit");
        
        // PBAC Rule: Can only edit if user has global permission AND plan is in Draft status
        if (hasEditPermission && resource.Status == "Draft") context.Succeed(requirement);
        return Task.CompletedTask;
    }
}
```

## Phase 3: The Strict Bimodal UI Contract (PDP vs PEP)

To prevent frontend UI bugs and authorization drift, the backend **MUST NOT** expect the frontend to calculate PBAC rules. We implement a strict separation between the Policy Decision Point (PDP) and Policy Enforcement Point (PEP) to preserve privacy and prevent sensitive claims from bleeding into the client.

### 1. The Policy Decision Point (PDP): Boolean-to-String Projection (Backend)
The backend acts as the authoritative **PDP**. To avoid N+1 queries, the backend computes PBAC outcomes as database projections and outputs them as a simple string array of allowed actions on the DTO.

*(.NET EF Core Example)*
```csharp
// The PBAC Translation mapped directly in the SQL query
AllowedActions = new List<string> {
    "view",
    (hasEditPermission && plan.Status == "Draft") ? "edit" : null
}.Where(a => a != null).ToArray()
```

### 2. The Policy Enforcement Point (PEP): ActionGuard (Frontend)
The frontend UI acts strictly as the **PEP**. It is "dumb", knows nothing about the user's role or business rules, and strictly defaults to **deny**. It wraps actionable widgets (like buttons or context menus) in an `ActionGuard` component that simply enforces the backend's decision by checking for the string presence in the payload.

*(Flutter Example)*
```dart
ActionGuard(
  allowedActions: dto.allowedActions,
  requiredAction: 'edit',
  child: IconButton(icon: Icon(Icons.edit), onPressed: _editPlan),
)
```

## Framework-Agnostic Mapping

While the examples above are in .NET/Flutter, this architectural pattern translates perfectly to any stack:

| Concept | .NET / C# | Node.js / NestJS | Python / Django | Frontend (React / Vue) |
| :--- | :--- | :--- | :--- | :--- |
| **Solving Token Bloat** | `IClaimsTransformation` | Custom Express Middleware | Custom Request Interceptor | N/A |
| **PBAC Engine** | `IAuthorizationHandler` | NestJS `@Injectable() Guard` | Django Custom `@decorator` | N/A |
| **PDP Projections** | EF Core `.Select()` | Prisma `select` / TypeORM | Django ORM `.annotate()` | N/A |
| **PEP ActionGuard** | Flutter `ActionGuard` Widget | React `<ActionGuard>` Component | Vue `v-action` directive | N/A |

## Gotchas & Edge Cases
*   **DB DDoS:** If you query the database directly to resolve permissions without a caching layer (Redis, Memcached), you will tank application throughput because it runs on every HTTP request.
*   **N+1 Query Risk:** Never load entities into memory and iterate through them to build UI lists. Always use DB boolean projections (Select/Map) to compute capabilities, then translate to strings.
*   **ActionGuard "Fail Closed":** If `allowedActions` is null or missing on a payload, the UI must completely hide the action.
