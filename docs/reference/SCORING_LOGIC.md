# Checkly Scoring System

This document describes the technical implementation and business rules for scoring configurations in Checkly. Scoring is driven by two orthogonal toggles (**Score Direction** and **Is Weighted**) instead of legacy scoring modes.

> [!NOTE]
> As of 2026-03-17, **template type is a pure filter tag**. All features (Points, CCP, RISK, Is Required, Weighted Density, Progressive Repeat) are universally available regardless of type. The `templateType == 'qc'` conditional logic has been fully removed.

## 1. Hierarchy & Structure

The scoring logic operates on a two-level hierarchy:
1.  **Section (Group)**: Has a "Density Weight" (Percentage of the total audit score) and "Max Points" (Absolute contribution to the section points).
2.  **Criteria (Audit Item)**: Has "Minus Per Fault", "Penalty Weights", and "Max Deduction Points" cap.

> [!NOTE]
> **Non-scored input types** (`text`, `single_choice`, `multi_choice`) are data-collection only — they have no `pointsWeight`, are excluded from scoring calculations, and do not show points in any UI.
>
> **Builder Enforcement**: The Template Builder's save-time validation guards (V5, V6) enforce that scored templates have at least one scoring criterion and that scoring criteria have points > 0. See Section 6 for details.

## 2. Core Formulas

### A. Criteria Deduction / Earned Points
Each criterion calculates its scoring contribution based on answers and faults.
- **Deduction (Down Scoring)**:
  - **Base Deduction** = `(Faults × Minus Per Fault) + (Repeated Faults × Minus Per Fault)`
  - **Progressive Repeat Penalty** (optional, per-template): When enabled, repeated faults use **quadratic escalation** instead of linear:
    - `Repeat Deduction = Repeated Faults² × Minus Per Fault`
    - Controlled by `scoring_logic_config.features.progressive_repeat_penalty` (default: `false`)
  - **Criteria Cap**: The total deduction for a single criterion is capped by its `max_deduction_points` (or `points_weight`).
  - **Total Criteria Deduction** = `MIN(Base Deduction, Criteria Cap)`
- **Earned Points (Up Scoring / Accumulation)**:
  - For **scale** input types: The earned score is the selected scale option's point value directly (`numericValue`).
  - For **binary/numeric** input types: If the criterion has 0 faults, is not `non_conform`, and has 0 repeated faults, it earns full `points_weight`. Otherwise, it earns `0` points.

---

### B. Section Score (Top-Level Group)
A section's score is a ratio representing the health or earned contribution of that section.

#### 1. Down Scoring (Checklist / Penalty)
- **Section Before** = `SUM(All Criteria Caps within the Section)`
- **Section Deduction** = `SUM(All Total Criteria Deductions within the Section)`
- **Section After** = `Section Before - Section Deduction`
- **Section Ratio** = `Section After / Section Before`

#### 2. Up Scoring (Accumulation)
- **Section Possible** = `SUM(All Points Weights within the Section)`
- **Section Earned** = `SUM(All Criteria Earned Points within the Section)`
- **Section Ratio** = `Section Earned / Section Possible` (forced to `0` if a CCP is failed in that section)

---

### C. Final Score Calculation (Percentage)
The final audit score is calculated depending on the scoring direction and weight configurations:

#### 1. Penalty (Weighted Down) — `scoreDirection = 'down'`, `isWeighted = true`
- **Weighted Score** = `SUM(Section Ratio * Section Density Weight)`
- **Total Possible Weight** = `SUM(All Section Weights)`
- **Final Result**: `(Weighted Score / Total Possible Weight) * 100`

#### 2. Checklist (Simple Down) — `scoreDirection = 'down'`, `isWeighted = false`
- **Final Result**: `MAX(0, 100 - SUM(All Criteria Deductions))`

#### 3. Accumulation (Weighted Up) — `scoreDirection = 'up'`, `isWeighted = true`
- **Weighted Score** = `SUM(Section Ratio * Section Density Weight)`
- **Total Possible Weight** = `SUM(All Section Weights)`
- **Final Result**: `(Weighted Score / Total Possible Weight) * 100`

#### 4. Accumulation (Simple Up) — `scoreDirection = 'up'`, `isWeighted = false`
- **Final Result**: `(SUM(All Section Earned Points) / SUM(All Section Possible Points)) * 100`

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
- **Points Possible**: `SUM(All Criteria Caps)`
- **Points Earned**: `SUM(Section After)` (where `Section After` is forced to 0 if a CCP is present in that section).

> [!IMPORTANT]
> **Orthogonal Scoring Configurations**: Templates support scoring logic via two fields in the JSON config: `scoreDirection` (down, up, none) and `isWeighted` (boolean). This replaced the legacy 4-value mode string, separating the mathematical direction from the weight constraint.

