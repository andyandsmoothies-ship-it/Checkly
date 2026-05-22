<latent_space_scratchpad>
We are splitting `template_list_page.dart` (378 lines) to maintain clean architectural lines and stay under the 400-line limit.
We will use a `part` and `part of` pattern.
This allows us to write an extension `_TemplateListLogic` on `_TemplateListPageState` in `template_list_page_logic.dart`.
This extension will have direct access to all private state variables like `_search`, `_filter`, and the manager instance without complex callbacks or boilerplate.
Edge cases to watch:
1. Ensure the parent file imports remain fully intact so they cover types used by the part file.
2. The part file must not contain any imports or package directives (except `part of`).
3. Ensure no disruption to list filter updates and search input states.
4. Run RBAC tests to ensure FAB context menus and permission guards still work seamlessly.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `lib/features/templates/pages/template_list_page.dart`

## Executive Summary & Out of Scope
The `template_list_page.dart` file currently has 378 lines. By splitting it, we decouple the page layout/building logic from the sorting, filtering, and menu presentation helper methods.
- **In Scope**:
  - Extract list-filtering logic, grouping algorithms, retry counters, and the FAB context menu builder into `template_list_page_logic.dart`.
  - Reference `template_list_page_logic.dart` as a part file of `template_list_page.dart`.
  - Guarantee that the refactored code compiles clean and passes existing test assertions.
- **Out of Scope**:
  - Rewriting custom list card widgets (`TemplateCard`, `WarmChip`, `TypeSection`).
  - Editing routing configurations or other page targets.
  - Adding new search queries or search endpoints.

## System Context
- **Offline/Online**: Offline-first. Calls `TemplateManager.loadTemplates()` which retrieves cached lists and schedules synchronization.
- **APIs**: Reads list state from `TemplateManager`.
- **RBAC**: Triggers capability validations using the global `PermissionGuard` against `AppCapabilities.templatesCreate`.
- **Logs**: Standard console output.

## Lifecycle Context
- **Success State**: Displays search results and grouped list headers.
- **Error State**: Displays detailed error code message with an interactive `Retry` button on failure.
- **Empty State**: Shows category headers without cards if no matching templates exist.
- **Loading State**: Displays standard `CircularProgressIndicator` when `manager.isLoading.value` is true.

## Constraint Traceability
| Constraint | Source File / Rule | Test Contract ID | Description |
|---|---|---|---|
| Max 400 lines per file | GEMINI.md / global rules | TC-SIZE-01 | Splitting files to stay well under the line-count limits |
| Part-file compilation | Dart SDK specs | TC-COMP-01 | Verifies that parent file uses `part` and part file uses `part of` correctly |
| Functional parity | Codebase behavior | TC-TEST-01 | Asserts that list/RBAC widgets still pass validation tests |

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-SIZE-01 | Verify `template_list_page.dart` has < 250 lines | Static check | Fails if the file remains at 378 lines or gets larger |
| TC-COMP-01 | Run `rtk flutter analyze` to verify compilation | Compile check | Fails if syntax errors are present |
| TC-TEST-01 | Run `rtk flutter test test/features/templates/template_list_page_rbac_test.dart` and `test/ui_gaps_test.dart` | Compile check | Fails if FAB is visible to non-admins or search breaks |

## Test Fixture & Payloads
Since this is a structural refactor, we rely on the existing tests in `test/features/templates/template_list_page_rbac_test.dart`.

## Tools & Commands
- **Required Skills**: `flutter-architecture`, `clean-architecture`
- **Commands to run**:
  - Test command 1: `rtk flutter test test/features/templates/template_list_page_rbac_test.dart`
  - Test command 2: `rtk flutter test test/ui_gaps_test.dart`
  - Analyze command: `rtk flutter analyze`

## Proposed Changes
| Status | File Path | Description |
|---|---|---|
| `[MOD]` | `lib/features/templates/pages/template_list_page.dart` | Keep imports and UI layout (build, Scaffold, ListView). Declare `part 'template_list_page_logic.dart';` |
| `[NEW]` | `lib/features/templates/pages/template_list_page_logic.dart` | Declare `part of 'template_list_page.dart';`. Move extension methods `_showCreateMenu`, `_filtered`, `_groupedByType`, `_countByFilter` here |

