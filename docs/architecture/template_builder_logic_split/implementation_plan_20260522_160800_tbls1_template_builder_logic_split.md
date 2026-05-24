<latent_space_scratchpad>
- Dart allows splitting single libraries / classes across multiple 'part' files.
- Each part file must have `part of 'template_builder_page.dart';` at the top.
- The parent file must list all part files using `part 'name.dart';`.
- No actual logic changes or renaming of methods are done, to keep the blast radius to absolute zero.
- This is a safe refactoring that perfectly complies with the 400-line limit constraint.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `lib/features/templates/pages/template_builder_page_logic.dart`

## Executive Summary & Out of Scope
The `template_builder_page_logic.dart` file currently spans 395 lines of code, which is close to the 400-line critical file size threshold set in `GEMINI.md`. Files close to or over this threshold can cause context confusion.

This plan details a safe refactoring that splits `template_builder_page_logic.dart` into three modular, logically isolated `part` files without modifying any underlying business logic or UI bindings:
1. `template_builder_page_logic.dart`: Retains template loading, builder tree/scoring DTO serialization, and HTTP persistence logic (~200 lines).
2. `template_builder_page_validation.dart`: Houses recursive template schema, section-weight sum, and criterion validator methods (~115 lines).
3. `template_builder_page_mutations.dart`: Houses inline list mutation helpers and reactive computed layout state getters (~80 lines).

### Out of Scope
- Modifying UI layout in `template_builder_page.dart`.
- Modifying business logic in `TemplateManager`.
- Changing API serialization contracts.

## System Context
- **Environment**: Client-side (Offline-first / Live Hybrid).
- **APIs**: Atomic serialization via `TemplateManager.saveTemplate`.
- **Dependencies**: Bounded strictly to Dart's `part` and `part of` compilation rules. Shared namespace is `template_builder_page.dart`.

## Lifecycle Context
### 4-State Matrix (Refactored Page Namespace)
| State | Trigger | UI Component | Action |
| --- | --- | --- | --- |
| **Loading** | Initial navigation/fetch | `CircularProgressIndicator` | Renders a standard centered spinner |
| **Empty** | `_sections.isEmpty` | `GhostAddButton` | Interactive empty-state canvas |
| **Validation Error** | Save trigger with invalid rules | `BuilderValidationBanner` | Top banner with specific error feedback |
| **Success** | Save completed | `SnackBar` + `context.pop()` | SnackBar success message and pop navigation |

## Constraint Traceability
| Constraint | Source File | Target Test Contract ID |
| --- | --- | --- |
| Compile compatibility | `template_builder_page.dart` | `TB-REF-COMP-01` |
| Valid layout binding | `template_builder_page.dart` | `TB-REF-COMP-02` |

## Test Contracts

### Compile and Integration Gate Contracts
| Test ID | Description | Input State | Expected Outcome / Action | Why it fails first |
| --- | --- | --- | --- | --- |
| `TB-REF-COMP-01` | Verifies clean compile & existing tests pass | Run `flutter test` | All 16 existing ATDD compiler gate checks remain GREEN | Compiler error if parts misaligned |
| `TB-REF-COMP-02` | Verifies state instantiation | Run widget test instantiation | State loads and disposes without throwing null exceptions | Extension binding fails |

## Test Fixture & Payloads
No special payloads are required. We rely on the existing test suite:
- `test/template_creation_test.dart`

## Tools & Commands
*   **Skill needed**: `flutter-architecture`, `clean-architecture`
*   **Execution command**: `rtk flutter test test/template_creation_test.dart`

## Proposed Changes
We will modify `template_builder_page.dart` and `template_builder_page_logic.dart`, and create two new files.

### [MOD] [template_builder_page.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_builder_page.dart)
Wired part dependencies:
```dart
part 'template_builder_page_logic.dart';
part 'template_builder_page_validation.dart';
part 'template_builder_page_mutations.dart';
```

### [MOD] [template_builder_page_logic.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_builder_page_logic.dart)
Keep only:
- `_loadExistingTemplate()`
- `_buildScoringConfig()`
- `_buildGroupsRecursive()`
- `_buildGroups()`
- `_save()`

### [NEW] [template_builder_page_validation.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_builder_page_validation.dart)
New part file housing:
- `_validate()`
- `_validateGroups()`
- `_scrollToFirstError()`

### [NEW] [template_builder_page_mutations.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/templates/pages/template_builder_page_mutations.dart)
New part file housing:
- `_addSection()`
- `_removeSection()`
- `_addSubSection()`
- `_removeSubSection()`
- `_addCriterionToGroup()`
- `_removeCriterionFromGroup()`
- `_totalPoints`
- `_totalDensity`

---

## Concept Diagram

```
         [template_builder_page.dart]
                      │
        ┌─────────────┼─────────────┐
        │             │             │
     [part]        [part]        [part]
        │             │             │
        ▼             ▼             ▼
  [..._logic]   [..._validation] [..._mutations]
```

---

## Execution Slices (Micro-Specs)

### Slice 1: Splitting and Validating Page Logic
*   **Summary**: Split the logic file into three distinct part files and compile-gate them.
*   **Value Delivered**: Instantly decreases file sizes from 395 lines to <=200 lines, ensuring clean and maintainable logic containers while satisfying standard file size constraints.
*   **Complexity**: Low. Safe refactoring of part declarations.
*   **Entry State**: `template_builder_page_logic.dart` has 395 lines.
*   **Exit State**: Three separate Dart part files under 200 lines compile and pass tests perfectly.
*   **Acceptance Criteria**:
    - All tests pass when running `rtk flutter test test/template_creation_test.dart`.
    - No changes in core user flows or logic functions.

---

## Risk Assessment
- **Risk 1: Dart Part File Compilation Separation**
  - **Context**: Incorrect part-of / part declarations will break compilation globally in templates.
  - **Mitigation**: Strictly match filenames and part declarations exactly. The file `template_builder_page.dart` must declare all three part files, and all three part files must declare `part of 'template_builder_page.dart';`.

## Verification Plan
### Automated Tests
Run the existing ATDD tests to confirm no regressions are introduced:
```bash
rtk flutter test test/template_creation_test.dart
```

### Static Analysis
Run standard Dart static analysis to verify parts are aligned and no warnings exist:
```bash
rtk flutter analyze
```

---

## Handoff Block
- **Slice 1**: Plan -> Build -> Verify. Run `rtk flutter test test/template_creation_test.dart`.

Plan file path: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260522_160800_tbls1_template_builder_logic_split.md`
