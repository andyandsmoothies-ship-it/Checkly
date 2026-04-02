---
trigger: always_on
description: Engineering standards — architecture, security, and verification in one place.
---

# Antigravity Engineering Standards

---

## 1. Architecture & Isolation

### Feature Isolation & Regression Safety
- **Additive Logic**: All code changes must be isolated. If a shared component is modified, you must prove that all existing props and data types remain supported.
- **Conflict Prevention**: Deleting code not directly related to the current task is strictly forbidden without explicit Director approval.

### Feature-Sliced Design (FSD) Compliance — PWA
- **Rule**: Follow the strictly defined layers: `shared` -> `entities` -> `features` -> `widgets` -> `pages` -> `app`.
- **Rule**: Cross-entity imports are FORBIDDEN. Entities must be isolated if possible, or orchestrated via `features`.

### Flutter Mobile Architecture
- **Pattern**: Feature-folder structure under `lib/features/[feature]/`
- **Sub-folders**: `pages/`, `manager/`, `model/`, `services/`, `widgets/`
- **State**: Manager classes extend `ChangeNotifier`, registered via `GetIt`
- **Navigation**: GoRouter declarative routing
- **DI**: GetIt service locator (singleton managers, scoped services)
- **Database (Drift)**: All unpaginated `.get()` queries MUST include a `.limit(n)` boundary to prevent OOM violations on large datasets.
- **Database (Drift) Aggregations**: Always use native SQLite aggregations (e.g., `countAll()`) instead of `.get().length` to count records. This is mandatory to prevent offline Out-Of-Memory (OOM) crashes on devices with large datasets.
- **Build**: `flutter analyze` + `flutter test` must pass before handoff
- **Layouts**: The `_MainShell` root layout must use a `Stack` (not a column) with `extendBody: true` to ensure the Floating Action Button (FAB) and glassmorphism nav bars anchor correctly.

#### Flutter Feature Structure
```
lib/features/[feature]/
├── manager/        # ChangeNotifier state management
│   └── [feature]_manager.dart
├── model/          # DTOs and data classes
│   └── [feature]_dto.dart
├── models/         # Editable/validation models (e.g., EditableGroup, ValidationErrors)
├── pages/          # Route-level widgets
│   └── [feature]_page.dart
├── services/       # API calls and business logic
│   └── [feature]_api_service.dart
└── widgets/        # Feature-specific reusable widgets
```

### Service Layer Pattern (MANDATORY) — PWA
- **Philosophy**: Hooks manage State; Services manage Data.
- **Rule**: Direct `supabase` calls are FORBIDDEN in Hooks and Components.
- **Action**: Always encapsulate raw queries and RPCs in `src/entities/[entity]/api/[Service].ts`.

#### Entity Structure (FSD)
Each domain entity follows this folder structure:
```
src/entities/[entity]/
├── api/          # Service layer (Supabase calls)
│   └── [entity]Service.ts
├── model/        # React Query hooks
│   └── use[Entity]s.ts
├── ui/           # Entity-specific presentational components
│   └── [Component].tsx
└── index.ts      # Public API exports
```

#### Implementation Standards
- **Imports**: 
  - `supabase` client is FORBIDDEN in Hooks and Components. It must only reside in Services.
  - Hooks must import service objects from `@/entities/[entity]/api/`.
  - App-level providers (AuthProvider) must import from specific files, NOT entity index, to avoid bundler cycles.
- **Typing**: 
  - All domain interfaces (e.g., `Submission`, `Store`) must be defined in the corresponding service file and exported.
  - Hooks should re-export these types for convenience if they are primary domain models.
- **RPC Usage**: All Database RPC calls MUST be encapsulated within a service method.
- **Error Handling**: Services should throw normalized errors. Hooks catch and trigger UI side-effects (e.g., `toast`).

#### Forbidden Patterns
- `import { supabase } from '@/integrations/supabase/client'` outside of `src/entities/*/api/`.
- Embedded query logic (e.g., `.from('table').select('*')`) inside `useQuery` or `useMutation` hooks.
- Cross-entity imports (e.g., importing from `entities/user` within `entities/store`).

### Initialization Cycle Prevention
- **Rule**: To avoid initialization-order hazards, App-level hooks (like `AuthProvider`) MUST import from specific entity files (e.g., `entities/user/api/authService`) rather than the entity index `index.ts`.

### Operational Safeguards
#### The "Zero Ghost" Import Protocol
- **Forbidden**: Do not use variables, hooks, or components not explicitly imported.
- **Mental Grep**:
    - `useState` -> `react`
    - `cn` -> `@/lib/utils`
    - Icons -> `lucide-react`
    - Components -> `@/components/ui`

### The Specification Gate
- **Rule**: PROHIBITED from creating an `implementation_plan.md` for a new feature or complex bug fix until a `functional_spec_[feature].md` exists and has been approved by the user.

### Cross-Feature Correlation
- **Rule**: Before modifying any Shared Service or Hook, you MUST identify all Consumer files via `grep`.
- **Requirement**: Update or create corresponding tests in the `__tests__` directory for shared logic changes.

---

## 2. Security (OWASP)

### Core Principles
- **Secure Coding**: Adopt a "deny-by-default" security posture.
- **Least Privilege**: Services/Hooks must only access the minimum data required.
- **Secrets Protocol**: NO hardcoded keys. Use environment variables or user secrets exclusively.
- **Error Handling**: Never leak server-side stack traces or internal schema details.

