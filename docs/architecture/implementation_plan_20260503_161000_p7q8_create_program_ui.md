# Implementation Plan: Create Program UI (Wizard)

<latent_space_scratchpad>
## Key Discoveries from Code Audit

**Critical finding 1 — StoreSelectorPage is NOT reusable:**
The existing `StoreSelectorPage` is single-select (taps directly navigate to `/audit`). It CANNOT be reused as a multi-select for programs. We need a new `ProgramStoreSelectorPage` that: (a) shows checkboxes, (b) has a "Done (N selected)" button, and (c) returns the selected store IDs to the wizard state.

**Critical finding 2 — `programs:create` capability doesn't exist in Flutter:**
`AppCapabilities.dart` has no `programsCreate` constant. We must add one. The server-side `AppCapabilities.cs` already has it. The router guard for `/programs/new` must use this.

**Critical finding 3 — ProgramApiService needs createProgram():**
The `ProgramApiService` (174 lines) currently has: `getPrograms`, `getProgramAssignments`, `getProgramSummary`. We add `createProgram`. File will grow ~20 lines, stays under 400.

**Critical finding 4 — Wizard state must NOT go through get_it global scope:**
The ADR's #1 strict constraint says: "MUST use an in-memory CreateProgramManager." Per GEMINI.md "Keep It Simple", a simple `StatefulWidget`-level state object is actually sufficient for a 4-step wizard that only lives for the duration of the flow. We do NOT need to register this in get_it at all — it's transient wizard state, not application state.

**Critical finding 5 — Template selection:**
The wizard needs to show templates. `TemplateManager` is already registered in DI globally. We can `di<TemplateManager>().loadTemplates()` from within the wizard, same pattern as how `StoreSelectorPage` calls `di<StoreManager>().loadStores()`.

**Wizard State Design (in-memory, in widget tree):**
```
class _ProgramDraft {
  String title = '';
  String category = '';
  DateTime? deadline;
  String? templateId;
  String? templateTitle;
  List<String> storeIds = [];
}
```
Hold this as a single field on `ProgramCreateWizardPage`'s `State`. Pass it to each step widget. Simple. No `get_it`. No memory leak.

**Navigation Architecture:**
- Wizard itself is a GoRouter route: `/programs/new`
- Store picker is a sub-route: `/programs/new/stores` 
- OR we use `Navigator.push` (non-GoRouter) to overlay the store picker on top of the wizard, then use `Navigator.pop(result)` returning `List<String>` IDs. Since this is in-wizard state (not cross-page), the list of IDs stays small relative to a `Navigator.pop` result — and it won't be passed through URL params. This is safe because it's a `Navigator.pop` within the same memory space (no Android Binder).

**Template Picker:**
A simple `BottomSheet` with a `ListView` of template tiles. Tap one → closes the sheet → wizard step updates. No new route needed.

**Route Guard for /programs/new:**
We add to `app_router.dart` the same guard pattern as `/templates/wizard`:
- Requires `AppCapabilities.programsCreate` capability.