### Is Required (Per-Criterion) & Global Confirm Correct
Accountability and validation are enforced through the `isRequired` flag rather than redundant bottom-sheet buttons:
- **Per-Criterion**: A criterion marked as `isRequired` displays a mandatory red asterisk in the UI. The auditor must explicitly provide an answer or verify the item before the audit can be submitted.
- **Global Override ("Require Confirmation")**: The template-level `confirmCorrect` configuration acts as a master switch. When enabled, it forces **all** criteria to `isRequired = true` during the save payload generation, and locks the individual toggles in the Template Builder UI to "ON" to ensure transparency.
- This simplifies the auditor UX by unifying all validation under a single `isRequired` mechanism, rather than relying on disparate confirmation buttons.


## 5. Non-Scored and Flat Point Configurations (Builder Constraints)

To prevent novice users from creating mathematically invalid templates (e.g., trying to assign point deductions to a Survey), the Template Builder UI enforces strict **Smart Constraints** via the Blueprint Wizard.

When a template is created as 'No Score' (survey) or 'Flat Points' (checklist):
- **Sub-sections are Physically Disabled**: The `+ Add Sub-Section` button is greyed out. Surveys and checklists strictly enforce a flat, 2-level hierarchy (Sections → Criteria) to ensure quick field operation.
- **Scored Input Types are Greyed Out**: Users are blocked from selecting `pass_fail`, `numeric`, `fault_count`, or `scale` in the criterion designer.
- **Scoring Engine Bypass**: If `scoreDirection == ScoreDirection.none` (Survey), the scoring engine skips all calculation (`totalScore = null`). The live points HUD is hidden in the audit form, and the "Points Weight" input is completely hidden in the Template Builder to prevent UX confusion.
- **Answers stored normally** — `Answer.Value` holds the selected option label (or comma-separated for multi-choice)
- **Analytics endpoint**: `GET /api/submissions/survey-results?templateId={id}` — admin-only, aggregates option counts per criterion
- **Choice input types**: `single_choice` (pick one) and `multi_choice` (select all that apply) — options stored in `criteria.metadata` as `{"options": ["A","B","C"]}`
- **History badge**: Completed survey submissions show a purple **SURVEY** badge instead of a score

## 6. Technical Implementation

### Flutter Mobile (Primary)
- **Scoring Engine**: `lib/_shared/services/scoring_engine.dart`
- **Simple Accumulation Calculator**: `lib/_shared/services/accumulation_calculator.dart`
- **Weighted Accumulation Calculator**: `lib/_shared/services/weighted_accumulation_calculator.dart`
- **Penalty Calculator**: `lib/_shared/services/penalty_calculator.dart`
- **Checklist Calculator**: `lib/_shared/services/checklist_calculator.dart`
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
| `ScoringCalculators.cs` | Houses pure functions for calculation execution (`VerifyAccumulation`, `VerifyAccumulationWeighted`, `VerifyChecklist`, `VerifyPenalty`) |
| `ScoringConfigParser.cs` | Safe extraction of `scoreDirection`, `isWeighted`, and `progressiveRepeat` from JSON configs, with logging on parse failure to prevent silent fallbacks. |
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

These rules govern how users are assigned to stores.

### 1 Store Manager per Store
- Each store (`stores.id`) can have at most **1 user** with role `store_manager` assigned to it (`profiles.store_id`).
- **Enforced at**: Edge Function (`createUser`), `admin_update_user` RPC, UI (store selector hides occupied stores).

### Store Assignment (Area Managers)
- Each store (`stores.id`) can be assigned to at most **1 user** with role `area_manager` via the `profile_store_assignments` junction table.
- A single Area Manager can be assigned to multiple stores (1-to-Many).
- **Enforced at**: Unique index on `StoreId` in `ProfileStoreAssignmentConfiguration`, backend assignment endpoints, and UI store selectors.

### Technical References
- **Backend Endpoint**: `Features/Admin/UpdateUser.cs` — checks SM + AM conflicts before profile update.
- **Auth Guard**: `Common/Auth/RoleAssignmentGuard.cs` — enforces the 1 SM per store limit.
- **UI (Stores)**: `lib/features/admin/pages/store_management_page.dart` — assignment selectors.

### SM Transfer Protocol

When replacing a Store Manager (SM), open action plans must be transferred atomically:

- **Transfer Endpoint**: `Features/Admin/TransferStoreManager.cs` — atomic swap + AP transfer + audit log.
- **Guards** (defense-in-depth):
  - **Frontend** (UserManagement): Blocks role/store changes for active SMs; directs admin to Store Management.
  - **Frontend** (UserManagement): Blocks disabling active SM accounts.
  - **Backend** (`UpdateUser.cs`): Prevents changes to active SMs' stores via normal update.
  - **Backend** (`BanUser.cs`): Prevents banning active SMs.

---

## 8. Action Plan Lifecycle

> For action plan creation rules, status transitions, notifications, deadlines, and dashboard metric impact, see [CORE_WORKFLOWS.md](./CORE_WORKFLOWS.md).
