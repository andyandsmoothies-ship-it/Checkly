# Research: Program Creation UI

## `[ORIGIN_IDEA]`
The UI to create and issue a new campaign (Program) has not been built yet in the Flutter app. Right now, the backend is fully prepared to create them (it has a POST /api/programs endpoint ready to use), but the frontend ProgramListPage currently only lists existing programs and doesn't have a "New Program" button or an API call to create one.

<latent_space_scratchpad>
- **Objective:** Bridge the gap between the ready backend endpoint (`POST /api/programs`) and the read-only frontend (`ProgramListPage`).
- **Backend Contract:** `CreateProgramRequest(Guid TemplateId, Guid[] StoreIds, DateTimeOffset Deadline, string Category, string Title)`
- **Frontend Gaps:**
  - `ProgramApiService` needs the `POST` method.
  - A `ProgramManager` (or existing state handling) needs a `createProgramCommand`.
  - UI needs a Floating Action Button (FAB) or Appbar Action on `ProgramListPage`.
  - UI needs a dedicated flow (Form or Wizard) to collect the 5 required fields.
- **Dependencies discovered:**
  - We need a way to pick `TemplateId`. We have `lib/features/templates/`.
  - We need a way to pick `StoreIds`. We have `lib/features/stores/pages/store_selector_page.dart`.
- **Tradeoffs:**
  - A single scrolling form page is fast to build but might be overwhelming if selecting from 1000s of stores.
  - A Wizard flow (like we have for Template creation) separates concerns (Step 1: Info, Step 2: Pick Template, Step 3: Pick Stores) and feels more premium for HQ workflows. Given the impact (bulk creating assignments), a deliberate wizard is preferred over a quick form.
</latent_space_scratchpad>

## E2E Workflow Map
1. **Trigger:** User taps "Create Campaign" on `ProgramListPage`.
2. **UI Navigation:** Routes to `ProgramCreateWizardPage` (or similar).
3. **Data Collection:**
   - Input `Title` & `Category`.
   - DatePicker for `Deadline`.
   - Navigation to `TemplateSelectorPage` (or dropdown) for `TemplateId`.
   - Navigation to `StoreSelectorPage` for `StoreIds`.
4. **Action:** User taps "Issue Program".
5. **Manager Layer:** `di<ProgramManager>().createCommand.run(dto)`.
6. **API Layer:** `ProgramApiService.createProgram()` posts to `/api/programs`.
7. **Backend:** `CreateProgram.cs` validates, bulk-inserts `ProgramAssignment`s, saves to DB, returns `201 Created`.
8. **UI Response:** On success, Wizard closes, `ProgramListPage` shows a success toast (via `InteractionManager`) and either auto-refreshes or optimistically adds the item to the list.

## Comparative Decision Matrix

| Option | Description | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A. Strict Native Fit (Basic Form)** | Single `ProgramCreatePage` with standard text fields, dropdown for template, and multi-select dialog for stores. | Fast implementation. Standard Flutter patterns. | Multi-select for stores inside a dialog gets messy if there are >50 stores. Poor UX for complex HQ workflows. | Reject |
| **B. Pragmatic Balance (Wizard Flow)** | Multi-step `ProgramWizardPage` (Info -> Template -> Stores -> Review). Reuses `store_selector_page.dart` for full-screen store picking. | Deliberate UX (prevents accidental mass-assignments). Good reuse of existing full-screen selectors. | Slightly more boilerplate to manage wizard state. | **Approve** |
| **C. Enterprise Textbook** | Server-Driven UI wizard where the backend defines the steps and dynamic fields. | Ultimate flexibility for future fields. | Massive over-engineering for 5 static fields. Violates "Keep It Simple". | Reject |

## Blind Spots & NFR Risks
1. **Memory/Payload (Store Selection):** If `StoreSelectorPage` is used to pick 5,000 stores, the state array size and the JSON payload for `Guid[] StoreIds` could become quite large. Needs monitoring to ensure no UI stutter.
2. **UX (Template Preview):** Picking a `TemplateId` via a simple dropdown is risky if titles are similar. Users might need to see what questions are in the template before assigning it. (Potential future scope: Template Preview step).
3. **Resilience (Backend Bulk Insert):** The backend uses `db.ProgramAssignments.AddRange(assignments);`. If a user selects 10,000 stores, `SaveChanges` might timeout. The API might need to move to Dapper Bulk Insert (`dotnet-bulk-updates` skill) if this scale is realistic.

## Rule Conflicts & Pattern Enforcement
- **Conflict with `flutter-architecture`:** The command execution pattern dictates that after `createCommand` succeeds, we *must not* nest commands (e.g., `loadCommand.run()`). Instead, we must either refresh the API directly inside the command or rely on the UI to call the refresh method after popping the wizard.

<forensic_evidence>
- `grep_search` confirmed `POST /api/programs` exists in `CreateProgram.cs`.
- `view_file` confirmed `CreateProgramRequest` shape in `ProgramDtos.cs`.
- `view_file` confirmed `ProgramListPage` currently lacks a creation entry point.
- `view_file` confirmed `ProgramApiService` currently lacks the `createProgram` method.
</forensic_evidence>

## Handoff Block

- **Verdict:** Viable. Proceed with Option B (Pragmatic Balance - Wizard Flow).
- **Effort Sizing:** Track A/B (Standard feature addition).
- **AI Agent Mission Brief:** The Scout has completed the architectural research. The Builder needs to add the `createProgram` method to `ProgramApiService`, add `createCommand` to the relevant manager (or create `ProgramManager`), and build a `ProgramCreateWizardPage` (or form) that gathers Title, Category, Deadline, TemplateId, and StoreIds, tying it to the "New Program" button on `ProgramListPage`.
- **Next Step:** Run the implementation workflow: `/analyze-feature c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260503_150700_abcd_program_creation.md`
