<latent_space_scratchpad>

## Edge Cases to Handle

### Backend
- `user` claims evaluated BEFORE the EF `.Select()` — C# compiler can't infer `bool` from `ClaimsPrincipal` inside a LINQ tree.
- The list endpoint returns `SubmissionDto` (no answers). The detail endpoint returns `SubmissionDetailDto` (with answers). BOTH need `AllowedActions`.
- For the list endpoint (`ListSubmissions`), the EF `.Select()` pattern is already clean — adding one extra ternary is low risk.
- For the detail endpoint (`GetSubmission`), it uses `Include()` + `AsSplitQuery()` then hand-maps the DTO. `AllowedActions` is added in the hand-mapping, not the EF projection.
- Status values currently in use: `draft`, `scheduled`, `in_progress`, `completed`, `finalized`, `voided`. The rules will be:
  - `canFinalize` = user has `submissions:review` AND status is `completed`
  - `canVoid` = user has `submissions:review` AND status NOT IN `voided`, `finalized`
  - `canEdit` = user has `submissions:create` AND status is `draft` OR `scheduled`
  - `canCreate` = user has `submissions:create` (always, no entity-state)

### Flutter
- `SubmissionDto.fromJson` is a long hand-written factory (169 lines). Adding `allowedActions` here is a straightforward list cast from JSON.
- `allowedActions` is `List<String>?` — nullable to signal offline state.
- `ActionGuard` must NOT import from `features/`. It belongs in `_shared/widgets/` next to `PermissionGuard`.
- The `withStatus()` copy method must also propagate `allowedActions`.

### Risk
- `SubmissionDto` has a `withStatus()` method — copy methods must be updated too or `allowedActions` is silently lost.

</latent_space_scratchpad>

# Implementation Plan: Hybrid Entity-Driven UI (Option 2)

**Plan ID**: PBAC02
**Date**: 2026-05-14
**Status**: Ready for Builder

---

## Input Lineage

- **Source ADR**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260514_205137_SYN01_capability_driven_ui.md`
- **Research R1**: `docs\product\research_20260514_203600_PBAC01_capability_ui.md`
- **Research R2**: `docs\product\research_20260514_203551_ARCH_capability_driven_ui.md`

---

## Executive Summary & Out of Scope

### What This Plan Builds
The server will compute exactly which actions a user can perform on a specific Submission right now — based on **both** the user's global role AND the submission's current `status`. This list is sent in every Submission DTO response. The Flutter app uses a new `ActionGuard` widget that reads this list to show or hide action buttons. When offline, `ActionGuard` gracefully falls back to the existing JWT-based `PermissionGuard` logic.

### Terminology Reminder (GEMINI.md Rule)
> "Campaign" in UI business language = "Submission" in the codebase. Do NOT rename any files.

### Out of Scope (YAGNI)
- ❌ Programs (`ProgramSummaryDto`) — static permissions, no volatile state
- ❌ Templates, Stores, Areas, Users — static permissions
- ❌ Full HATEOAS `_links` hypermedia format
- ❌ Changes to GoRouter redirects or `PolicyManager`
- ❌ Changes to `PermissionGuard` widget (it is preserved as-is)
- ❌ Any new Drift table columns or migrations

---

## System Context

| Aspect | Value |
|---|---|
| **Architecture** | Offline-first hybrid (Flutter + ASP.NET Core Minimal API + Drift SQLite) |
| **Online path** | Server computes `allowedActions` in EF projection → returned in DTO |
| **Offline path** | `allowedActions` is `null` in Drift-cached model → `ActionGuard` falls back to JWT capability check |
| **RBAC gates** | `submissions:create`, `submissions:review` are the only capabilities that affect which actions are allowed |
| **Logging** | No new log events needed (existing endpoint-level logs cover it) |
| **Affected endpoints** | `GET /api/submissions` (list), `GET /api/submissions/{id}` (detail) |

---

## Lifecycle Context

### `ActionGuard` Widget — 4-State Matrix

| State | Behaviour |
|---|---|
| **Online + actions available** | Server returns `["edit", "void"]`. `ActionGuard` shows the child widget. |
| **Online + action NOT in list** | Server returns `["view"]`. `ActionGuard` hides the child. `SizedBox.shrink()` rendered. |
| **Offline + fallbackCapability passes** | `actions` is null. `ActionGuard` checks `AuthManager.capabilities`. If user has the fallback cap, shows child. |
| **Offline + fallbackCapability fails** | `actions` is null. User does not have the fallback cap. Widget is hidden. Same as `PermissionGuard` today. |

### Error / Empty States
- No dedicated error state is needed. The widget is purely compositional — it wraps another widget. If the parent widget has an error state, `ActionGuard` is irrelevant.

---

## Test Contracts

| ID | Test Description | Action Key | Entry State | Expected UI |
|---|---|---|---|---|
| TC-01 | User with `submissions:review` opens a `completed` submission | `finalize` | Status=`completed`, user has `submissions:review` | Finalize button visible |
| TC-02 | User with `submissions:review` opens a `finalized` submission | `finalize` | Status=`finalized`, user has `submissions:review` | Finalize button hidden |
| TC-03 | User with `submissions:review` opens a `voided` submission | `void` | Status=`voided`, user has `submissions:review` | Void button hidden |
| TC-04 | User WITHOUT `submissions:review` opens a `completed` submission | `finalize` | Status=`completed`, user lacks `submissions:review` | Finalize button hidden |
| TC-05 | Auditor (has `submissions:create`) opens their own `draft` submission | `edit` | Status=`draft`, user has `submissions:create` | Edit button visible |
| TC-06 | Auditor opens a `finalized` submission | `edit` | Status=`finalized`, user has `submissions:create` | Edit button hidden |
| TC-07 | Flutter — `allowedActions` is null (offline) + fallbackCapability passes | any | `allowedActions = null`, user has fallback cap in JWT | Button visible (offline fallback) |
| TC-08 | Flutter — `allowedActions` is null (offline) + fallbackCapability fails | any | `allowedActions = null`, user lacks fallback cap | Button hidden |
| TC-09 | Flutter — `allowedActions` is empty list `[]` | any | `allowedActions = []` | Button hidden (explicit deny) |
| TC-10 | `SubmissionDto.withStatus()` copy — `allowedActions` is propagated | — | Existing DTO with `allowedActions = ["edit"]` | Copied DTO also has `["edit"]` |

---

## Test Fixture & Payloads

### Required Seeded Fixtures
- A user seeded with `submissions:review` capability  
- A user seeded WITHOUT `submissions:review` capability  
- Submissions seeded in statuses: `draft`, `scheduled`, `completed`, `finalized`, `voided`

### API Payload — `GET /api/submissions` (List)
```json
// Response item — user has submissions:review, submission status = completed
{
  "id": "abc-123",
  "status": "completed",
  "allowedActions": ["view", "finalize", "void"],
  ...
}

