# Research: Balancing Business Integrity & Design Flexibility in the Audit Template Engine

**Date**: 2026-05-28 | **ShortID**: c3563378
**Topic**: audit-template-flexibility
**Conversation ID**: cdefadc1-bcb6-48a6-b2df-d50ea610949f
**Status**: Technical Proposal for Review

---

## [ORIGIN_IDEA]
The business administrator needs a solution to make the "Business Integrity & Design Flexibility" trade-offs lesser in the Audit Template Engine. We want to preserve maximum design flexibility so admins can build any checklist structure they want, while minimizing user errors (e.g. bad scoring configurations, mixed scored/unscored checkpoints) that pollute downstream boardroom metrics (BOD) or result in invalid averages.

---

<latent_space_scratchpad>
We are dealing with a classic software architectural trade-off: **Freedom vs. Constraints**.

Currently, the Audit Template Engine allows infinite nesting and free-form field types. However, this freedom comes at a cost:
1. **Logical Failures**: An admin can set a template to `penalty` mode but provide zero point weights on groups/criteria, rendering the math useless.
2. **Purity Gate Pitfalls**: Mixing scored and unscored questions makes the audit a "Mixed Audit", resulting in a `null` score. If an admin does this by accident, they wonder why their submissions show no score on the executive dashboard.
3. **Boardroom Pollution**: A flat checklist and a high-stakes QC audit get blended together, skewing the overall compliance score of a store.

### Evaluating the Solutions:
- **Option A (Presets/Archetypes at Creation)**: Very strict. We force the user to pick "Operational Checklist", "QC Scored Audit", or "Qualitative Survey". The editor then restricts their options.
  * *Pros*: Guarantees database hygiene. No invalid configurations possible.
  * *Cons*: Reduces flexibility. What if they need an "Operational Checklist" but want to add a single high-impact scored section? They are locked out.
- **Option B (Smart Linter & Guardrails)**: Highly flexible. The UI and API allow full freedom, but run a "Linter Ruleset" that reviews the template tree and generates non-blocking warning blocks (e.g., "Mixed Audits will result in a null score", "No weight configured for section").
  * *Pros*: Admins retain 100% of their flexibility but receive immediate visual feedback on the mathematical consequences. The UI can explain *why* it's warning them.
  * *Cons*: Requires building a simple rule processor on C# and Dart.
- **Option C (Separate Schemas/Endpoints)**: Textbook enterprise approach. Separates the models entirely.
  * *Pros*: Perfect domain boundary.
  * *Cons*: Massive overhead. Doubles database tables, sync endpoints, Dart models, and UI editor code. Highly complex.

Option B is the clear pragmatic winner. It leverages "Smart UX Guardrails" over "Draconian Enforcement", reducing the cons of both extremes.
</latent_space_scratchpad>

---

## E2E Workflow Map
The following ASCII flowcharts describe how the Smart Linter (Option B) executes from creation to submission:

### A. Template Creation & Editing (Admin UX)
```
 [Admin UI Template Editor] ──► [Builds Template Tree]
             │
             ▼
 [Run Local Dart Linter] ────► [Detects: Scored & Unscored criteria mixed]
             │
             ├──► Show warning card: "⚠️ This is a Mixed Audit. Final score will be NULL."
             │
             ▼ (Admin clicks Publish)
 [PUT /api/templates/{id}/tree] ──► [Runs Backend C# Linter]
                                            │
                                            ├──► Save success, return schema + lint warnings JSON
```

### B. Downstream Execution & Boardroom (BOD) Analytics
```
 [Postgres Db] ──► [Sync Engine] ──► [Auditor Mobile App] ──► [Executes Audit]
                                                                     │
                                                                     ▼
 [Boardroom Sync Worker] ◄── [BOD Reports Table] ◄── [Calculates Score (or Null)]
           │
           ▼
 [BOD Dashboard Chart] (Safely ignores NULL scores of Surveys & Mixed Audits)
```

---

## Impact Spectrum

We analyze three options to balance flexibility and constraints in the system:

1. **Option A: Hard Presets (Strict)**
   - Forces structural separation at the UI entry point. Disables non-relevant inputs and scoring configurations based on preset choice.
   - *Impact*: Low database risk but highly restrictive for custom business models.

2. **Option B: Smart Linter & UX Guardrails (Pragmatic)**
   - Allows full freedom but adds a real-time logical rules linting engine inside C# backend and Flutter editor to flag invalid configurations.
   - *Impact*: Preserves 100% customizability while preventing user configuration mistakes.

3. **Option C: Split Domain Database Schema (Overhaul)**
   - Splitting database tables into specific models (`operational_checklists`, `qc_audits`, `surveys`).
   - *Impact*: High database migration risk and code duplication.

---

## Blind Spots

The following are three key non-functional blind spots identified for our recommended option (Option B):

1. **Sync Payload Size**: Returning a highly verbose linter warning structure in the JSON tree schema may increase network payloads for bandwidth-constrained field devices. The backend must serialize warnings concisely.
2. **Flutter UI Editor Lag**: Running complete layout validations dynamically at 60fps in Dart during structural changes could degrade performance. Validation should trigger asynchronously on a debounce timer.
3. **Historical Schema Migration**: Introducing new database constraints for archetypes can block existing templates in the database that are structurally invalid but active. Linters must be purely advisory for existing templates.

---

## Conflicts with Rules

The following are conflicts identified with existing rules and architecture:

