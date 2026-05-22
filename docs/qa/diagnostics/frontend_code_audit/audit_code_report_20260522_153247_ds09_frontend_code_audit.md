# Frontend Code Quality Audit Report (DS09)

This diagnostics report outlines structural health, architectural boundaries, code hygiene, and test coverage findings for the `lib/features/templates` and `lib/features/user_groups` directories.

---

## 1. Severity Matrix

| Finding ID | Target File / Area | Severity | Category | Description |
| :--- | :--- | :--- | :--- | :--- |
| **AUD-01** | `user_groups/` | 🔴 CRITICAL | Coverage Gap | Feature directory has zero widget, manager, or behavioral unit tests. |
| **AUD-02** | `templates/pages/template_builder_page_logic.dart` | 🟡 WARNING | Sizing | File has 395 lines (close to the 400-line Critical threshold). |
| **AUD-03** | `templates/pages/template_wizard_page.dart` | 🟡 WARNING | Sizing | File has 390 lines (combines wizard view and sub-layouts). |
| **AUD-04** | `templates/pages/template_list_page.dart` | 🟡 WARNING | Sizing | File has 378 lines (combines tab selection, lists, and search). |
| **AUD-05** | `templates/widgets/section_editor_parts.dart` | 🟡 WARNING | Class Density & Isolation | Combines 4 private classes with complete private isolation (untestable). |
| **AUD-06** | `templates/widgets/wizard_step_sections_parts.dart` | 🟡 WARNING | Class Density & Isolation | Combines 4 private classes with complete private isolation (untestable). |
| **AUD-07** | `templates/` (Multiple Widgets) | 🔴 CRITICAL | Method Sizing | Multiple `build` methods exceed the 150-line critical threshold (up to 305 lines). |
| **AUD-08** | `templates/` (Multiple Files) | 🟡 WARNING | Code Duplication | Identical recursive payload building and serialization routines across 3 files. |

---

## 2. Findings, Actionable Refactors & Trade-offs

### AUD-01: Zero Behavioral Test Coverage for User Groups
* **Finding**: The `lib/features/user_groups` directory has no widget, manager, or behavioral unit tests. Only one service-level client test exists.
* **Refactor Proposal**: 
  Implement `test/features/user_groups/manager/user_group_manager_test.dart` to cover:
  1. Success state: Fetch user groups and verify manager status changes from loading to success.
  2. Error state: Capture API exceptions and verify status switches to error with blame-free messages.
  3. Actions: Verify adding, updating, and removing groups reactively propagates state.
* **Complexity**: **Medium**. Requires mocking `UserGroupApiService` using `mocktail` and wrapping manager notifications in custom test streams.
* **Trade-offs**:
  * **Pros**: Establishes bulletproof reliability for user-group administration pages.
  * **Cons**: Requires initial setup of mocked API frameworks inside the tests.

---

### AUD-02: Near-Monolithic Template Builder Logic (395 lines)
* **Finding**: `template_builder_page_logic.dart` has 395 lines. It combines dynamic template mappings, form validations, API responses, and node structures.
* **Refactor Proposal**:
  Extract validation rules and mapper calculations into dedicated functional utilities (e.g., `lib/features/templates/pages/widgets/builder_validators.dart`).
* **Complexity**: **Medium**. The validation methods are state-dependent, meaning we need to cleanly extract them while passing proper context.
* **Trade-offs**:
  * **Pros**: Reduces logic file size by ~100 lines, improving clarity and modular testing.
  * **Cons**: Splitting validation splits context, meaning developers must open two files to modify forms.

---

### AUD-03: Heavy Wizard Layout Controller (390 lines)
* **Finding**: `template_wizard_page.dart` has 390 lines. It controls step navigation, visual sub-layouts, and suggestion cards.
* **Refactor Proposal**:
  Extract wizard suggestion cards and starter layouts to independent widgets in `lib/features/templates/widgets/wizard_step_sections_parts.dart`.