// Response item — same user, submission status = finalized
{
  "id": "def-456",
  "status": "finalized",
  "allowedActions": ["view"],
  ...
}
```

### API Payload — `GET /api/submissions/{id}` (Detail)
```json
// User has submissions:create, submission status = draft (own submission)
{
  "id": "abc-123",
  "status": "draft",
  "allowedActions": ["view", "edit", "void"],
  "answers": [...]
}
```

### Defined Action Key Constants

| Dart constant | C# constant | Key string | Meaning |
|---|---|---|---|
| `SubmissionActions.view` | `SubmissionActions.View` | `"view"` | Always included |
| `SubmissionActions.edit` | `SubmissionActions.Edit` | `"edit"` | Modify a draft/scheduled submission |
| `SubmissionActions.finalize` | `SubmissionActions.Finalize` | `"finalize"` | Finalize a completed submission |
| `SubmissionActions.voidAction` | `SubmissionActions.Void` | `"void"` | Void an active submission |

---

## Tools & Commands

### Skills the Builder MUST Load
- `/skills/tdd/SKILL.md` — for backend integration tests
- `/skills/flutter-api/SKILL.md` — for `ActionGuard` widget design

### Test Commands
```powershell
# Backend integration tests (run from server/ directory)
rtk dotnet test

# Flutter unit tests (run from lib/ parent directory)
rtk flutter test test/unit/widgets/action_guard_test.dart
```

---

## Proposed Changes

| Status | File | Reason |
|---|---|---|
| [MOD] | `server/Features/Submissions/Dtos.cs` | Add `List<string> AllowedActions` to `SubmissionDto` and `SubmissionDetailDto` |
| [NEW] | `server/Features/Submissions/SubmissionActions.cs` | New static class with `const string` action key constants |
| [MOD] | `server/Features/Submissions/ListSubmissions.cs` | Evaluate claims before query, inject `AllowedActions` in `.Select()` |
| [MOD] | `server/Features/Submissions/GetSubmission.cs` | Compute `AllowedActions` in the hand-mapping after entity load |
| [MOD] | `lib/features/audit/model/submission_dto.dart` | Add `allowedActions` field + update `fromJson` + update `withStatus()` copy |
| [NEW] | `lib/_shared/widgets/action_guard.dart` | New `ActionGuard` widget (next to `PermissionGuard`) |
| [NEW] | `lib/_shared/constants/submission_actions.dart` | Dart `SubmissionActions` static const class (mirrors C# constants) |

---

## Concept Diagram

```
[GET /api/submissions]
       |
       | user claims evaluated BEFORE query
       |  bool canFinalize = user.HasClaim(AppCapabilities.SubmissionsReview);
       |  bool canEdit     = user.HasClaim(AppCapabilities.SubmissionsCreate);
       |
       v