- **Gotcha 5: Survey Mode**: Our new linter rules must align with the existing boardroom filtering rule `Filter WHERE scoring_mode != 'survey' before averaging scores`. If the linter forces a score on survey templates, it will conflict with this reporting pipeline.
- **Rule: Keep it Simple (SRP/WET)**: Extracting shared linter classes must be done carefully to avoid over-engineering or building complex generic rules engines when simple flat logical checks are sufficient.

---

## UI Component Routing Table

To support the Smart Linter in the Flutter UI without causing card overflow or rendering lags:

| UI Widget | Component Path | Layout Constraint | Overflow Risk & Handling | Downstream Route |
| :--- | :--- | :--- | :--- | :--- |
| `TemplateLinterPanel` | `lib/features/templates/widgets/template_linter_panel.dart` | Max height 180px, Scrollable ListView. | **High Risk**: Multiple warning cards can overflow standard height. **Fix**: Wrap in `ConstrainedBox` with `.shrink()` if list is empty. | Displayed at the top of the Template Builder sidebar. |
| `LintWarningCard` | `lib/features/templates/widgets/lint_warning_card.dart` | Horizontal Row with Icon + Column. | **Low Risk**: Wrap label text in `Expanded` to prevent horizontal clipping. | Clicking card focus-scrolls to the offending Group/Criterion in the editor. |

---

<forensic_evidence>
Proof of context research:
- Executed `view_file` on `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Templates\SaveTemplateTree.cs` to verify how the backend manages tree saves.
- Executed `view_file` on `c:\Users\HP\Documents\GitHub\Checkly\docs\product\requirements_20260527_122500_c3563378_audit_template_full_scope_v5.md` to map E2E scoring engine specifications.
- Verified how system telemetry calculations process data via visual auditing.
</forensic_evidence>

---

## Handoff Block

### Final Verdict & Recommendation
**Approved Option B (Smart Linter & UX Guardrails)** with the **Live Score Simulator**. It provides a perfect balance. Business users keep the creative flexibility they need, while the system guides them dynamically to prevent invalid configurations, protecting the mathematical consistency of boardroom analytics.

- **Persistent Research Path**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260528_161500_template_flexibility_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`
- **Effort Sizing**: Track B (Pragmatic / Tactical Addition). 3-4 dev days.
- **Concurrency Strategy**: Safe to implement in parallel with reporting tasks since it introduces new linter services without changing base entities.

### AI Agent Mission Brief & Build Specifications

#### 1. Linter Ruleset & Severity Levels
The system must run independent checks and return two severity levels:
*   🔴 **Critical Errors (Blocking)**:
    *   `EmptyStructureCheck`: Checks if any group has 0 questions, or if the template has 0 groups.
    *   `DuplicateIdCheck`: Checks if any two sections or questions share the exact same UUID.
    *   `EmptySectionName`: Checks if any group has a blank or whitespace-only title.
    *   `PenaltyModeGroupSum`: Checks if top-level group weights in penalty mode do not sum to exactly 100.0%.
    *   *Result*: Disables the "Publish" button until resolved.
*   🟡 **Advisory Warnings (Non-Blocking)**:
    *   `MixedAuditWarning`: Checks if a scored question is mixed with unscored survey questions (warning the user that the total score will evaluate to NULL on boardroom dashboards).
    *   `ScaleMixingWarning`: Checks if positive scoring (`scale`) and deduction scoring (`pass_fail`) are mixed in a single group.
    *   `SilentRiskInSurvey`: Checks if `isRisk = true` is enabled in a `survey` template.
    *   `ProgressiveZeroImpact`: Checks if `Progressive Repeat Penalty` is active but question deduction impact is 0 or null.
    *   *Result*: Allows publishing, but requires checking a bypass checkbox: `[x] I understand these mathematical warnings. Publish anyway.`

#### 2. Auditor View Restriction Gate
*   **Safety Rule**: The linter panel and all warning cards are restricted strictly to the Admin Template Editor. 
*   **Result**: The Store Auditor's mobile audit execution screens must be completely clean and free of linter warnings.

#### 3. Live Score Simulator Panel
*   **Aesthetics**: Interactive right-side panel inside the Admin Editor.
*   **Simulation Controls**: Lets the admin toggle test checkboxes (`[Fail]` or `[N/A]`) for each question.
*   **Dynamic Calculations**: Instantly displays maximum possible score, current simulated score percentage, and triggers `🔴 RISK TRIGGERED: Score forced to 0%` in real-time.
*   **Mobile-First Design (Responsive Tabbed Layout)**:
    *   *Desktop/Web View*: Renders as a three-column split view (Left: Question Editor, Center: Linter Panel, Right: Simulator Panel).
    *   *Mobile/Narrow View*: Automatically switches to a top TabBar with three swipeable tabs: `[ 📝 Design ]`, `[ ⚠️ Issues ]`, and `[ 🧮 Simulator ]` using standard Flutter `TabBarView`. This eliminates squishing, horizontal overflows, and floating panel clutter.

#### 4. Omitted Features
*   **One-Click Auto-Fix**: Dropped to avoid extra code complexity and maintain a lightweight development surface.

### Next Action Command
Pass this updated research artifact to `/analyze-feature` to map out the exact specification:
```powershell
cmd /c python .agents/scripts/verify_workflow.py "C:\Users\HP\Documents\GitHub\Checkly\.agents\active_tasks\audit-template-flexibility\task_20260528_161500_audit_template_flexibility_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md"
```