**App Capabilities — double-checking server:**
Server's `AppCapabilities.cs` has `ProgramsCreate = "programs:create"`. We mirror this in Flutter's `app_capabilities.dart`.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_151520_synth_program_ui.md`

---

> [!WARNING]
> **Blast Radius Note:** `app_router.dart` (323 lines) and `app_capabilities.dart` are shared infrastructure. Edits are minimal and surgical — one new `GoRoute` entry and one new `static const` — but these files affect all users.

---

## Executive Summary & Out of Scope

**Goal:** Let HQ users create and issue a new campaign (Program) from the `ProgramListPage` by tapping a FAB. A 3-step wizard collects: (1) Info (Title, Category, Deadline), (2) Template selection, (3) Store selection. On "Issue", calls `POST /api/programs`.

**Out of Scope (YAGNI):**
- No "Select All" bulk store selection (future scope).
- No offline support — this is a live-API, online-only HQ action.
- No backend changes — the endpoint already exists.
- No `get_it` scope push — wizard state is transient, not app state.
- No editing an existing program (a separate future feature).
- No server-side validation changes.

---

## System Context
- **Mode:** Online-only (HQ action — requires network).
- **API Endpoint:** `POST /api/programs` → `CreateProgramRequest(TemplateId, StoreIds[], Deadline, Category, Title)` → `201 Created` with `{ programId, assignmentCount }`.
- **RBAC:** Requires `programs:create` capability (mirrors server `AppCapabilities.ProgramsCreate`). Must be added to `AppCapabilities.dart` and used in the router guard.
- **Logging:** No special audit trail needed on Flutter side — the backend already logs `program_created` in `CreateProgram.cs`.

---

## Lifecycle Context (4-State Matrix)

### `ProgramCreateWizardPage`
| State | UI Behavior |
|-------|-------------|
| **Loading (submitting)** | "Issue Program" button disabled, shows `CircularProgressIndicator` inside button. Full-screen overlay is NOT needed — button-level loading is sufficient for a single API call. |
| **Empty (no stores selected)** | "Issue Program" button on Step 3/Review is disabled. Shows inline validation message: "Select at least 1 store." |
| **Error (API failure)** | Snackbar: "Could not create program. Please try again." Button re-enables. |
| **Success (201 Created)** | Wizard pops. `ProgramListPage` calls `_load()` to refresh the list. Snackbar on `ProgramListPage`: "Program issued to N stores." |

### `ProgramStoreSelectorPage` (new, multi-select)
| State | UI Behavior |
|-------|-------------|
| **Loading** | `CircularProgressIndicator` in center. |
| **Empty** | "No stores found." text. |
| **Error** | Error banner + "Retry" button. |
| **Success** | ListView with checkboxes. Count badge in AppBar ("3 selected"). |

---

## Test Contracts

| ID | Test Name | Scenario | Why It Fails First |
|----|-----------|----------|--------------------|
| TC-01 | `createProgram posts correct payload` | `ProgramApiService.createProgram()` called with valid args → Dio receives `POST /programs` with correct JSON body | Method doesn't exist yet |
| TC-02 | `createProgram throws on non-2xx` | DioException with 400 → method propagates exception | Method doesn't exist yet |
| TC-03 | `programsCreate constant exists` | `AppCapabilities.programsCreate == 'programs:create'` | Constant missing |
| TC-04 | `wizard Issue button disabled with no stores` | No stores selected → "Issue Program" button is disabled | Button not built yet |
| TC-05 | `wizard Issue button disabled with no deadline` | No deadline set → "Issue Program" button disabled | Button not built yet |
| TC-06 | `wizard Issue button disabled with empty title` | Title empty → "Issue Program" button disabled | Button not built yet |
| TC-07 | `store selector returns selected IDs` | Tap 2 stores, tap "Done" → `Navigator.pop` returns `['id1', 'id2']` | Page not built yet |
| TC-08 | `wizard calls createProgram on Issue` | Tap "Issue Program" → `ProgramApiService.createProgram` invoked with wizard state | Service method missing |

---

## Test Fixture & Payloads

**Required Test Fixture State:** `ProgramApiService` requires a mocked `Dio` instance. No database seeding needed.

**Sample API Request (POST /api/programs):**
```json
{
  "templateId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "storeIds": [
    "a1b2c3d4-...",
    "e5f6a7b8-..."
  ],
  "deadline": "2026-06-30T23:59:59Z",
  "category": "Hygiene",
  "title": "Q2 Hygiene Blitz"
}
```

**Sample API Response (201 Created):**
```json
{
  "programId": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
  "assignmentCount": 2
}
```

---

## Tools & Commands

**Skills needed for Builder:**
- `flutter-architecture` (Manager + Command pattern)
- `interaction-design` (multi-step wizard, loading states)

**Test commands:**
```powershell
# Unit tests only (fast — no emulator needed)
cmd /c rtk flutter test test/features/programs/
```

---

## Proposed Changes

| Action | File | Reason |
|--------|------|--------|
| `[MOD]` | `lib/_shared/constants/app_capabilities.dart` | Add `programsCreate = 'programs:create'` constant |
| `[MOD]` | `lib/features/programs/services/program_api_service.dart` | Add `createProgram(...)` method |
| `[MOD]` | `lib/features/programs/pages/program_list_page.dart` | Add FAB wired to `/programs/new` route |
| `[MOD]` | `lib/_shared/router/app_router.dart` | Add `/programs/new` route + capability guard |
| `[NEW]` | `lib/features/programs/pages/program_create_wizard_page.dart` | Multi-step wizard (Info → Template → Stores → Review) |
| `[NEW]` | `lib/features/programs/pages/program_store_selector_page.dart` | Multi-select store picker (returns `List<String>` IDs) |
| `[NEW]` | `test/features/programs/program_api_service_test.dart` | Unit tests for `createProgram` method |

---

## Concept Diagram

```
[ProgramListPage]
     | FAB tap
     v
