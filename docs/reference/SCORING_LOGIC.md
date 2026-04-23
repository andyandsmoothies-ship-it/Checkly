# Checkly Scoring System

This document describes the technical implementation and business rules for all scoring modes in Checkly: **Penalty**, **Accumulation**, **Checklist**, and **Survey**.

> [!NOTE]
> As of 2026-03-17, **template type is a pure filter tag**. All features (Points, CCP, RISK, Is Required, Weighted Density, Progressive Repeat) are universally available regardless of type. The `templateType == 'qc'` conditional logic has been fully removed.

## 1. Hierarchy & Structure

The scoring logic operates on a three-level hierarchy:
1.  **Section (Top-Level Group)**: Has a "Density Weight" (Percentage of the total audit score).
2.  **Subsection (Sub-Group)**: Has "Max Points" (Absolute contribution to the section points).
3.  **Criteria (Audit Item)**: Has "Minus Per Fault" and "Penalty Weights".

> [!NOTE]
> **Non-scored input types** (`text`, `single_choice`, `multi_choice`) are data-collection only — they have no `pointsWeight`, are excluded from scoring calculations, and do not show points in any UI.
>
> **Builder Enforcement**: The Template Builder's save-time validation guards (V5, V6) enforce that scored templates have at least one scoring criterion and that scoring criteria have points > 0. See Section 6 for details.

## 2. Core Formulas

### A. Subsection Score
Each subsection calculates its deductions based on faults found in its criteria.
- **Criteria Deduction** = `(Faults × Minus Per Fault) + (Repeated Faults × Minus Per Fault)`
- **Progressive Repeat Penalty** (optional, per-template): When enabled, repeated faults use **quadratic escalation** instead of linear:
  - `Repeat Deduction = Repeated Faults² × Minus Per Fault` (capped at subsection max)
  - Controlled by `scoring_logic_config.features.progressive_repeat_penalty` (default: `false`)
- **Criteria Override**: If a criteria has a specific `minus_impact` metadata value, it overrides the Subsection's `Minus Per Fault`.
- **Subsection Deduction** = `SUM(Criteria Deductions)` (Capped at `Subsection Max Points`)
- **Subsection Score** = `Subsection Max Points - Subsection Deduction`

### B. Section Score (Top-Level Group)
A section's score is a percentage representing the health of that section.
- **Section Before** = `SUM(All Subsection Max Points)`
- **Section After** = `SUM(All Subsection Scores)`
- **Section Ratio** = `Section After / Section Before`

### C. Total Weighted Score (Percentage)
The final audit score is a **Normalized Weighted Average** of all section ratios.
- **Weighted Score** = `SUM(Section Ratio * Section Density Weight)`
- **Total Possible Weight** = `SUM(All Section Weights)`
- **Final Result**:
    - If `Total Possible Weight > 0`: `(Weighted Score / Total Possible Weight) * 100`
    - If `Total Possible Weight = 0`: `100 - SUM(All Raw Points Deductions)`

This ensures that templates with no points or weights assigned still start at **100%** and lose points incrementally for faults.

---

## 3. Critical Overrides (Sentinel Rules)

The system includes two types of logical overrides that bypass standard arithmetic:

### 🛡️ CCP (Critical Control Point)
- **Trigger**: Any criteria with `is_ccp = true` is marked as "Fail" or has > 0 faults.
- **Scope**: **Section-Level**.
- **Impact**: 
    - The entire **Section Score** becomes **0%**.
    - The section's absolute points earned becomes **0** in the HUD display.
    - Standard weighting still applies (e.g., if a 15% section fails CCP, the total audit score drops by 15 points).

### ⚠️ RISK (Template-Bound)
- **Trigger**: Any criteria with `is_risk = true` that has a **fault** (input-type-aware via `_hasFault()`).
  - `pass_fail`: fault = answer is `non_conform`
  - `numeric`: fault = `numericValue > 0` (fault count)
  - `scale`: fault = `numericValue == 0` (earned zero points)
- **Also triggered by**: `answer.isRisk = true` (auditor manual override on a specific criterion)
- **Scope**: **Audit-Level**.
- **Impact**:
    - The **Final Audit Score** is forced to **0%**.
    - All absolute points earned are forced to **0**.
    - This reflects a fundamental failure that invalidates the entire audit.

