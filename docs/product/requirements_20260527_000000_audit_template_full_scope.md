# Audit Template Engine — Complete Feature Scope & Architecture

**Date**: 2026-05-27 | **ShortID**: d1b5c2a1
**Status**: Approved & Reference Design

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

### Database Entity Relationships (ERD)

```
┌───────────────────────────────────────┐
│               Template                │
├───────────────────────────────────────┤
│ Id (PK) - UUID                        │
│ Title - string                        │
│ Description - string (nullable)       │
│ Type - string ('qc', 'training', etc.)│
│ Version - int (for concurrency)       │
│ ScoringLogicConfig - jsonb string     │
│ DisplayNoun - string ('Audit', etc.)  │
│ IsActive - boolean                    │
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
│ Weight - decimal (nullable)           │
│ MaxDeductionPoints - decimal (null)   │
│ MinusPerFault - decimal (nullable)    │
│ OrderIndex - int                      │
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
│ InputType - string ('pass_fail', etc.)│
│ PointsWeight - decimal (nullable)     │
│ IsCcp - boolean (Critical Control Pt) │
│ IsRisk - boolean (Fatal Zero Risk)    │
│ MinusImpact - decimal (nullable)      │
│ MaxDeductionPoints - decimal (null)   │
│ OrderIndex - int                      │
└───────────────────────────────────────┘
```

---

## 3. The Four (4) Flexible Scoring Engines

Checkly supports four distinct audit scoring modes. These are controlled by a simple JSON configuration (`scoringLogicConfig`) on the template, such as `{"scoringMode": "penalty", "progressiveRepeat": true}`.

### Mode 1: Penalty Mode (`penalty`) - The Executive Standard
* **How it works**: Every section starts at 100%. Faults (failed checkpoints) deduct points. Section scores are then multiplied by their section weights to calculate the final average.
* **Special Rule (CCP Section Exclusion)**: If a Critical Control Point (CCP) checkpoint fails inside a section, the **entire section** is immediately excluded from the score (both numerator and denominator are skipped).
* **Mathematical Formula**:
  $$\text{Section Score} = \max\left(0, 1.0 - \sum \text{Deductions}\right)$$
  $$\text{Final Audit Score} = \frac{\sum (\text{Section Score} \times \text{Section Weight})}{\sum \text{Participating Section Weights}} \times 100$$

### Mode 2: Accumulation Mode (`accumulation`) - Positive Reinforcement
* **How it works**: The audit starts at 0%. Points are added for each compliant (passed) checkpoint up to the maximum possible points.
* **Typical Use Case**: Video review or training audits (like camera audits), where staff earn points for each good behavior completed.
* **Mathematical Formula**:
  $$\text{Final Score} = \frac{\sum \text{Points of Passed Checkpoints}}{\sum \text{Total Points Weight of All Checkpoints}} \times 100$$

### Mode 3: Checklist Mode (`checklist`) - Flat Deductions
* **How it works**: The audit starts at 100. Any failed checkpoint deducts points directly from the total 100, without any section-weight grouping.
* **Special Feature (Progressive Repeat Penalty)**: If the same type of fault is made multiple times, the penalty grows exponentially ($N^2 \times \text{Rate}$) rather than linearly ($N \times \text{Rate}$).
* **Mathematical Formula**:
  $$\text{Final Score} = \max\left(0, 100 - \sum (\text{Failed Checkpoint Penalty})\right)$$

### Mode 4: Survey Mode (`survey`) - Qualitative Feedback
* **How it works**: No mathematical scores are computed.
* **Result**: The final score evaluates to `null` in the database.
* **Typical Use Case**: Qualitative audits, general comments, or gathering customer feedback.

---

## 4. Safety & Guardrails (CCP & RISK)

To enforce strict operating standards, the engine supports two levels of operational severity flags:

### 1. Critical Control Points (CCP) — Section Disqualification
* **Purpose**: Disqualify a specific operational section if a vital standard is missed.
* **Example**: If a store fails "Clean Water Supply" (CCP), the entire "Food Safety" section receives a zero score and is removed from the audit average calculations.

### 2. High Risk (RISK) — Instant Total Failure
* **Purpose**: Force the entire audit score to 0% immediately.
* **Example**: If an auditor discovers expired food being used, the overall audit score is instantly forced to 0% regardless of other high-scoring sections.

### Two-Path Risk Activation Contract
The system evaluates RISK through two distinct triggers:
1. **Template-Defined RISK**: Checkpoints marked as `IsRisk = true` on the template will trigger the zero-score rule **only if the answer has a fault** (e.g., the auditor selectes "FAIL" or "NO").
2. **Auditor Manual Override RISK**: Auditors can manually flag *any* checkpoint as an active RISK at audit time. This triggers the zero-score rule **unconditionally** (even if the checkpoint answer was otherwise passing), allowing supervisors to escalate special scenarios.

---

## 5. System API Specifications

All template operations are performed through unified, transaction-safe REST endpoints on the C# Minimal API:

### 1. Atomic Tree Upsert
* **Route**: `PUT /api/templates/{id}/tree`
* **Purpose**: Saves the entire tree of sections, subsections, and checkpoints in a single transactional database call, soft-deleting any removed items.
* **Request Payload (`SaveTreeRequest`)**:
```json
{
  "title": "[MAYCHA] TnD Store Visit - In Person",
  "type": "qc",
  "description": "Standard in-person store audit",
  "scoringLogicConfig": "{\"scoringMode\":\"penalty\",\"progressiveRepeat\":false}",
  "displayNoun": "Audit",
  "version": 1,
  "groups": [
    {
      "id": "group-guid",
      "title": "FRONT OF HOUSE",
      "description": "Customer areas",
      "weight": 0.40,
      "maxDeductionPoints": 10.0,
      "minusPerFault": 2.0,
      "orderIndex": 0,
      "children": [],
      "criteria": [
        {
          "id": "criteria-guid",
          "label": "Staff Uniforms tidy & compliant",
          "inputType": "pass_fail",
          "pointsWeight": 1.0,
          "isCcp": false,
          "isRisk": false,
          "minusImpact": 1.0,
          "orderIndex": 0
        }
      ]
    }
  ]
}
```

### 2. Template Cloning
* **Route**: `POST /api/templates/{id}/clone`
* **Purpose**: Duplicates an entire template tree (including all nested groups and criteria) to create a new draft template.

### 3. Template Sync (Offline-First)
* **Route**: `GET /api/templates/sync?since={timestamp}`
* **Purpose**: Allows offline Flutter devices to download all new or modified templates created since their last online session.

---

## 6. Seeded Templates (Maycha System)

In our current database configuration, Checkly provides **two (2) active templates** by default:

1. **`[MAYCHA] TnD Store Visit - In Person`** (Quality Control - `qc`)
   * A comprehensive, real-world store inspection template containing Front of House, Back of House, Product Standards, and Operation Focus groups with 40+ specific checkpoints.
2. **`[MAYCHA] TnD Store Visit - Camera`** (Training - `training`)
   * A streamlined 5-point training template designed for video review or remote camera audits, checking staff readiness, App controls, BOH processes, and general shift manager performance.
