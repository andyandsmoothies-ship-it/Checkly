# Audit Template Engine — Complete Feature Scope & Architecture (V4)

**Date**: 2026-05-27 | **ShortID**: a2b3c4d5
**Status**: Approved & Reference Design (Updated to include CAPA, Tagging, Snapshotting, and N/A Math)

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
│ CategoryTags - string array (null)    ◄── Cross-template analytics tags (e.g. ['Food Safety'])
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
│ InputType - string                    ◄── 'pass_fail', 'scale', 'numeric', 'single_choice', 'multi_choice', 'text', 'photo', 'signature', 'barcode'
│ CategoryTags - string array (null)    ◄── Cross-template tagging for granular analytics
│ PointsWeight - decimal (nullable)     │
│ IsCcp - boolean (Critical Control Pt) │
│ IsRisk - boolean (Fatal Zero Risk)    │
│ MinusImpact - decimal (nullable)      │
│ MaxDeductionPoints - decimal (null)   │
│ OrderIndex - int                      │
│ Metadata - string (jsonb nullable)    ◄── 'isRequired', 'options', 'requirePhotoOnFail', 'requireActionPlanOnFail', 'showIf' (Branching)
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

## 3. Advanced Configuration (CAPA, Branching, Analytics)

### Remediation & Action Plans (CAPA)
The engine supports mandatory Corrective and Preventive Actions (CAPA) triggered upon checkpoint failure. These are configured via the Criterion's `Metadata` JSON:
* `requirePhotoOnFail: true` — The auditor cannot finalize the submission without attaching a photo to this answer.
* `requireCommentOnFail: true` — A textual explanation must be provided.
* `requireActionPlanOnFail: true` — Forces the auditor to spawn a tracked "Action Plan / Task" for the store manager to resolve.

### Cross-Template Category Tagging
To support unified boardroom analytics (BOD) where executives want to see "Food Safety" across *all* active templates, the system relies on `CategoryTags`.
* Both `Group` and `Criterion` support a string array of tags.
* This allows analytics endpoints to query flat sections grouped by explicit tags, preventing data fragmentation when admins rename sections in the UI.

### Branching & Conditional Logic
To keep offline sync lightweight, the engine employs a "Linear by Default, Branched by Metadata" strategy.
* Checkpoints can contain a `showIf` condition in their `Metadata`. 
* Example: `{"showIf": {"criterionId": "uuid-1234", "operator": "equals", "value": "FAIL"}}`.
* The Flutter frontend parses this metadata at runtime to dynamically hide/show checkpoints based on state.

---

## 4. Score Processing Logic

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

#### 1. Critical Control Points (CCP) — Section Disqualification
* **Purpose**: Disqualify a specific operational section if a vital standard is missed.
* **Two-Path CCP Activation Contract**:
  1. **Template-Defined CCP**: Checkpoints with `IsCcp = true` trigger section score to 0% **only if there is an active fault**.
  2. **Auditor Manual Override CCP**: Auditors can manually flag *any* checkpoint answer as `IsCcp = true`, triggering 0% **unconditionally**.

#### 2. High Risk (RISK) — Instant Total Failure
* **Purpose**: Force the entire audit score to 0% immediately.
* **Three-Path RISK Activation Contract**:
  1. **Template-Defined RISK**: `IsRisk = true` on the template triggers zero-score **only if there is a fault**.
  2. **Auditor Manual Override RISK**: Auditors can manually flag *any* checkpoint answer as `IsRisk = true`, triggering zero-score **unconditionally**.
  3. **Global Risk Domain Event**: When a global compliance issue is triggered, the overall audit score is forced to 0% **unconditionally**.

### The Purity Gate (Mixed Audits)
* **Rule**: If a template contains a mixture of scored (points weight > 0) and unscored (points weight = 0 or null) measurable checkpoints (e.g., `pass_fail`, `numeric`, `scale`), the audit is treated as a **Mixed Audit**.
* **Result**: The final score is set to `null` to prevent misleading averages.

### Handling "Not Applicable" (N/A) Math
When an auditor marks a scored checkpoint as N/A:
* The checkpoint is excluded from being a fault.
* **Dynamic Denominator**: The checkpoint's `PointsWeight` is dynamically **subtracted** from the `RawMaxPoints` (the denominator) for the section. This ensures the store is neither penalized nor rewarded for checkpoints they cannot control.

---

## 5. The Four (4) Flexible Scoring Engines