* **Complexity**: **Medium**. Requires passing wizard states or step navigation callbacks between parent and child components.
* **Trade-offs**:
  * **Pros**: Simplifies the main Wizard page state and renders components highly reusable.
  * **Cons**: Increases callback parameters and parameter threading across widget trees.

---

### AUD-04: Dense Template List Controller (378 lines)
* **Finding**: `template_list_page.dart` has 378 lines. It manages search terms, empty illustrations, tabs, list views, and RBAC actions.
* **Refactor Proposal**:
  Extract the search header and clean empty states into `lib/features/templates/widgets/template_search_header.dart`.
* **Complexity**: **Low**. Standard stateless/stateful widget extraction.
* **Trade-offs**:
  * **Pros**: Decouples search widget layout from main page list view.
  * **Cons**: Slightly increases feature folder nesting.

---

### AUD-05 & AUD-06: Untestable Private Isolated Classes
* **Finding**: `section_editor_parts.dart` and `wizard_step_sections_parts.dart` declare multiple private helper classes (e.g. `_SectionEditorHeader`, `_WizardSectionProgressHeader`). Because they are private (prefixed with `_`), they cannot be target-asserted in individual widget unit tests.
* **Refactor Proposal**:
  Remove the private underscore `_` prefix, making them public and exposing clean constructor boundaries.
* **Complexity**: **Low**. Simple rename operations.
* **Trade-offs**:
  * **Pros**: Promotes mockability and testability of distinct visual building blocks.
  * **Cons**: Exposes layouts that were originally intended to remain package-private.

---

### AUD-07: Inline Build Methods Exceeding 150 Lines (Method Sizing)
* **Finding**: Multiple widgets contain extremely large nested layout trees inside their `Widget build` methods, severely violating method-length limits and SRP:
  1. `criterion_editor_drawer.dart` (build: **305 lines**)
  2. `advanced_settings_card.dart` (build: **264 lines**)
  3. `template_card.dart` (build: **237 lines**)
  4. `template_list_page.dart` (build: **185 lines**)
  5. `criterion_editor.dart` (build: **167 lines**)
  6. `template_detail_page.dart` (build: **163 lines**)
  7. `wizard_step_structure.dart` (build: **161 lines**)
  8. `review_section_breakdown.dart` (build: **158 lines**)
  9. `template_wizard_page.dart` (build: **154 lines**)
* **Refactor Proposal**:
  Refactor these layout trees by extracting complex visual branches (e.g., custom form cards, header tabs, list-item decorators) into distinct sub-widgets or clean, helper render methods (e.g., `Widget _buildSectionItem()`) within the same directory.
* **Complexity**: **Medium**. Care must be taken to ensure stateless widget extractions do not break layout sizing parameters (like expanded constraints) or context inheritance.
* **Trade-offs**:
  * **Pros**: Improves readability, reduces nesting level, and permits targeted widget tests.
  * **Cons**: Developers need to navigate between smaller widgets to understand the full page layout.

---

### AUD-08: Significant Template Serialization Duplication
* **Finding**: Direct duplication of recursive section/group payload mapping and serialization routines of length **8 to 31 lines** between:
  1. `template_builder_page_logic.dart` (`_buildGroupsRecursive` method, lines 57-135)
  2. `builder_payload_mapper.dart` (`buildGroupsPayload` method, lines 6-87)
  3. `wizard_payload_builder.dart` (`buildGroupsRecursive` method, lines 42-69)
  This introduces significant operational risk of drift when updating serialized template contracts.
* **Refactor Proposal**:
  Unify all group serialization logic by importing and utilizing `builder_payload_mapper.dart`'s `buildGroupsPayload` function across both `template_builder_page_logic.dart` and `wizard_payload_builder.dart`. Delete the duplicated private/inline recursive methods.
* **Complexity**: **Low**. Clean deletion of redundant methods and substituting references with the shared mapper logic.
* **Trade-offs**:
  * **Pros**: Eradicates duplication, establishes a single source of truth for template APIs, and eliminates 100+ lines of duplicate logic.
  * **Cons**: Introduces a minor direct dependency from page-level states/wizards to utility functions (already standard).
