# Audit Template Engine — Complete Feature Scope & Architecture (V3)

**Date**: 2026-05-27 | **ShortID**: d1b5c2a2
**Status**: Approved & Reference Design (Updated to fully cover live C# and Dart codebase behaviors)

---

## 1. Overview & Business Goal

The **Audit Template Engine** is the backbone of Checkly. It allows business administrators to set up highly flexible checklist forms and custom scoring rules for store audits without writing any new code. 

### The Business Terminology Map
To prevent confusion between business language and technical database language, we use this direct mapping:
* **UI/Business Language**: Users see and talk about **Audits** (e.g., "Schedule Audit", "Store Audit", "Assign Audit to Auditor").
* **DB/Technical Code**: The database and API endpoints use the entity name **Submission** (e.g., `Submissions` table, `SubmissionSectionScores`, `CreateSubmission`).
* **UI/Business Language**: Users build **Audit Templates** with **Sections** and **Checkpoints**.
* **DB/Technical Code**: The database and API use **Template**, **Group**, and **Criterion** (e.g., `templates`, `groups`, and `criteria` tables).

---

## 2. System Architecture & Data Schema

Checkly uses a **Hierarchical Tree Structure** to model audit templates. This structure allows sections and subsections to be nested infinitely.

```
 [Template]
     │
     └───► [Group 1: Front of House] (Root Section)
     │         │
     │         ├───► [Criterion 1.1: Staff Uniforms] (Checkpoint/Question)
     │         │
     │         └───► [Subgroup 1.A: Cleanliness Detail] (Subsection)
     │                   │
     │                   └───► [Criterion 1.A.1: Floor Cleanliness]
     │
     └───► [Group 2: Back of House] (Root Section)
```

### Database Entity Schema (ERD)

```
┌───────────────────────────────────────┐
│               Template                │
├───────────────────────────────────────┤
│ Id (PK) - UUID                        │
│ Title - string                        │
│ Description - string (nullable)       │
│ Type - string ('QC', 'Training')      │
│ Version - int (for concurrency)       │
│ ScoringLogicConfig - jsonb string     │
│ DisplayNoun - string ('Audit', etc.)  │
│ IsActive - boolean                    │
│ CreatedBy - UUID (nullable)           │
│ CreatedAt - DateTimeOffset            │
│ UpdatedAt - DateTimeOffset            │
│ RowVersion - uint (concurrency)       │
└──────────────────┬────────────────────┘
                   │ 1
                   │
                   │ N
┌──────────────────▼────────────────────┐
│                 Group                 │
├───────────────────────────────────────┤
│ Id (PK) - UUID                        │
│ TemplateId (FK) - UUID                │
│ ParentId (FK) - UUID (Self-Ref, null) ◄── Allows infinite subsection nesting
│ Title - string                        │
│ Description - string (nullable)       │
│ Weight - decimal (nullable)           │
│ MaxDeductionPoints - decimal (null)   │
│ MinusPerFault - decimal (nullable)    │
│ OrderIndex - int                      │
│ Metadata - string (jsonb nullable)    ◄── Stores 'subsection_max_points', 'minus_per_fault'
│ IsActive - boolean                    │
│ CreatedAt - DateTimeOffset            │
│ UpdatedAt - DateTimeOffset            │
└──────────────────┬────────────────────┘
                   │ 1
                   │
                   │ N
┌──────────────────▼────────────────────┐
│               Criterion               │
├───────────────────────────────────────┤
│ Id (PK) - UUID                        │
│ GroupId (FK) - UUID                   │
│ Label - string                        │
│ Description - string (nullable)       │
│ InputType - string                    ◄── 'pass_fail', 'scale', 'numeric', 'single_choice', 'multi_choice', 'text'
│ PointsWeight - decimal (nullable)     │
│ IsCcp - boolean (Critical Control Pt) │
│ IsRisk - boolean (Fatal Zero Risk)    │
│ MinusImpact - decimal (nullable)      │
│ MaxDeductionPoints - decimal (null)   │
│ OrderIndex - int                      │
│ Metadata - string (jsonb nullable)    ◄── Stores 'isRequired', 'scaleOptions', 'options'
│ IsActive - boolean                    │
│ CreatedAt - DateTimeOffset            │
│ UpdatedAt - DateTimeOffset            │
└───────────────────────────────────────┘
```

### Group Content Mutual Exclusivity Invariant
To keep the engine predictable during scoring evaluation, the backend and frontend enforces a strict **mutual exclusivity invariant** for Groups: 
* A Group can contain `Criteria` (checkpoints).
* **OR** a Group can contain `Children` (subsections).
* A Group **must never** contain both at the same level.

### Tree Constraints & Reconciliation Patterns
When submitting or updating a template tree:
* **Hard Scale Limits**: The backend enforces strict validation limits to prevent performance bottlenecks or database timeouts. An upsert tree payload can contain a maximum of **200 Groups** and **2000 Criteria**.
* **Soft-Delete Reconciliation**: The `PUT /api/templates/{id}/tree` endpoint uses a soft-deletion reconciliation pattern. Any existing `Group` or `Criterion` omitted from the payload is set to `IsActive = false` instead of performing a hard SQL delete. This preserves historic database integrity and prevents foreign key violations with existing submissions.
* **Optimistic Concurrency Control**: The backend maps the PostgreSQL system column `xmin` to the `RowVersion` entity field in `Template.cs`. Concurrent updates on the tree throw `DbUpdateConcurrencyException`, returning a HTTP 409 Conflict.

---

## 3. Score Processing Logic

Before scores are processed under the respective scoring modes, the engine performs initial safety and consistency evaluations:

```
[Submission Request] ──► [RISK Check: Template & Answer overrides] ──► (Triggered?) ──► Yes ──► [Score = 0%]
                                      │
                                      No
                                      ▼
                      [Purity Gate: All measurable criteria > 0 pts?] ──► (No/Mixed?) ──► Yes ──► [Score = null]
                                      │
                                      Yes
                                      ▼
                      [Run Scoring Engine (Penalty, Checklist, Accumulation, Survey)]
```

### Safety & Guardrails (CCP & RISK Contracts)

To enforce strict operating standards, the engine supports two levels of operational severity flags:

#### 1. Critical Control Points (CCP) — Section Disqualification
* **Purpose**: Disqualify a specific operational section if a vital standard is missed.
* **Example**: If a store fails "Clean Water Supply" (CCP), the entire "Food Safety" section receives a zero score. However, its weight is **retained in the denominator** of the final average to penalize the score overall.
* **Two-Path CCP Activation Contract**:
  1. **Template-Defined CCP**: Checkpoints with `IsCcp = true` on the template will trigger the section score to 0% **only if there is an active fault** (e.g., the answer is evaluated as non-conforming).
  2. **Auditor Manual Override CCP**: Auditors can manually flag *any* checkpoint answer as `IsCcp = true` at audit time. This triggers the section 0% score **unconditionally**, even if the checkpoint answer was otherwise passing.

#### 2. High Risk (RISK) — Instant Total Failure
* **Purpose**: Force the entire audit score to 0% immediately.
* **Example**: If an auditor discovers expired food being used, the overall audit score is instantly forced to 0% regardless of other high-scoring sections.
* **Three-Path RISK Activation Contract**:
  1. **Template-Defined RISK**: Checkpoints marked as `IsRisk = true` on the template will trigger the zero-score rule **only if the answer has a fault** (e.g., the auditor selects "FAIL" or "NO").
  2. **Auditor Manual Override RISK**: Auditors can manually flag *any* checkpoint answer as `IsRisk = true` at audit time. This triggers the zero-score rule **unconditionally** (even if the checkpoint answer was otherwise passing).
  3. **Global Risk Domain Event**: When a global compliance issue is triggered (creating a `SubmissionRisk` entry in the `submission_risks` table), the overall audit score is forced to 0% **unconditionally**.

---

### The Purity Gate (Mixed Audits)
* **Rule**: If a template contains a mixture of scored (points weight > 0) and unscored (points weight = 0 or null) measurable checkpoints (e.g., `pass_fail`, `numeric`, `scale`), the audit is treated as a **Mixed Audit**.
* **Result**: The final score is set to `null` to prevent misleading averages.
* **Exceptions**: Survey mode does not trigger purity checks.

---

## 4. The Four (4) Flexible Scoring Engines

These modes are controlled by a simple JSON configuration (`scoringLogicConfig`) on the template.
Example `scoringLogicConfig`:
```json
{
  "scoringMode": "penalty",
  "ccpOverride": true,
  "riskOverride": true,
  "weightedDensity": false,
  "progressiveRepeat": true,
  "confirmCorrect": true,
  "deadlineDays": 7,
  "reminderDays": 2
}
```

### Mode 1: Penalty Mode (`penalty`) - The Executive Standard
* **How it works**: Every section starts at 100%. Faults (failed checkpoints) deduct points. Section ratios are then multiplied by their section weights to calculate the final average.
* **Mathematical Formula**:
  $$\text{Deduction} = \text{Faults} \times \text{Impact}$$
  (where $\text{Impact}$ is $\text{MinusImpact} \text{ if set, else } \text{PointsWeight}$)
  
  $$\text{Section Score} = \max\left(0, \text{Section Max Points} - \sum \text{Deductions}\right)$$
  $$\text{Section Ratio} = \frac{\text{Section Score}}{\text{Section Max Points}}$$
  $$\text{Final Audit Score} = \frac{\sum (\text{Section Ratio} \times \text{Section Weight})}{\sum \text{Section Weights}} \times 100$$

### Mode 2: Accumulation Mode (`accumulation`) - Positive Reinforcement
* **How it works**: The audit starts at 0%. Points are added for each compliant (passed) checkpoint up to the maximum possible points.
* **Mathematical Formula**:
  $$\text{Final Score} = \frac{\sum \text{Points of Passed Checkpoints}}{\sum \text{Total Points Weight of All Checkpoints}} \times 100$$
* **Dual-Layer Telemetry Fields**: To support granular data analysis, the engine captures raw scoring aggregates and persists them directly within the `Submission` database record:
  * `RawEarnedPoints` (decimal): Sum of passed checkpoint points.
  * `RawMaxPoints` (decimal): Sum of all eligible checkpoint points.
  * `IsWeighted` (boolean): Flat indicator showing whether section weight groups were applied during evaluation.

### Mode 3: Checklist Mode (`checklist`) - Flat Deductions
* **How it works**: The audit starts at 100. Any failed checkpoint deducts points directly from the total 100, without any section-weight grouping.
* **Deduction and Repeat Penalty calculation**:
  * **Base Deduction**: $\text{Faults} \times \text{Impact}$
  * **Repeat Deduction**:
    * **If Progressive Repeat is ON**: $\text{RepeatedFaults}^2 \times \text{Impact}$
    * **If Progressive Repeat is OFF**: $\text{RepeatedFaults} \times \text{Impact}$
  * **Total Deduction per checkpoint** is capped at `MaxDeductionPoints` (if defined).
* **Mathematical Formula**:
  $$\text{Final Score} = \max\left(0, 100 - \sum (\text{Checkpoint Total Deduction})\right)$$

### Mode 4: Survey Mode (`survey`) - Qualitative Feedback
* **How it works**: No mathematical scores are computed.
* **Result**: The final score evaluates to `null` in the database.

---

## 5. System Database Telemetry & Access Controls

### Answer-Level Failure Telemetry
* **Semantic Failure Flag (`IsFailure`)**: The database answer entity has an automated boolean `IsFailure` flag. This flag is automatically computed by the server during submission finalization. It marks an answer as a semantic failure if its checkpoint is in `ScoringVerifier.FailedCriteriaIds` (excluding unscored input types like `text` or metadata) to support back-office analytics dashboards.

### Sync Access Control Rules
* **Sync Permissions Filter**: Non-admin users are strictly filtered when downloading or listing templates via `/api/sync/templates?since={timestamp}` and `/api/templates`. They can only pull or view templates that are either:
  1. Completely unassigned (Global templates).
  2. Assigned to a User Group that the auditor is a member of.

---

## 6. System API Specifications

All template operations are performed through transactional, secure Minimal API endpoints:

### 1. Template Management & CRUD
* `GET /api/templates` — List active templates (Non-admins are restricted to templates assigned to their user groups or unassigned templates).
* `GET /api/templates/{id}` — Retrieve full template structure.
* `POST /api/templates` — Create a new draft template.
* `PUT /api/templates/{id}` — Update general template properties (Title, Description, Noun, etc.).
* `DELETE /api/templates/{id}` — Soft-delete a template (Sets `IsActive = false`).

### 2. Atomic Tree Upsert
* **Route**: `PUT /api/templates/{id}/tree`
* **Purpose**: Saves the entire tree of sections, subsections, and checkpoints in a single transactional database call, soft-deleting any removed items.

### 3. Template Cloning
* **Route**: `POST /api/templates/{id}/clone`
* **Purpose**: Duplicates an entire template tree (including all nested groups and criteria) to create a new draft template.

### 4. User Group Assignments
* **Route**: `PUT /api/templates/{id}/assignments`
* **Purpose**: Assigns the template to specific user groups, enforcing robust access control.

### 5. Template Sync (Offline-First)
* **Route**: `GET /api/sync/templates?since={timestamp}`
* **Purpose**: Allows offline Flutter devices to download all new or modified templates, groups, and criteria created since their last online session (Access control rules apply).
* **Offline Cache Gotcha (Display Noun)**: In the offline-first SQLite database (using Drift in `lib/_shared/database/tables.dart`), the local cache table `CachedTemplates` does **not** persist `DisplayNoun` (this property is only kept in memory via `TemplateDto` and `TemplateTreeDto` when fetched live). Offline client UIs naturally fallback to the standard 'Audit' terminology or use local defaults.

---

## 7. Seeded Templates (Maycha System)

Checkly provides **two (2) active templates** by default:

1. **`[MAYCHA] TnD Store Visit - In Person`** (Quality Control - `qc`)
   * A comprehensive, real-world store inspection template containing Front of House, Back of House, Product Standards, and Operation Focus groups with 40+ specific checkpoints.
2. **`[MAYCHA] TnD Store Visit - Camera`** (Training - `training`)
   * A streamlined 5-point training template designed for video review or remote camera audits.