### Mode 1: Penalty Mode (`penalty`) - The Executive Standard
* **How it works**: Every section starts at 100%. Faults deduct points. Section ratios are multiplied by their section weights to calculate the final average.
* **Mathematical Formula**:
  $$\text{Deduction} = \text{Faults} \times \text{Impact}$$
  $$\text{Section Score} = \max\left(0, \text{Section Max Points} - \sum \text{Deductions}\right)$$
  $$\text{Section Ratio} = \frac{\text{Section Score}}{\text{Section Max Points}}$$
  $$\text{Final Audit Score} = \frac{\sum (\text{Section Ratio} \times \text{Section Weight})}{\sum \text{Section Weights}} \times 100$$

### Mode 2: Accumulation Mode (`accumulation`) - Positive Reinforcement
* **How it works**: Starts at 0%. Points are added for each compliant (passed) checkpoint up to the maximum possible points.
* **Mathematical Formula**:
  $$\text{Final Score} = \frac{\sum \text{Points of Passed Checkpoints}}{\sum \text{Total Points Weight of Eligible Checkpoints}} \times 100$$
* **Dual-Layer Telemetry Fields**:
  * `RawEarnedPoints`: Sum of passed checkpoint points.
  * `RawMaxPoints`: Sum of all eligible checkpoint points (dynamically adjusted for N/A answers).
  * `IsWeighted`: Flat indicator showing whether section weight groups were applied.

### Mode 3: Checklist Mode (`checklist`) - Flat Deductions
* **How it works**: Starts at 100. Any failed checkpoint deducts points directly from the total 100, without any section-weight grouping.
* **Deduction and Repeat Penalty calculation**:
  * **Base Deduction**: $\text{Faults} \times \text{Impact}$
  * **Repeat Deduction**:
    * **Progressive ON**: $\text{RepeatedFaults}^2 \times \text{Impact}$
    * **Progressive OFF**: $\text{RepeatedFaults} \times \text{Impact}$

### Mode 4: Survey Mode (`survey`) - Qualitative Feedback
* **How it works**: No mathematical scores are computed.
* **Result**: Final score evaluates to `null`.

---

## 6. System Database Telemetry & Access Controls

### Answer-Level Failure Telemetry
* **Semantic Failure Flag (`IsFailure`)**: The database answer entity has an automated boolean `IsFailure` flag, calculated by checking if the checkpoint is in `ScoringVerifier.FailedCriteriaIds`.

### Template Publishing Lifecycle & Snapshots
To protect historical records from schema drift when administrators edit live templates:
* **The Snapshot Contract**: When an auditor starts an audit (Submission), the backend creates a deeply nested JSON document (`TemplateSnapshot`) inside the `Submission` record. 
* This snapshot permanently freezes the Group Names, Criteria Weights, and Rules exactly as they were at that millisecond.
* All scoring math relies on the `TemplateSnapshot`, never the live relational `Template` tables. 
* **Publishing**: `PUT /api/templates/{id}/tree` edits the live template immediately for all *future* audits, but historic audits remain strictly locked to their snapshots.

### Sync Access Control Rules
* **Sync Permissions Filter**: Non-admin users are strictly filtered when downloading or listing templates via `/api/sync/templates?since={timestamp}` and `/api/templates`. They can only pull or view templates that are either unassigned (Global templates) or assigned to their User Group.

---

## 7. System API Specifications

All template operations are performed through transactional, secure Minimal API endpoints:

### 1. Template Management & CRUD
* `GET /api/templates` — List active templates.
* `GET /api/templates/{id}` — Retrieve full template structure.
* `POST /api/templates` — Create a new draft template.
* `PUT /api/templates/{id}` — Update general template properties.
* `DELETE /api/templates/{id}` — Soft-delete a template (Sets `IsActive = false`).

### 2. Atomic Tree Upsert
* **Route**: `PUT /api/templates/{id}/tree`
* **Purpose**: Saves the entire tree of sections, subsections, and checkpoints in a single transactional database call, soft-deleting any removed items.

### 3. Template Cloning
* **Route**: `POST /api/templates/{id}/clone`
* **Purpose**: Duplicates an entire template tree.

### 4. User Group Assignments
* **Route**: `PUT /api/templates/{id}/assignments`
* **Purpose**: Assigns the template to specific user groups.

### 5. Template Sync (Offline-First)
* **Route**: `GET /api/sync/templates?since={timestamp}`
* **Purpose**: Allows offline Flutter devices to download all new or modified templates.

---

## 8. Seeded Templates (Maycha System)

Checkly provides **two (2) active templates** by default:
1. **`[MAYCHA] TnD Store Visit - In Person`** (Quality Control - `qc`)
2. **`[MAYCHA] TnD Store Visit - Camera`** (Training - `training`)