### 🚨 Global Risk (Template-Agnostic)
- **Trigger**: Auditor manually flags a company-wide risk from the universal Risks Panel during an audit, regardless of the template being used.
- **Scope**: **Audit-Level**.
- **Impact**:
    - The **Final Audit Score** is forced to **0%**.
    - An **Action Plan** is automatically generated on the backend for each triggered Global Risk, bypassing the standard fault evaluation.
    - Operates in parallel with legacy template-bound RISK flags.

---

## 4. Points HUD Logic (Live Feedback)
The live HUD in the Audit Form displays "Points Earned / Points Possible".
- **Points Possible**: `SUM(All Subsection Max Points)`
- **Points Earned**: `SUM(Section After)` (where `Section After` is forced to 0 if a CCP is present in that section).

> [!IMPORTANT]
> **Multi-Mode Support**: Templates support four scoring modes via `scoring_logic_config.scoringMode`: `penalty` (default), `accumulation`, `checklist`, and `survey`. The mode determines how the scoring engine calculates the final score.

### Is Required (Per-Criterion)
The legacy global "Confirm Correct" toggle has been replaced by a granular, per-criterion `isRequired` flag:
- A criterion marked as `isRequired` displays a mandatory red asterisk in the UI.
- The auditor must explicitly provide an answer or verify the item before the audit can be submitted.
- This ensures targeted accountability without forcing users to tap a button for every single trivial passing item.


## 5. Survey and Checklist Modes (Builder Constraints)

To prevent novice users from creating mathematically invalid templates (e.g., trying to assign point deductions to a Survey), the Template Builder UI enforces strict **Smart Constraints** via the Blueprint Wizard.

When a template is created as a `survey` or `checklist`:
- **Sub-sections are Physically Disabled**: The `+ Add Sub-Section` button is greyed out. Surveys and checklists strictly enforce a flat, 2-level hierarchy (Sections → Criteria) to ensure quick field operation.
- **Scored Input Types are Greyed Out**: Users are blocked from selecting `pass_fail`, `numeric`, `fault_count`, or `scale` in the criterion designer.
- **Scoring Engine Bypass**: If `scoringMode == 'survey'`, the scoring engine skips all calculation (`totalScore = null`). The live points HUD is hidden in the audit form, and the "Points Weight" input is completely hidden in the Template Builder to prevent UX confusion.
- **Answers stored normally** — `Answer.Value` holds the selected option label (or comma-separated for multi-choice)
- **Analytics endpoint**: `GET /api/submissions/survey-results?templateId={id}` — admin-only, aggregates option counts per criterion
- **Choice input types**: `single_choice` (pick one) and `multi_choice` (select all that apply) — options stored in `criteria.metadata` as `{"options": ["A","B","C"]}`
- **History badge**: Completed survey submissions show a purple **SURVEY** badge instead of a score

---

## 6. Technical Implementation

### Flutter Mobile (Primary)
- **Scoring Engine**: `lib/_shared/services/scoring_engine.dart`
- **Audit Manager**: `lib/features/audit/manager/audit_manager.dart`
- **Audit Form Page**: `lib/features/audit/pages/audit_form_page.dart`
- **Template Builder**: `lib/features/templates/pages/template_builder_page.dart`
- **Template Detail**: `lib/features/templates/pages/template_detail_page.dart`
- **Survey Results Page**: `lib/features/audit/pages/survey_results_page.dart`

### PWA (Legacy Reference)
- **Source Code**: `src/lib/scoringEngine.ts`
- **Hook**: `src/hooks/useAuditScoring.ts`
- **Database Persistence**: `finalize_audit` RPC
- **Server Verification**: `verify-score` Edge Function

### Server-Side (C# .NET Core)
The `CreateSubmission` and `FinalizeSubmission` endpoints include **synchronous server-side score verification**. After answers are parsed, the backend calls `ScoringVerifier.Verify()` which re-computes the score independently. If the server score diverges from the client score by >0.01 tolerance, the submission is **rejected** with a 400 Bad Request.

| Component | Purpose |
|:---|:---|
| `ScoringVerifier.cs` | Re-computes from template + answers, mimicking `scoring_engine.dart` |
| `ScoringConfigParser.cs` | Safe extraction of `scoringMode` and `progressiveRepeat` from JSON configs, with logging on parse failure to prevent silent fallbacks. |
| `scoring_input_mapper.dart` | Client-side mapper. Applies a case-insensitive check for `non_conform` answers to assign a default `numericValue=1`, ensuring parity with C#. |