[EF .Select() Projection]
       |
       |  AllowedActions = new[] { "view" }
       |    .Concat(canEdit && (s.Status=="draft"||s.Status=="scheduled") ? ["edit"] : [])
       |    .Concat(canFinalize && s.Status=="completed" ? ["finalize"] : [])
       |    .Concat(canFinalize && s.Status!="voided" && s.Status!="finalized" ? ["void"] : [])
       |    .ToList()
       v
[SubmissionDto with allowedActions: ["view","finalize","void"]]
       |
       v
[Flutter: submission_dto.dart fromJson]
       |  allowedActions = (json['allowedActions'] as List?)?.cast<String>()
       v
[ActionGuard Widget]
       |
  [Online?] YES → check actions.contains(requiredAction)
       |
  [Online?] NO  → check AuthManager.capabilities.contains(fallbackCapability)
       |
  [pass] → show child widget
  [fail] → show SizedBox.shrink()
```

---

## Execution Slices

This plan spans the backend API and Flutter UI. Per the **Maximum Thickness Rule**, it is split horizontally into two phases.

---

### Phase A — Backend: `AllowedActions` in Submission DTOs

**Complexity**: Medium — touches 4 C# files but the logic is simple ternaries.

**Plain English Summary**: The server learns to calculate and send the list of allowed actions for each Submission. This is the "brains" of the feature. The Flutter app can't do anything new until this data is in the API response.

**Why this step first?**: The Flutter widget reads from the DTO. If the DTO does not have `allowedActions`, the widget has nothing to consume. Backend comes first.

**Scenario Focus**: Basic Scenario (Happy Path)

**Value Delivered**: `GET /api/submissions` and `GET /api/submissions/{id}` both return `"allowedActions": [...]` in every response. A developer can verify this with Postman before touching Flutter.

**Entry State Required**:
- `dotnet build` passes with zero errors/warnings.
- No existing tests are failing.

**Exit State Guaranteed**:
- `dotnet test` passes. All new backend integration tests pass (TC-01 through TC-06).
- `SubmissionDto` and `SubmissionDetailDto` both include `AllowedActions` in their JSON response.
- `AllowedActions` is computed inside the EF `.Select()` for ListSubmissions. No N+1.
- `AllowedActions` is computed in hand-mapping for GetSubmission (entity is already in memory).

**Architectural Scope**:
- `server/Features/Submissions/Dtos.cs` — Add field
- `server/Features/Submissions/SubmissionActions.cs` — New constants file
- `server/Features/Submissions/ListSubmissions.cs` — EF projection update
- `server/Features/Submissions/GetSubmission.cs` — Hand-mapping update

**Pros & Cons**
| | Pros | Cons |
|---|---|---|
| EF inline ternary | No N+1, EF translates to SQL, single query | Logic is in-line, harder to unit test in isolation |
| Post-query mapping | Easier to unit test, logic is in a pure function | Could become a service-layer loop if misused |
> **Decision**: Use EF inline ternary for `ListSubmissions`. Use post-query mapping for `GetSubmission` (already loads entity into memory via `Include()`). This is the existing pattern in each file — match it.

**Acceptance Criteria** (Test Contract):
| Test | Method | Input | Expected |
|---|---|---|---|
| TC-01 | `GET /submissions` | User=reviewer, status=`completed` | `allowedActions` contains `"finalize"` |
| TC-02 | `GET /submissions` | User=reviewer, status=`finalized` | `allowedActions` does NOT contain `"finalize"` |
| TC-03 | `GET /submissions` | User=reviewer, status=`voided` | `allowedActions` does NOT contain `"void"` |
| TC-04 | `GET /submissions` | User=no-reviewer, status=`completed` | `allowedActions` does NOT contain `"finalize"` |
| TC-05 | `GET /submissions/{id}` | User=creator (own), status=`draft` | `allowedActions` contains `"edit"` |
| TC-06 | `GET /submissions/{id}` | User=creator, status=`finalized` | `allowedActions` does NOT contain `"edit"` |

---

### Phase B — Flutter: `ActionGuard` Widget + DTO Update

**Complexity**: Medium — new widget + DTO update. No new state management needed.

**Plain English Summary**: Flutter reads the new `allowedActions` list from the API and uses the new `ActionGuard` widget to show or hide buttons. It also handles the offline case cleanly by falling back to the user's JWT capability.

**Why this step second?**: Phase A must be complete so Phase B has a real API to test against. The `ActionGuard` widget can be built in isolation (widget unit test), but integration testing requires Phase A.

**Scenario Focus**: Basic Scenario + Extension (offline fallback)

**Value Delivered**: Submission action buttons (Finalize, Void, Edit) are dynamically shown or hidden based on entity state. When offline, the app falls back gracefully with no user-visible disruption.

**Entry State Required**:
- Phase A is complete and `GET /api/submissions` returns `allowedActions` in responses.
- `flutter test` currently passes with zero errors.

**Exit State Guaranteed**:
- `flutter test test/unit/widgets/action_guard_test.dart` passes all 4 widget unit tests (TC-07, TC-08, TC-09, TC-10).
- `SubmissionDto.allowedActions` is populated from JSON. `withStatus()` propagates it.
- `ActionGuard` widget is in `lib/_shared/widgets/`. It is NOT imported by any `features/` code yet — that wiring happens in Slice 3 (future).
- `PermissionGuard` is NOT modified.

**Architectural Scope**:
- `lib/features/audit/model/submission_dto.dart` — Add field, update `fromJson`, update `withStatus()`
- `lib/_shared/widgets/action_guard.dart` — New widget
- `lib/_shared/constants/submission_actions.dart` — New constants file

**Pros & Cons (ActionGuard internals)**
| | Pros | Cons |
|---|---|---|
| `ValueListenableBuilder` (same as `PermissionGuard`) | Reactive to auth changes, consistent pattern | Slightly more boilerplate |
| Simple `StatelessWidget` | Minimal code, easy to read | Does not react to auth changes at runtime (acceptable for this widget) |
> **Decision**: Use `StatelessWidget` for `ActionGuard`. The `actions` list comes from the DTO (a snapshot). It doesn't need to react to live `AuthManager` changes on its own — the parent page rebuilds when the DTO changes. Only the offline fallback path needs to check `AuthManager`, which is a simple synchronous call. Keeps the widget simple.

**Acceptance Criteria** (Test Contract):
| Test | Input | Expected |
|---|---|---|
| TC-07 | `actions=null`, user has fallbackCapability | Child widget rendered |
| TC-08 | `actions=null`, user lacks fallbackCapability | `SizedBox.shrink()` rendered |
| TC-09 | `actions=[]` (empty list) | `SizedBox.shrink()` rendered (explicit deny, no fallback) |
| TC-10 | `SubmissionDto(allowedActions: ["edit"]).withStatus("draft")` | Copied DTO `allowedActions == ["edit"]` |

---

<command_logs>

```
# No terminal commands were required for this analysis phase.
# The following would be run by the Builder after implementation:

# Backend build check
cmd /c "rtk dotnet build"

# Backend test
cmd /c "rtk dotnet test"

# Flutter test
cmd /c "rtk flutter test"
```

</command_logs>

---

## Handoff Block

### Summary for Next Agent

This plan implements **Option 2 — Hybrid Entity-Driven UI** as decided in ADR `SYN01`. The feature adds `AllowedActions` to `SubmissionDto` and `SubmissionDetailDto` in the ASP.NET Core backend, computes this array inside EF Core projections based on user claims + entity status, and creates a new `ActionGuard` Flutter widget that reads from this list with a clean offline fallback.

**The two phases are sequential — Phase B cannot start until Phase A is complete.**

### Critical Constraints (Do NOT Ignore)
- 🔴 Claims MUST be evaluated to `bool` variables **before** the `.Select()` lambda — C# cannot translate `ClaimsPrincipal` method calls inside LINQ trees.
- 🔴 `AllowedActions` is NOT added to any Drift table. It is a transient field.
- 🔴 `SubmissionDto.withStatus()` MUST be updated to propagate `allowedActions` or it will be silently dropped on copy.
- 🟡 `ActionGuard` lives in `lib/_shared/widgets/` — not inside `features/`.
- 🟡 `PermissionGuard` is NOT modified. It remains valid for all existing use cases.

### Routing Commands (Run ONE AT A TIME)

**Phase A — Backend (Integration Tests First)**
```
@[/atdd] Execute specs for Phase A — Backend AllowedActions: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md
```

**Phase B — Flutter (TDD for Widget, then Build)**
```
@[/tdd] Execute tests for Phase B — ActionGuard Widget: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md
```

**Phase B (after tests pass)**
```
@[/implement] Execute build for Phase B — Flutter DTO + ActionGuard: C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260514_223612_PBAC02_hybrid_entity_ui.md
```

> **Concurrency Rule**: Phase B slices are independent of each other (`action_guard.dart` widget and `submission_dto.dart` update can be built in parallel). But Phase B as a whole must wait for Phase A to be COMPLETE.
