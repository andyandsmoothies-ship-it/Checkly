<latent_space_scratchpad>
- Ensure UserGroupManager handles error friendliness properly, covering SocketException, 403, 401, and general errors.
- CreateGroupSheet needs validation testing (name empty, name > 200 characters) and successful submission triggering manager.createGroup.
- UserGroupListPage needs to show Loading (CircularProgressIndicator), EmptyState, ErrorState, and list of UserGroupTile correctly.
- Mocks should use mocktail, matching existing codebase style.
- Clean up GetIt scope properly in widget tests to avoid test leakage.
- Use explicit types, constants, and avoid magic strings where possible.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `lib/features/user_groups/`

## Executive Summary & Out of Scope
This plan details the addition of 100% test coverage for the `user_groups` feature directory in the Flutter client. The `user_groups` feature contains the manager, model, page, and widgets for viewing and creating user groups. Currently, it has zero widget, manager, or behavioral unit tests. 

This change will introduce a comprehensive suite of unit and widget tests that verify the correct behavior of:
- `UserGroupManager` (state machine, loading, error mapping, success, and creation flows)
- `UserGroupListPage` (4-state rendering, FAB trigger, and scroll-to-refresh)
- `CreateGroupSheet` (form validation, saving state, error displays, and pop behavior)
- Supporting components: `UserGroupTile`, `EmptyState`, and `ErrorState`

### Out of Scope
- Backend modifications (only client-side unit and widget tests are within scope).
- Core routing behavior or integration test flows beyond widget-level unit behaviors.

## System Context
- **Environment**: Client-side (offline-capable).
- **APIs**: UserGroupApiService (GET `/user-groups`, POST `/user-groups`).
- **RBAC / Capabilities**: Managed via capability guard checks in pages (requires `users:manage` capability, handled by router, list page is administrative).
- **Dependency Injection**: Registered via `GetIt.instance`. Must be properly isolated and scoped per test run using `GetIt.I.pushNewScope()` and `GetIt.I.popScope()`.

## Lifecycle Context
### 4-State Matrix (UserGroupListPage)
| State | Trigger | UI Component | Action |
| --- | --- | --- | --- |
| **Loading** | `isLoading == true` | `CircularProgressIndicator` | Spinner shown in center |
| **Empty** | `groups.isEmpty` & `error == null` | `EmptyState` | Prominent graphic + 'Create First Group' button |
| **Error** | `error != null` | `ErrorState` | Displays error message + 'Retry' button |
| **Success** | `groups.isNotEmpty` | `ListView.separated` | List of `UserGroupTile` components |

## Constraint Traceability
| Constraint | Source File | Target Test Contract ID |
| --- | --- | --- |
| Group name required | `create_group_sheet.dart` | `UG-WID-CREATE-VAL-01` |
| Group name max 200 chars | `create_group_sheet.dart` | `UG-WID-CREATE-VAL-02` |
| Prepend on create success | `user_group_manager.dart` | `UG-MGR-CREATE-01` |
| 403 maps to permission error | `user_group_manager.dart` | `UG-MGR-ERR-01` |
| 401 maps to expired session | `user_group_manager.dart` | `UG-MGR-ERR-02` |
| Network error mapping | `user_group_manager.dart` | `UG-MGR-ERR-03` |

## Test Contracts

### Manager Behavioral Tests
| Test ID | Description | Input State | Expected Outcome / Action | Why it fails first |
| --- | --- | --- | --- | --- |
| `UG-MGR-INIT-01` | Verify initial manager state | Constructor called | `groups` is empty, `isLoading` is false, `error` is null | Assertion checks |
| `UG-MGR-LOAD-01` | Load groups success flow | API returns groups list | `isLoading` toggles, `groups` populated, listeners notified | Method not verified |
| `UG-MGR-LOAD-02` | Load groups empty flow | API returns empty list | `groups` remains empty, no error set | Empty state check |
| `UG-MGR-ERR-01` | 403 HTTP error mapping | API throws 403 Exception | `error` is 'You do not have permission to manage user groups.' | Generic message check |
| `UG-MGR-ERR-02` | 401 HTTP error mapping | API throws 401 Exception | `error` is 'Your session has expired. Please sign in again.' | Generic message check |
| `UG-MGR-ERR-03` | SocketException error mapping | API throws SocketException | `error` is 'No internet connection. Please try again.' | Generic message check |
| `UG-MGR-CREATE-01` | Create group success flow | Input valid parameters | API creates group, manager prepends to list, returns `true` | Prepend assertion |
| `UG-MGR-CREATE-02` | Create group failure flow | API throws error | `error` updated with friendly error, returns `false` | Error propagation check |

