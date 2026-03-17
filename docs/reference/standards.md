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
- **Build**: `flutter analyze` + `flutter test` must pass before handoff

#### Flutter Feature Structure
```
lib/features/[feature]/
├── manager/        # ChangeNotifier state management
│   └── [feature]_manager.dart
├── model/          # DTOs and data classes
│   └── [feature]_dto.dart
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
- **Secrets Protocol**: NO hardcoded keys. Use environment variables exclusively.
- **Validation**: Strict Zod validation for all inputs; sanitize all UI outputs.
- **Error Handling**: Never leak server-side stack traces or internal schema details.

### OWASP Top 10 Adherence
- **A01: Broken Access Control**: Verify RLS on every new table.
- **A03: Injection**: Use parameterized Supabase filters; avoid raw SQL template strings.
- **A01: Auth Failures**: Always use session-based authentication from `AuthProvider`.

### RLS Performance (MANDATORY)
- **InitPlan Rule**: All RLS policies MUST use `(select auth.uid())` instead of bare `auth.uid()`. Same for `auth.role()`. This prevents per-row re-evaluation.
- **Helper Functions**: Wrap args too — `has_role((select auth.uid()), ...)`, `get_user_store_id((select auth.uid()))`.
- **FK Indexes**: Every new foreign key column MUST have a corresponding `CREATE INDEX`. All existing FKs are indexed as of 2026-02-20.

### Database Integrity (Schema Reality)
- **Constraint**: Never assume a column exists.
- **Action**: Always `cat src/integrations/supabase/types.ts` before writing SQL.

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