### OWASP Top 10 Adherence
- **A01: Broken Access Control**: Admin endpoints use `RequireAuthorization("AdminOnly")` at the route group level. Area management (POST/PUT) requires `AdminOnly`. IDOR checks in every handler via `SubmissionAccessGuard.CanAccessAsync()` for submission-scoped resources (submissions, photos).
- **A03: Injection**: Use EF Core LINQ or parameterized queries. Raw SQL with user input is forbidden.
- **A05: Security Misconfiguration**: CORS policy is config-driven via `Cors:AllowedOrigins` in appsettings. Never use `AllowAnyOrigin()` with `AllowCredentials()`.
- **A07: Auth Failures**: Login endpoint uses `SignInManager.CheckPasswordSignInAsync` with `lockoutOnFailure: true`. Account locks after 5 failed attempts for 15 minutes.

### Server Auth Configuration
- **JWT**: ValidateIssuer, ValidateAudience, ValidateLifetime, ValidateIssuerSigningKey = `true`. ClockSkew = `Zero`.
- **Lockout**: 5 attempts max, 15-min lockout, enabled for new users.
- **CORS**: Middleware ordering: `UseCors()` → `UseAuthentication()` → `UseAuthorization()`.
- **Policies**: `AdminOnly`, `AuditorAccess`, `StoreManagerAccess`, `AreaManagerAccess`.
- **IDOR Guard**: `SubmissionAccessGuard` (`Common/SubmissionAccessGuard.cs`) — reusable guard for all submission-scoped resources. Uses `Guid.TryParse` for defense-in-depth. Role-based access: admin→all, auditor→owns, store_manager→their store, area_manager→their area.

### Media & Storage Security
- **File Limits**: All media upload endpoints (`UploadPhoto`) must strictly enforce a maximum file size of **15MB**.
- **MIME Whitelisting**: Strict MIME-type whitelisting is mandatory for all inbound files (e.g., `.jpg`, `.jpeg`, `.png`, `.webp`, `.heic`). Reject any other format with a `400 Bad Request` to prevent arbitrary file upload execution (A03: Injection/DoS).
- **Path Traversal Defense**: All APIs streaming files (e.g., `GetPhoto`) MUST bind lookup parameters via strict typed `Guid` checking and sanitize output paths against `..`, `/`, and `\` injection.

### Server API Standards
- **Pagination**: All list endpoints MUST return `PagedResult<T>` (from `Common/PagedResult.cs`). Use `page`/`pageSize` query params with defaults (page=1, pageSize=50) and enforced max (200). Pattern: `Skip((page-1)*pageSize).Take(pageSize)` + `CountAsync`.
- **Transaction Singularity**: Shared services (e.g., `ActionPlanService`) MUST NOT call `SaveChangesAsync` internally. They must participate in the caller's transaction (`CreateSubmission`, `FinalizeSubmission`) to ensure atomicity and prevent orphaned records or race conditions.
- **Audit Logging**: All sensitive operations (template CRUD, submission finalization, admin user actions) MUST write to `system_logs` via `AuditLogger.Log()` (`Common/Services/AuditLogger.cs`). Use `EntityType` + `EntityId` for entity-level traceability. Logs participate in the same SaveChanges transaction as the primary operation.

---

## 3. Verification & Quality

### The Build Wall
Never report a task as complete without verifying the build environment.
- **Command**: Run `npx tsc --noEmit` for TypeScript verification.
- **Self-Audit**: Read the code diff one last time for incomplete functions or hallucinated imports.
- **Handoff**: Explicitly state: "Self-Audit Complete: No Type Errors Found."

### Test Contract Protocol
- **Requirement**: Every `functional_spec` MUST define a "Logic Validation Plan" mapping scenarios to specific test files.
- **Execution Gate**: No feature is "Implemented" until unit tests in the `__tests__` directory pass.
- **Action**: Run `npm test [fileName]` before reporting completion.

### The Parity Wall (Refactor Integrity)
For refactors reducing file size by >30% or extracting logic:
- **Action**: Audit "Deleted Logic" against "New Hook/Component" to ensure zero omissions.
- **Action**: Trace the "Zero-Interaction" path (e.g., submit without changes) to ensure default behaviors are preserved.

### Cleanup Protocol
- **Dependency Audit**: Before deleting code, perform a search to ensure no remaining functions reference its variables or imports.
- **Incremental Refactoring**: Ensure new dependencies are fully declared before removing legacy logic.

---

## 4. Documentation & Visualization

### Visual Spec Protocol
- **Complex Logic**: For state machines, data flows, or multi-step processes, you MUST provide a visual diagram (Mermaid/Draw.io) in the Functional Spec or Implementation Plan.
- **Skill Usage**: Use `drawio-diagrams` skill to generate and embed these diagrams.
- **Editable Source**: Always provide the `open_drawio_mermaid` call for future editing.

---

## 5. Dependency Management Protocol

### The "No Blind Upgrades" Rule
- **Rule**: Never run `flutter pub upgrade` or `dotnet update` blindly.
- **Context**: Upgrading core packages (like `connectivity_plus`, `go_router`, `flutter_secure_storage`) often introduces massive breaking changes (e.g., Android Gradle Plugin bumps, Jetpack Security rewrites) that destroy the build.
- **Action**: All major dependency version bumps MUST be treated as architecture-level features (Track C). They require a dedicated ATDD branch, rigorous isolated testing, and a functional specification document outlining the breaking changes.