[/programs/new] — guarded by programs:create capability
     |
[ProgramCreateWizardPage] — holds _ProgramDraft state in widget
     |
     |-- Step 1: Info Form (Title, Category, Deadline)
     |-- Step 2: Template Picker (BottomSheet over TemplateManager.templates)
     |-- Step 3: Stores (push ProgramStoreSelectorPage → pop List<String>)
     |-- Step 4: Review & Issue
          |
          v
     ProgramApiService.createProgram(draft)
          |
          v
     POST /api/programs → 201 Created
          |
          v
     pop wizard → ProgramListPage._load()
```

---

## Execution Slices

### Phase A: Service & Constants
**Complexity: Low** — No new files. Two surgical edits.

**Steps:**
1. `[MOD]` `app_capabilities.dart`: Add `static const programsCreate = 'programs:create';`. Also add it to `adminDomainCapabilities` set so it gets the implicit admin grant.
2. `[MOD]` `program_api_service.dart`: Add `createProgram({required String title, required String category, required DateTime deadline, required String templateId, required List<String> storeIds})` method. POSTs to `/programs`. Returns `Map<String, dynamic>` with `programId` and `assignmentCount`.
3. **Write tests first (TC-01, TC-02, TC-03)** → run → confirm RED → implement → confirm GREEN.

**Pros:** Tiny blast radius. Fully testable in isolation. Unblocks Phase B.
**Cons:** None.

---

### Phase B: Wizard & Store Selector UI
**Complexity: Medium** — Two new pages. Wizard state held in-widget. Multi-select store picker uses existing `StoreManager`.

**Steps:**
1. `[NEW]` `program_store_selector_page.dart`: Full-screen page with search + checkbox `ListView`. AppBar shows "N selected". "Done" button calls `Navigator.pop(context, selectedIds)`. Reads from `di<StoreManager>().stores`.
2. `[NEW]` `program_create_wizard_page.dart`: `StatefulWidget` holding `_ProgramDraft`. Uses a `PageView` or `IndexedStack` for the 4 steps. "Issue Program" button in Step 4 is disabled unless: `title.isNotEmpty && deadline != null && templateId != null && storeIds.isNotEmpty`. On submit: calls `di<ProgramApiService>().createProgram(...)`. On success: `context.pop()`. On error: shows `SnackBar`.
3. `[MOD]` `app_router.dart`: Add `GoRoute(path: '/programs/new', builder: ...)` with an inline capability guard checking `AppCapabilities.programsCreate`.
4. `[MOD]` `program_list_page.dart`: Add `floatingActionButton: FloatingActionButton.extended(label: Text('New Program'), icon: Icon(Icons.add), onPressed: () => context.push('/programs/new'))`. After wizard pops, call `_load()` via a `.then()` on the push future.
5. **Write widget tests (TC-04, TC-05, TC-06, TC-07, TC-08)** → confirm RED → implement → confirm GREEN.

**Pros:** Simple in-widget state, no DI pollution, easy to test.
**Cons:** If the wizard needs to survive app backgrounding, this won't persist state (acceptable for an HQ creation flow — if user backgrounds the app mid-wizard, losing draft is acceptable UX).

**Key Constraint from ADR:** Do NOT pass `storeIds` through GoRouter URL params. Use `Navigator.pop(result)` within the same memory space, which is safe.

---

<command_logs>
- grep_search "programs:create" → Found in server AppCapabilities.cs, server tests, Program.cs. NOT in lib/
- grep_search "ProgramListPage" → Found in app_router.dart, program_list_page.dart
- view_file program_list_page.dart → 139 lines, no FAB, no createProgram call
- view_file program_api_service.dart → 174 lines, no createProgram method
- view_file program_manager.dart → 140 lines, SM offline-first, no HQ create logic
- view_file store_selector_page.dart → 282 lines, single-select only
- view_file app_router.dart → 323 lines, no /programs/new route
- view_file app_capabilities.dart → 40 lines, no programsCreate constant
- view_file locator.dart → ProgramApiService and ProgramManager both registered as LazySingletons
</command_logs>

---

## Handoff Block

- **Final Verdict:** Viable. Two clean phases, no backend changes, no DI scope complexity.
- **Effort:** Track B1 — standard feature. ~4 hours of focused Builder work.
- **Mission Brief:** Add `programsCreate` capability constant, add `createProgram()` to `ProgramApiService`, build a `ProgramCreateWizardPage` (in-widget state) with a matching `ProgramStoreSelectorPage` (multi-select), wire a FAB on `ProgramListPage`, and add the route to the router with a capability guard.

**Step-by-step (run ONE AT A TIME, in order):**

**Step 1 — Unit tests for Service & Constants first:**
> `/tdd` Execute tests for Phase A — Service & Constants: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

**Step 2 — Build Service & Constants:**
> `/implement` Execute build for Phase A — Service & Constants: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

**Step 3 — Build Wizard UI (after Step 2 is GREEN):**
> `/implement` Execute build for Phase B — Wizard & Store Selector UI: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_161000_p7q8_create_program_ui.md`

