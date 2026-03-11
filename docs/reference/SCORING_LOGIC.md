# Checkly Penalty-based Scoring System (Unified Penalty Model)

This document describes the technical implementation and business rules for the **Deduction (Penalty) Mode** scoring logic, which is the unified standard for all template types (QC, Training, General) in Checkly Smart.

## 1. Hierarchy & Structure

The scoring logic operates on a three-level hierarchy:
1.  **Section (Top-Level Group)**: Has a "Density Weight" (Percentage of the total audit score).
2.  **Subsection (Sub-Group)**: Has "Max Points" (Absolute contribution to the section points).
3.  **Criteria (Audit Item)**: Has "Minus Per Fault" and "Penalty Weights".

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

### ⚠️ RISK
- **Trigger**: Any criteria with `is_risk = true` is marked as "Fail" or has > 0 faults.
- **Scope**: **Audit-Level**.
- **Impact**:
    - The **Final Audit Score** is forced to **0%**.
    - All absolute points earned are forced to **0**.
    - This reflects a fundamental failure that invalidates the entire audit.

---

## 4. Points HUD Logic (Live Feedback)
The live HUD in the Audit Form displays "Points Earned / Points Possible".
- **Points Possible**: `SUM(All Subsection Max Points)`
- **Points Earned**: `SUM(Section After)` (where `Section After` is forced to 0 if a CCP is present in that section).

> [!IMPORTANT]
> **Unified Mode Enforcement**: All templates are forced to `scoring_type: 'penalty'`. Accumulation-based scoring (Standard Mode) is deprecated to ensure a consistent UX where every audit starts at a perfect score.


## 5. Technical Implementation
- **Source Code**: [scoringEngine.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/lib/scoringEngine.ts)
- **Hook**: [useAuditScoring.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/hooks/useAuditScoring.ts)
- **Database Persistence**: [finalize_audit RPC](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/migrations/20260220_score_verification_enforce.sql)
- **Server Verification**: [verify-score Edge Function](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/functions/verify-score/index.ts) — re-computes score server-side

### Score Verification (Phase 2: Enforce)

The `finalize_audit` RPC includes **synchronous server-side score verification**. After answers are upserted, the RPC calls the `verify-score` Edge Function (via the `http` extension) which re-computes the score independently. If the server score diverges from the client score by >5%, the submission is **rejected**.

| Component | Purpose |
|:---|:---|
| `verify-score` Edge Function | Inlines the scoring engine, re-computes from template + answers |
| `extensions.http_post()` | Synchronous HTTP call within the RPC transaction |
| Vault: `score_verification_mode` | Kill switch (`observe` = log only, `enforce` = block) |
| `system_logs` category `SCORING_MISMATCH_REJECTED` | Logged when a submission is rejected |

> [!WARNING]
> Submissions with spoofed scores (>5% delta) are rejected. The Phase 1 async trigger (`pg_net`) also logs all mismatches as a redundant safety net.

---

## 6. Assignment Rules (SM / AM Constraints)

These rules govern how users are assigned to stores and areas.

### Valid Areas
Only 5 area codes are allowed: `North`, `South`, `Central`, `East`, `West`.

> [!IMPORTANT]
> These areas are currently hardcoded in `UserManagement.tsx` and `StoreManagement.tsx`.
> If you add/remove areas in the future, update BOTH files.

### 1 Store Manager per Store
- Each store (`stores.id`) can have at most **1 user** with role `store_manager` assigned to it (`profiles.store_id`).
- **Enforced at**: Edge Function (`createUser`), `admin_update_user` RPC, UI (store selector hides occupied stores).

### 1 Area Manager per Area
- Each area code can have at most **1 user** with role `area_manager` assigned to it (`profiles.area_code`).
- **Enforced at**: Edge Function (`createUser`), `admin_update_user` RPC, UI (area selector hides occupied areas).

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

## 7. Action Plan Lifecycle

> For action plan creation rules, status transitions, notifications, deadlines, and dashboard metric impact, see [CORE_WORKFLOWS.md](./CORE_WORKFLOWS.md).