### Widget Tests
| Test ID | Description | Input State | Expected Outcome / Action | Why it fails first |
| --- | --- | --- | --- | --- |
| `UG-WID-LIST-01` | List page loading state | Manager `isLoading == true` | Shows `CircularProgressIndicator`, hides lists | Widget presence check |
| `UG-WID-LIST-02` | List page empty state | Manager `groups.isEmpty` | Shows `EmptyState`, tapping button launches sheet | EmptyState verification |
| `UG-WID-LIST-03` | List page error state | Manager `error != null` | Shows `ErrorState` card, tapping 'Retry' calls `loadGroups` | Error text verification |
| `UG-WID-LIST-04` | List page success list | Manager has 2 groups | Renders list with 2 `UserGroupTile` widgets | Tile count matches |
| `UG-WID-CREATE-01`| Form renders correctly | Bottom sheet open | Title, TextFields, 'Create Group' button exist | Component finding |
| `UG-WID-CREATE-VAL-01`| Validation empty name | Tap submit with empty name | Displays validation error 'Group name is required.' | Form validator |
| `UG-WID-CREATE-VAL-02`| Validation name length | Tap submit with name > 200 | Displays 'Name must not exceed 200 characters.' | Form validator |
| `UG-WID-CREATE-02`| Form submit success | Enter valid input, submit | Triggers manager `createGroup`, pops sheet, shows SnackBar | Navigation assertion |
| `UG-WID-CREATE-03`| Form submit failure | Submit triggers API error | Calls `ErrorDisplayService.show` with manager's error | Service mock capture |
| `UG-WID-TILE-01` | Tile description subtitle | Group with description | Subtitle text widget rendered with exact description | Text widget finding |
| `UG-WID-TILE-02` | Tile no description | Group without description | Subtitle text widget is not rendered | Subtitle find count |

## Test Fixture & Payloads
Mocks needed:
- `MockUserGroupApiService` extending `Mock` implements `UserGroupApiService`
- `MockUserGroupManager` extending `Mock` implements `UserGroupManager`
- `MockErrorDisplayService` extending `Mock` implements `ErrorDisplayService`

Setup requirements:
- Use `mocktail` for stubs and verifications.
- Scoped `GetIt` registrations per test running in `setUp()` and `tearDown()` using `GetIt.instance.pushNewScope()` and `popScope()`.

## Tools & Commands
*   **Skill needed**: `flutter-api`, `testing-strategy`, `ui-visual-validator`
*   **Execution command**: `rtk flutter test test/features/user_groups/`

## Proposed Changes
We will create five new test files matching the exact package paths inside the `test/` directory.

### [NEW] [user_group_manager_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/user_groups/manager/user_group_manager_test.dart)
Behavioral unit tests for the `UserGroupManager`.
- Mocks `UserGroupApiService` to drive all state machines.
- Verifies loading transitions and friendly error conversions.
- Verifies creation prepends items.

### [NEW] [user_group_list_page_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/user_groups/pages/user_group_list_page_test.dart)
Widget test for `UserGroupListPage`.
- Mocks `UserGroupManager` to verify the 4-state lifecycle UI rendering.
- Verifies scroll-to-refresh and FAB sheet triggers.

### [NEW] [create_group_sheet_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/user_groups/widgets/create_group_sheet_test.dart)
Widget test for `CreateGroupSheet`.
- Mocks `UserGroupManager` and `ErrorDisplayService`.
- Verifies validation errors and successful submissions.

### [NEW] [user_group_tile_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/user_groups/widgets/user_group_tile_test.dart)
Widget test for `UserGroupTile`.
- Verifies rendering of name, description, avatar decoration, and `StrokeCard` integration.

### [NEW] [empty_error_states_test.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/test/features/user_groups/widgets/empty_error_states_test.dart)
Combined widget test for `EmptyState` and `ErrorState` components.
- Verifies text outputs and callback execution on tap.

