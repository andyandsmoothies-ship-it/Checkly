# Masterclass: Building Scalable Access Control (RBAC/PBAC)

This reference document outlines universal best practices for designing and implementing Permission-Based Access Control (PBAC) and Role-Based Access Control (RBAC) systems. These principles apply across all software paradigms, including SaaS, Enterprise systems, Mobile applications, and microservices.

## Core Architectural Principles

### 1. The Golden Rule: Capabilities over Roles
Never hardcode role names (e.g., `if user.role == 'Admin'`) in your application code or frontend UI. 
- **Why**: Business hierarchies change constantly. Hardcoding roles requires massive code refactors when new roles are introduced or definitions change.
- **Solution**: Code must strictly evaluate granular capabilities/permissions (e.g., `if user.hasCapability('invoice:delete')`). Roles exist purely in the database to group capabilities together for easier assignment.

### 2. Default Deny Architecture
Every API endpoint, database query, and UI component must be locked down by default.
- Developers must explicitly apply an authorization guard (e.g., `[RequireCapability("users:read")]`) to expose functionality.
- A forgotten authorization guard should result in a 403 Forbidden, not a data breach.

### 3. Decouple AuthN from AuthZ
Understand the boundary between identity and access.
- **Authentication (AuthN)** answers "Who are you?" (Managed by Okta, Auth0, AWS Cognito, etc.).
- **Authorization (AuthZ)** answers "What are you allowed to do here?" (Managed by your application's PBAC system).
- **Rule**: Do not force your external Identity Provider to manage your fine-grained, application-specific business logic.

## Frontend / UI Best Practices

### 4. The "Dumb" UI Pattern
The frontend application should not calculate authorization logic. 
- **The Sync**: Upon login, the backend provides the frontend with a flat list of capability strings assigned to the user.
- **Proactive Hiding**: The UI simply evaluates this list. If `invoice:create` is missing, the UI completely hides the "New Invoice" button. Do not show disabled buttons unless required for a specific upsell/UX reason, as it creates frustration.
- **Graceful Failure**: The UI must still handle 403 errors gracefully, as capabilities can be revoked mid-session before the UI syncs again.

## Backend & Database Best Practices

### 5. Contextual & Scope-Based Security (IDOR Prevention)
Possessing a capability string is not enough for data modification.
- **The Problem**: A user possesses `invoice:delete`. Does that mean they can delete *any* invoice in the system?
- **The Solution**: Your backend must evaluate **Ownership/Scope**. 
  1. Does the user have `invoice:delete`?
  2. Does the `OrganizationId` of the invoice match the `OrganizationId` of the user making the request?

### 6. The Multi-Tenant Boundary (SaaS)
If building B2B SaaS software, roles must be scoped to the Tenant/Organization, not just the User.
- A user might be an "Admin" in Workspace A, but only a "Viewer" in Workspace B. 
- The database relationship must be a 3-way join: `User <-> Tenant <-> Role`. 

### 7. Additive Permissions Only (Avoid Deny Rules)
Avoid building systems that mix "Allow" and "Deny" rules (e.g., "Allow everything EXCEPT billing").
- **Why**: Resolving conflicts between overlapping Allow/Deny rules is notoriously difficult, computationally expensive, and highly prone to developer error.
- **Solution**: Stick to a strictly Additive (Whitelist) model. If you don't explicitly have the capability, you can't do it.

### 8. JWT Payload Optimization
Do not inject all of a user's capabilities into the JWT (JSON Web Token) payload.
- **Why**: As your app grows, a user might have 300 capabilities. This bloats the token size, causing HTTP headers to exceed limits (resulting in 431 Request Header Fields Too Large errors) and slowing down every network request.
- **Solution**: Store only the `UserId` and `TenantId` (or `RoleId`) in the token. Have the backend API gateway or application middleware cache the specific capabilities in Redis, looking them up securely per request.

## Operations & Security

### 9. Immutable Audit Logging
Permissions are the most critical security vector in an application.
- Every time a role is modified, or a user is granted a new role, the system must write an immutable log to an Audit table.
- **Schema**: `Timestamp`, `ActorId` (Who did it), `TargetId` (Who received it), `Action` (Granted/Revoked), `Entity` (Role/Capability).

### 10. The "God Mode" Escape Hatch
Implement a strict, highly monitored bypass for extreme emergencies.
- If a junior admin accidentally deletes the main Admin role mapping, the system is permanently locked.
- Support a hardcoded `IsSystemAdmin` boolean or `*` super-capability that bypasses database role checks. Limit this to internal super-users and alert the engineering team whenever it is invoked.

### 11. Test the "Hacker" Paths
Security is defined by what fails, not what succeeds.
- Do not just write integration tests proving an Admin can delete a record. 
- You MUST write tests proving that an unauthorized user attempting the exact same API call receives a `403 Forbidden` response. No test suite is complete without explicitly testing the rejection paths.
