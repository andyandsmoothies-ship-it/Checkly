# 🛡️ Structural Boundary: The Common Layer

> [!CAUTION]
> You are currently operating inside `server/Common/`. This is the shared architectural backbone of the backend.

## The "No Business Logic" Mandate
- **STRICT RULE**: You are absolutely FORBIDDEN from adding any template-specific, store-specific, or single-feature business logic to this folder.
- **Purpose**: Everything in `Common/` MUST be highly generic, reusable infrastructure (e.g., `SubmissionAccessGuard`, `AuditLogger`, `PagedResult`).
- **If you are building a specific feature handler**, you are in the wrong directory. Go up and build it inside `server/Features/{YourFeature}/`.
