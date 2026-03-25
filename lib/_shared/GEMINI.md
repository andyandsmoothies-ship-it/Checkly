# 🛡️ Structural Boundary: The Shared Layer

> [!CAUTION]
> You are currently operating inside `lib/_shared/`. This is the shared component library of the Flutter app.

## The "No Business Logic" Mandate
- **STRICT RULE**: You are absolutely FORBIDDEN from adding any feature-specific UI, domain-specific state managers, or template routing logic to this folder.
- **Purpose**: Everything in `_shared/` MUST be generic (e.g., standard buttons, `AuditSectionCard`, database adapters, networking services).
- **If you are building a specific app screen or feature**, you are in the wrong directory. Go up and build it inside `lib/features/{your_feature}/`.