**Concurrency:** Phase B is BLOCKED on Phase A. Steps 1 → 2 → 3 are strictly sequential.

---

## Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `app_router.dart` edit introduces regression in existing route guards | Low | High | Add the new route at the correct position in the file. Keep the existing `authRedirect` logic untouched. The guard for `/programs/new` is a simple inline `redirect` call matching the templates pattern. |
| `StoreSelectorPage` is accidentally modified instead of creating a new page | Low | Medium | Create a *new* file: `program_store_selector_page.dart`. Do NOT touch `store_selector_page.dart`. |
| `ProgramApiService` grows too large | Low | Low | Currently 174 lines. Adding `createProgram` will bring it to ~195 lines. Well under the 400-line limit. No split needed. |
| Double-submit if user taps "Issue" twice | Low | Medium | Button is disabled on `isSubmitting == true`. The boolean flag is set before the async call and cleared in `finally`. |

---

## Verification Plan

After Phase A and Phase B are both implemented, run the following to confirm correctness:

```powershell
# 1. Unit tests
cmd /c rtk flutter test test/features/programs/

# 2. Analyze for dead code / compile errors
cmd /c rtk flutter analyze lib/features/programs/ lib/_shared/constants/ lib/_shared/router/
```

**Manual test checklist (hand to user):**
- [ ] Tap FAB on Programs page → Wizard opens.
- [ ] Without `programs:create` capability → `/programs/new` redirects to `/home`.
- [ ] Leave Title blank → "Issue Program" button is disabled.
- [ ] No stores selected → "Issue Program" button is disabled.
- [ ] Set deadline in the past → server returns 400 → snackbar shows error.
- [ ] Fill all fields + pick stores → tap "Issue Program" → button spins → success → wizard closes → Programs list refreshes.