> [!WARNING]
> Both C# and Flutter must handle `non_conform` answers consistently. The C# engine drops directly into the `faults * impact + repeat` math logic without early returns, matching Flutter perfectly. Submissions with spoofed or mathematically divergent scores are rejected.

### Template Builder Validation

The Template Builder (`template_builder_page.dart`) includes a **unified inline validation system** that prevents admins from creating broken or meaningless templates. All validations run in a single pass on save, showing ALL errors simultaneously with red borders, inline error text, a summary banner, and auto-scroll to the first error.

| Guard | Rule | Error When |
|:------|:-----|:-----------|
| Template title | Title must not be empty | Blank title field |
| Minimum sections | At least 1 section required | Zero sections |
| Section title | All sections/sub-sections need titles | Any empty title |
| Empty sections | Every section must have ≥1 criterion or sub-section | Section has neither |
| Scale options | Scale criteria must have ≥2 options | Fewer than 2 scale options |
| Choice options | Choice criteria must have ≥2 options | Fewer than 2 choice options |
| **V5: Ghost Template** | Scored templates must have ≥1 scoring criterion (`pass_fail`, `numeric`, or `scale`) | All criteria are non-scoring types |
| **V6: Pointless Criteria** | `numeric` and `scale` criteria must have `pointsWeight > 0` | Zero or empty points on scoring criteria |
| Density weights | When Weighted Density is ON, all section weights > 0 and sum to 100% | Zero weight or sum ≠ 100% |

- **Validation Model**: `lib/features/templates/models/validation_result.dart` — key-value map for O(1) lookup per widget
- **Blueprint Selection**: New templates open with a Blueprint Selection modal that auto-configures scoring mode and scaffolds the first section
- **Survey exemption**: V5 and V6 guards are skipped for Survey mode templates

---

## 7. Assignment Rules (SM / AM Constraints)

These rules govern how users are assigned to stores and areas.

### Valid Areas
Areas are managed entities stored in the `areas` table with `id`, `name`, and `description` fields.

> [!NOTE]
> Areas are now managed dynamically via the Admin API (`/api/areas`). The previous hardcoded 5-area restriction has been removed.

### 1 Store Manager per Store
- Each store (`stores.id`) can have at most **1 user** with role `store_manager` assigned to it (`profiles.store_id`).
- **Enforced at**: Edge Function (`createUser`), `admin_update_user` RPC, UI (store selector hides occupied stores).

### 1 Area Manager per Area
- Each area (managed entity in `areas` table) can have at most **1 user** with role `area_manager` assigned to it via FK (`profiles.area_id` → `areas.id`).
- **Enforced at**: `RoleAssignmentGuard.FindExistingAreaManager` (Guid `areaId`), `PUT /api/admin/users/{id}`, UI (area selector hides occupied areas).

### Technical References
- **Edge Function**: [admin-api/index.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/functions/admin-api/index.ts) — `createUser()` checks SM + AM conflicts before profile creation.
- **RPC**: `admin_update_user` — checks SM + AM conflicts before profile update.
- **UI (Users)**: [UserManagement.tsx](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/pages/admin/UserManagement.tsx) — selectors filter out occupied stores/areas.
- **UI (Stores)**: [StoreManagement.tsx](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/pages/admin/StoreManagement.tsx) — area selector with 5 valid areas.

### SM Transfer Protocol

When replacing a Store Manager (SM), open action plans must be transferred atomically:

- **Transfer RPC**: `transfer_store_manager(store_id, new_sm_id)` — atomic swap + AP transfer + audit log.
- **Pre-check RPC**: `check_sm_open_aps(store_id)` — returns count of open APs for confirmation dialog.
- **Guards** (defense-in-depth):
  - **Frontend** (UserManagement): Blocks role/store changes for active SMs; directs admin to Store Management.
  - **Frontend** (UserManagement): Blocks disabling active SM accounts.
  - **RPC** (`admin_update_user`): Prevents changes to active SMs.
  - **Edge Function** (`banUser`): Prevents banning active SMs.
- **UI**: StoreManagement shows confirmation dialog with open AP count before transfer.

---

## 8. Action Plan Lifecycle

> For action plan creation rules, status transitions, notifications, deadlines, and dashboard metric impact, see [CORE_WORKFLOWS.md](./CORE_WORKFLOWS.md).
