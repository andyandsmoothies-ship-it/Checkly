# Research: Create Program UI

[ORIGIN_IDEA]: The UI to create and issue a new campaign (Program) has not been built yet in the Flutter app. The backend is ready (POST /api/programs exists) but ProgramListPage needs a "New Program" button and an API call to create one.

<latent_space_scratchpad>
**Backend Contract Analysis:**
The endpoint `POST /api/programs` is mapped in `ProgramEndpoints.cs` and handled by `CreateProgram.cs`.
It expects `CreateProgramRequest`:
- `Guid TemplateId` (Must exist and be active)
- `Guid[] StoreIds` (Length >= 1)
- `DateTimeOffset Deadline` (Must be in future)
- `string Category` (Max 100)
- `string Title` (Max 200)

**Frontend Current State (`ProgramListPage`):**
- Located at `lib/features/programs/pages/program_list_page.dart`.
- Simple `StatefulWidget` directly using `ProgramApiService.getPrograms()`.
- Lacks a Floating Action Button (FAB) or Appbar Action to navigate to a creation screen.

**Required UI Components:**
1. A trigger on `ProgramListPage` (FAB).
2. A new `CreateProgramPage` or modal. Given the complexity of selecting a Template and multiple Stores, a dedicated full-screen route (`/programs/new`) is preferred.
3. Form fields: Title (Text), Category (Dropdown or Text), Deadline (Date/Time picker).
4. Relational selectors: Template (Dropdown), Stores (Multi-select list with search).

**Alternative Architectures:**
A. **Strict Native Fit (Single Page Form):** A standard scrolling form with all inputs. Uses `ProgramApiService.createProgram(dto)`. State handled by `setState`. Matches `ProgramListPage` style.
B. **Pragmatic Balance (Manager-backed Wizard):** Uses a multi-step form (Step 1: Info, Step 2: Template, Step 3: Stores) backed by a `CreateProgramManager` to hold intermediate state.
C. **Enterprise Textbook Overhaul:** Offline-first creation, dumping into an outbox, sync engine picks it up later. Unnecessary since HQ is assumed online-only.

**Blind Spots regarding NFRs:**
1. **Store Selection Scalability:** If Checkly manages 5,000 stores, a simple dropdown or scrolling list will cause severe UI jank. A paginated or searchable selection widget is mandatory.
2. **Template Validation:** The backend enforces `template.IsActive`. If the UI caches templates, it might submit an inactive template. The UI must only fetch and present active templates.
3. **Double Submission:** Submitting 5,000 `ProgramAssignment` records via EF Core bulk insert might take 1-3 seconds. The UI must aggressively disable the submit button and show a loading overlay to prevent duplicate program creations.

**Rules Conflicts:**
1. **PFA Manager vs setState:** `ProgramListPage` currently uses `setState` (violating strict PFA Manager pattern). If we build `CreateProgramPage` with a `Manager`, the feature becomes architecturally inconsistent. We should stick to the local `setState` style for this specific feature to maintain local consistency, or explicitly decide to refactor both.

</latent_space_scratchpad>

## E2E Workflow Map

1. **Trigger:** User clicks a new `FloatingActionButton` on `ProgramListPage`.
2. **Navigation:** `context.push('/programs/new')`.
3. **Pre-fetch:** `CreateProgramPage` loads `Active Templates` and `All Stores` from their respective API services.
4. **Input:** User fills Title, Category, Deadline, selects Template, selects >= 1 Store.
5. **Validation:** Frontend checks `StoreIds.isNotEmpty` and `Deadline.isAfter(DateTime.now())`.
6. **Submission:** `ProgramApiService.createProgram(request)` sends POST to `/api/programs`.
7. **Backend Execution:** `CreateProgram.HandleAsync` bulk inserts assignments, returns `201 Created`.
8. **Completion:** UI pops back to `ProgramListPage` yielding `true`. List page calls `_load()` to refresh.

## Comparative Decision Matrix

| NFR / Metric | (A) Single Page Form | (B) Multi-step Wizard (Baseline) | (C) Offline Queue |
|---|---|---|---|
| **Origin Idea Alignment** | +1 | 0 | -1 |
| **UX for >500 Stores** | -1 (Cluttered) | 0 (Dedicated Step) | 0 |
| **Implementation Speed** | +1 (Fastest) | 0 | -1 (Slowest) |

## <forensic_evidence>
- `grep_search` on `ProgramListPage` revealed `lib/features/programs/pages/program_list_page.dart`.
- `view_file` on `ProgramListPage` showed `setState` driven UI with `ProgramApiService`.
- `grep_search` on `CreateProgram` revealed `server/Features/Programs/CreateProgram.cs` and `ProgramDtos.cs`.
- `view_file` on `ProgramDtos.cs` confirmed `CreateProgramRequest` signature.
</forensic_evidence>

## Handoff Block

### Final Verdict & Persistent Path
**Verdict:** Viable. Proceed with Option A (Single Page Form) but include a searchable MultiSelect dialog/widget for the Store selection to handle potential scale.
**Persistent Path:** `docs/product/research_20260503_150428_a1b2c3d4_create_program_ui.md`

### Effort Sizing & Concurrency Strategy
**Effort:** Track A/B (Pragmatic Single Page UI). Medium effort. 
**Concurrency:** Frontend can be built immediately since the backend `POST /api/programs` endpoint is already fully functional and mapped.

### AI Agent Mission Brief
Build the `CreateProgramPage` in the Flutter app to consume the existing `POST /api/programs` endpoint. Add a "New Program" FAB to `ProgramListPage` and implement a form with Title, Category, Deadline, Template (dropdown), and Stores (searchable multi-select).

### Next Steps
The user should run the next analysis/implementation workflow targeting this artifact:
`/analyze-feature docs/product/research_20260503_150428_a1b2c3d4_create_program_ui.md`