## Concept Diagram
```text
           [template_list_page.dart] (Main UI Page)
              ├── Imports & Main Widget Declarations
              ├── _TemplateListPageState variables, initState
              ├── build() UI Layout & appBar / search input / list view
              └── [part 'template_list_page_logic.dart';]
                               │
                               ▼
        [template_list_page_logic.dart] (Part of Main Page)
              ├── [part of 'template_list_page.dart';]
              └── extension _TemplateListLogic on _TemplateListPageState:
                   ├── _showCreateMenu()
                   ├── _filtered (getter)
                   ├── _groupedByType (getter)
                   └── _countByFilter()
```

## Execution Slices (Micro-Specs)

### Execution Phase: Structural Split
- **Plain English Summary**: We will create `template_list_page_logic.dart`, add the `part of` directive, move sorting, filtering, and context menu methods to an extension on `_TemplateListPageState`, reference it via `part` inside `template_list_page.dart`, and delete the moved methods from `template_list_page.dart`.
- **Value Delivered**: Ensures compliance with the 400-line maximum file size rule, improves code scannability, and keeps logic separated from the UI presentation layer.
- **Entry State Required**: File `template_list_page.dart` exists with 378 lines. Code compiles with zero analyzer warnings.
- **Exit State Guaranteed**: Code compiles and analyzes with zero warnings. Both files are under 250 lines. All tests in both test targets pass successfully.
- **Acceptance Criteria**:
  1. `template_list_page.dart` has `< 250` lines.
  2. `template_list_page_logic.dart` has `< 150` lines.
  3. `rtk flutter analyze` passes with zero errors/warnings.
  4. `rtk flutter test test/features/templates/template_list_page_rbac_test.dart` passes.
  5. `rtk flutter test test/ui_gaps_test.dart` passes.

---

### Complexity: Low
This is a low-complexity refactoring task. The `part`/`part of` language-level feature guarantees compiler-enforced variable scoping and zero runtime performance overhead.

---

### Pros & Cons of the Split Pattern
- **Pros**:
  - Direct access to private states (`_search`, `_filter`, etc.) without boilerplate or state management overrides.
  - Zero refactoring impact on other classes or pages.
  - File size drops by ~40% for the main UI file.
- **Cons**:
  - Tight coupling between the two files remains (by design of Dart part-files).

<command_logs>
- `rtk flutter test test/features/templates/template_list_page_rbac_test.dart`
- `rtk flutter test test/ui_gaps_test.dart`
- `rtk flutter analyze`
</command_logs>

## Handoff Block
Next Phase: **Build Phase** for Execution Phase.
Input: `docs/architecture/implementation_plan_20260522_161100_tls1_template_list_split.md`
Action Sequence:
1. Create `lib/features/templates/pages/template_list_page_logic.dart` and populate it with `part of 'template_list_page.dart';` and the `_TemplateListLogic` extension.
2. Edit `lib/features/templates/pages/template_list_page.dart` to add `part 'template_list_page_logic.dart';` at line 14, and remove the moved logic methods.
3. Verify compilation, run code analysis (`rtk flutter analyze`), and run tests.

## Risk Assessment
- **Structural Integrity**: Low risk. Dart part-files share the exact scope, so there's no risk of scope leaks or private field access failures.
- **Dependency Scope**: Zero risk. No external packages are installed or altered.
- **Performance Impact**: Zero risk. Pure compilation grouping without runtime overhead.

## Verification Plan
- **Verification Step 1**: Run `rtk flutter analyze` to verify the refactored code has zero compiler issues.
- **Verification Step 2**: Run `rtk flutter test test/features/templates/template_list_page_rbac_test.dart` to verify template list state/models and RBAC capabilities still function perfectly.
- **Verification Step 3**: Manually verify file lines count for both files to confirm compliance.
