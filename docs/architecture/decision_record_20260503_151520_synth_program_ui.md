# Architectural Decision Record: Program UI Creation
Workflow: /synthesize

## Input Lineage
- `docs/product/research_20260503_150428_a1b2c3d4_create_program_ui.md`
- `docs/product/research_20260503_150700_abcd_program_creation.md`

[ORIGIN_IDEA]: The UI to create and issue a new campaign (Program) has not been built yet in the Flutter app. The backend is ready (POST /api/programs exists) but ProgramListPage needs a "New Program" button and an API call to create one.

<latent_space_scratchpad>
Both artifacts agree on the backend contract but disagree on the UI architecture. Option 1 pushes for a Single Page Form, while Option 2 pushes for a Multi-step Wizard reusing existing pages.
For HQ workflows, assigning a program to 5,000 stores is a destructive/heavy action. A single-page form makes it too easy to misclick or lose state. A wizard forces deliberate action. The multi-select dialog for 5,000 stores in Option 1 is a guaranteed performance bottleneck. Option 2's reuse of `StoreSelectorPage` is safer.
</latent_space_scratchpad>

## Normalized Summary of Options
1. **Option A: Single Page Form:** A standard scrolling form holding Title, Category, Deadline, Template Dropdown, and a multi-select dialog for stores. State is managed via `setState`.
2. **Option B: Multi-step Wizard Flow:** A stepped wizard (Info -> Template -> Stores -> Review). Reuses `store_selector_page.dart` for full-screen store picking. State is managed via a dedicated `Manager`.

## Red Team Interrogation (Hostile Attack Vectors)

### Attack Vector 1: Single Page Form (Memory & Jank)
**Scenario:** An HQ user selects 5,000 stores using the multi-select dialog.
**Catastrophic Failure:** The form attempts to render 5,000 selected "chips" or names on the single screen, blocking the main thread and causing an Application Not Responding (ANR) crash on low-end Android devices. Furthermore, if the user accidentally swipes back or hits the physical back button, the entire form's state is instantly wiped, causing data loss and frustration.

### Attack Vector 2: Multi-step Wizard (Navigation Payload Limits)
**Scenario:** The user picks 5,000 stores on `StoreSelectorPage` and hits "Confirm", navigating back to the Wizard.
**Catastrophic Failure:** If the 5,000 UUIDs are passed via GoRouter URL parameters or `Navigator.pop(result)` without being backed by a shared in-memory Manager, it could exceed Android's Intent/Binder transaction limits (1MB), causing a silent crash during navigation. Furthermore, if the wizard's scoped manager isn't disposed when the user force-closes the app, it could lead to memory leaks.

## Pugh Decision Matrix
**Baseline [0]:** Option A (Single Page Form)

| Non-Functional Requirement | Option A (Form Baseline) | Option B (Wizard Flow) |
|---|---|---|
| **Origin Idea Alignment** | 0 | 0 |
| **UX & Safety for High Scale (5000+ Stores)** | 0 | +1 |
| **Data Loss Prevention (Accidental Back)** | 0 | +1 |
| **Implementation Complexity** | 0 | -1 |
| **Main Thread Performance (Rendering)** | 0 | +1 |
| **TOTAL SCORE** | **0** | **+2** |

## Final Verdict
**WINNER: Option B (Multi-step Wizard Flow)**

### Executive Business Summary
For HQ users issuing a campaign to thousands of stores, we cannot afford accidental clicks or frozen screens. A single-page form is too fragile for this scale. We will build a Step-by-Step Wizard. This guarantees users must deliberately review their choices before hitting "Submit", prevents the app from crashing when displaying thousands of selected stores, and allows us to save their progress at each step.

---

## Handoff Block

1. **Final Verdict:** Option B (Multi-step Wizard Flow).
2. **Strict Constraints:**
   - **Memory Scoping:** The Wizard MUST be wrapped in a `get_it` scope (`di.pushNewScope(scopeName: 'create-program')`) when opened, and `di.popScope()` when closed. This guarantees the `CreateProgramManager` and its heavy state (thousands of UUIDs) are instantly garbage-collected, preventing memory leaks.
   - **Data Structure (O(1) Performance):** The `CreateProgramManager` MUST use a `Set<String>` (or `Set<Guid>`) for `StoreIds`, not a `List`. This ensures O(1) lookups during UI rendering on the `StoreSelectorPage`, keeping scrolling buttery smooth.
   - **Reactive State & Graceful Failure:** The `CreateProgramManager` MUST expose a `flutter_it` Command (e.g., `late final issueCommand = Command.createAsyncNoParam(...)`). The UI will watch `issueCommand.isRunning` for the loading overlay and `issueCommand.errors` for failure toasts. If the API call fails, the Wizard MUST remain open with state intact, allowing the user to retry without losing 5,000 selections.
   - **UX for Scale:** The `StoreSelectorPage` MUST support a "Select All (Matching Filters)" action, as tapping 5,000 checkboxes individually is not viable.
3. **Execution Slices:**
   - **Slice 1 [BLOCKING]:** Add `createProgram` to `ProgramApiService` and create the `CreateProgramManager`.
   - **Slice 2 [SEQUENTIAL]:** Build the Wizard UI and wire it to the `ProgramListPage` FAB.
4. **Requirements Alignment Check:** N/A - The origin idea is purely UI addition.
5. **AI Agent Mission Brief:** The synth is complete. The winning architecture is a Multi-step Wizard using an in-memory manager to hold state. Build the `ProgramApiService` endpoint and the Wizard UI screens.
6. **Next Workflow Command:** 
   `@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_151520_synth_program_ui.md`
