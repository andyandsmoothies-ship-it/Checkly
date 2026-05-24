# Task: Fix Program Create Wizard UX Issues
Workflow: /analyze-feature | Track: A

## Input Lineage
- **Source Input**: `C:\Users\HP\.gemini\antigravity\brain\838cfcdf-5138-4bb2-b287-8727e68f9a15\ux_heuristic_eval_program_wizard.md.resolved`

## Executive Summary & Out of Scope
Fix the 3 high-priority UX issues in the Program Create Wizard (Step 2):
1. UI Freeze during Template fetch.
2. Silent network errors & dead-end empty states.
3. Missing emergency exit (Close button) in the AppBar.
**Out of Scope**: Refactoring the wizard state management or changing other steps (Store Selection).

## Risk Assessment
- **Risk Level**: Low.
- **Architectural Impact**: Minimal. We are simply handling existing state properties (`isLoading`, `error`) within the UI.
- **Mitigation**: By keeping changes contained within `program_create_wizard_page.dart` and `program_wizard_steps.dart`, we don't affect backend contracts.

## System Context
- **Environment**: Online-only Mobile App.
- **RBAC**: HQ Admin users creating campaigns.

## Lifecycle Context
- **Loading**: `TemplatePicker` shows a `CircularProgressIndicator` while `TemplateManager` fetches data.
- **Empty**: `TemplatePicker` shows actionable copy ("No templates exist yet...").
- **Error**: `TemplatePicker` shows an error message and a "Retry" button.
- **Success**: `TemplatePicker` displays the list of templates.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-01 | "Close button pops wizard" | AppBar shows Close icon. | Icon does not exist. |
| TC-02 | "TemplatePicker shows loading" | `isLoading == true` -> Spinner. | BottomSheet currently waits for network before opening. |
| TC-03 | "TemplatePicker shows error" | `error != null` -> Retry button. | Error is silently ignored. |
| TC-04 | "TemplatePicker shows empty" | `templates.isEmpty` -> Actionable copy. | Shows generic "No templates available". |

## Test Fixture & Payloads
- Mock `TemplateManager` returning empty, error, and delayed success responses.

## Tools & Commands
- **Skills**: `flutter-api`, `flutter-architecture`.
- **Command**: `flutter test`

## Proposed Changes
- `[MOD] lib/features/programs/pages/program_create_wizard_page.dart`:
  - Add `actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(context).pop())]` to the AppBar.
  - Modify `_pickTemplate()` to open the BottomSheet *first*, passing `_templateManager` to it, and triggering `_templateManager.loadTemplates()` asynchronously.
- `[MOD] lib/features/programs/widgets/program_wizard_steps.dart`:
  - Modify `TemplatePicker` to use a `ListenableBuilder` (or `ValueListenableBuilder`) listening to `_templateManager.isLoading`, `error`, and `templates`.
  - Add UI for `isLoading` (Spinner).
  - Add UI for `error` (Error text + Retry button calling `loadTemplates()`).
  - Update `isEmpty` UI text to be actionable.

## Concept Diagram
`[User clicks Template]` --> `[Open BottomSheet]` --> `[Show Spinner]` --> `[Show Templates/Error]`

## Verification Plan
1. Compile the flutter app locally or run flutter tests to verify no compilation issues.
2. Execute the test cases described in the Test Contracts (TC-01 to TC-04).
3. Validate that UI renders the spinner before the network request resolves, and correctly surfaces error strings if the request fails.

## Execution Slices
### Execution Phase
**Complexity**: Low. UI-only modifications handling state representation.
**Pros & Cons**: 
- *Pro*: Vastly improves UX, prevents perceived app freezes.
- *Con*: Requires passing `TemplateManager` down to the `TemplatePicker` widget.

## Handoff Block
The implementation plan is ready. The next agent should implement the UX fixes directly.
`@[/implement] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_172548_a1b2c3d4_program_wizard_ux.md`