---

## Concept Diagram

```
 [UserGroupListPage]
   ├── isLoading == true  ──> [CircularProgressIndicator]
   ├── error != null      ──> [ErrorState]  ──(Tap Retry)──> Calls loadGroups()
   ├── groups.isEmpty     ──> [EmptyState]  ──(Tap Create)─> Shows CreateGroupSheet
   └── groups.isNotEmpty  ──> [ListView] ───> Renders [UserGroupTile] (uses StrokeCard)
                                                 │
                                           (Tap FAB) ──> Shows [CreateGroupSheet]
                                                             │
                                                       [TextFormField] (Name, Desc)
                                                       [BubblyButton]  ──(Tap)──> Validation
                                                                                     │
                                                                           ┌─────────┴─────────┐
                                                                        [Valid]             [Invalid]
                                                                           │                   │
                                                                 Calls createGroup()     Shows validation error
                                                                           │
                                                                 ┌─────────┴─────────┐
                                                             [Success]           [Failure]
                                                                 │                   │
                                                             Pops sheet;      Calls ErrorDisplayService
                                                            Shows SnackBar
```

## Execution Slices (Micro-Specs)

### Slice 1: Manager Behavioral Unit Tests
*   **Summary**: Add full coverage of the manager layer to secure the core data engine.
*   **Value Delivered**: Confirms that backend responses and failures translate perfectly into clean UI-facing state notifications.
*   **Complexity**: Low. Isolated Dart unit test.
*   **Entry State**: `test/features/user_groups/manager/` directory does not exist.
*   **Exit State**: `user_group_manager_test.dart` covers all initialization, loading, and error states.
*   **Acceptance Criteria**:
    - All tests pass when running `rtk flutter test test/features/user_groups/manager/user_group_manager_test.dart`.
    - initial state verified.
    - load success, load empty, and load errors (403, 401, offline SocketException, standard error) verified.
    - create success (prepends item) and failure verified.

### Slice 2: Widget & Page Component Tests
*   **Summary**: Add UI/UX behavior tests for all page and widget components.
*   **Value Delivered**: Guarantees visual resilience across the 4 state variations, forms, and custom components.
*   **Complexity**: Medium. Requires Flutter `testWidgets` with GetIt dependency injection.
*   **Entry State**: Zero widget tests in `test/features/user_groups/`.
*   **Exit State**: Four complete widget test files passing synchronously.
*   **Acceptance Criteria**:
    - `rtk flutter test test/features/user_groups/` succeeds without compile or runtime errors.
    - `UserGroupListPage` handles Loading, Empty, Error, and Success render trees perfectly.
    - `CreateGroupSheet` performs 200 character validation, handles loading state in submit button, and pops on success.
    - `UserGroupTile`, `EmptyState`, and `ErrorState` cover all interaction vectors.
---

## Risk Assessment
- **Risk 1: Test Pollution and Scoping Leakage**
  - **Context**: Multiple widget tests registering mock services in `GetIt` can conflict and leak states if not properly cleaned up.
  - **Mitigation**: Every widget and page test must use `GetIt.instance.pushNewScope()` inside `setUp()` and `GetIt.instance.popScope()` inside `tearDown()` to guarantee absolute service isolation.
- **Risk 2: API Contract Drift**
  - **Context**: Stubs for API calls in tests can pass while drifting from real backend contracts.
  - **Mitigation**: Stubs must strictly adhere to the schema structures defined in `lib/features/user_groups/services/user_group_api_service.dart`.

## Verification Plan
### Automated Tests
Execute the following verification command to confirm all tests pass successfully:
```bash
rtk flutter test test/features/user_groups/
```

### Static Analysis & Lints
Verify there are no compiler warnings or style violations in our newly added test files:
```bash
rtk flutter analyze
```

---

## Handoff Block
- **Slice 1**: Plan -> Write Unit Tests -> Build. Run `rtk flutter test test/features/user_groups/manager/user_group_manager_test.dart`.
- **Slice 2**: Plan -> Write Widget Tests -> Build. Run `rtk flutter test test/features/user_groups/`.

Please execute the slices one at a time.
Plan file path: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_160300_ds10_user_groups_tests.md`
