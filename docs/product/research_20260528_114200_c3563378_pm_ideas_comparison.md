# Product Research: Boardroom Analytics Standardization Strategies

**Date**: 2026-05-28 | **ShortID**: c3563378
**Topic**: PM Strategic Comparison (Idea 1 vs Idea 2)
**Status**: Research & Evaluation Phase

---

## 1. Executive Summary & Strategy Map

When selling Checkly to multiple distinct markets (Quick Service Restaurants, Retail, Hospitality, Manufacturing), we face a conflict: **operations teams want custom, dynamic checklists**, while **executives want uniform boardroom metrics**.

This document compares two strategic product management approaches to solve this issue:
* **Idea 1: The "Universal Translator"** (translates input checkpoints into unified category percentages).
* **Idea 2: "Golden Output Metrics"** (standardizes overall output data and separates templates by archetype).

### Dynamic Strategy Flowchart

```
                 [Dynamic Multi-Market Checklists]
                                │
        ┌───────────────────────┴───────────────────────┐
        ▼                                               ▼
  [Idea 1: Input Translator]                     [Idea 2: Golden Outputs]
  - Calculates Tag Compliance                    - Tracks Completion % & TTR
  - Checkpoint-level mapping                     - Archetype-level segregation
  - High complexity, unified scores              - Low complexity, standard metrics
```

---

## 2. Detailed Breakdown of Each Idea

### Idea 1: The "Universal Translator" (Checkpoint Compliance)
Idea 1 focuses on standardizing the **internal checklist items (the input)**. It uses a fine-grained category mapping system at the checkpoint level.

* **Core Scoring Formula**:
  $$\text{Compliance Ratio} = \frac{\text{Number of Passed Checkpoints with Tag X}}{\text{Total Answered Checkpoints with Tag X (excluding N/A)}} \times 100$$
* **Geographical Scope**: Restricts dashboard filters to native `Province ──► District` boundaries to guarantee high query performance.
* **Audit Type Segregation**: Introduces a clean **Audit Type Selector** at the top of the Boardroom Dashboard:
  * **Quality Audits**: Shows average scores (0-100%).
  * **Operational Checklists**: Shows completion rates (0-100%).
  * **Surveys**: Shows qualitative counts.
* **Performance Control**: Utilizes static pre-computed snapshots by default (loaded in <50ms) to ensure premium speed, running live SQL queries only when filters are active.

---

### Idea 2: Standardize the Output (Golden Metrics & MVP focus)
Idea 2 focuses on standardizing the **final results of the submission (the output)**. It leaves the dynamic internal checklists as they are and tracks only universal business metrics.

* **Golden Metrics Model**:
  * **Completion Rate**: Did they finish it?
  * **Time To Resolve (TTR)**: How fast are issues fixed?
  * **Compliance Status**: Pass / Fail / Flagged counts.
* **Template Archetypes**: Explicitly groups templates into three isolated bins:
  * **Scored Audits** (generates a 0-100 average score).
  * **Task Campaigns** (generates a 0-100% completion rate).
  * **Fault Logs** (generates raw issue counts).
  The dashboard automatically filters charts so these archetypes are never mixed together.
* **Tag-based Filtering**: Relies on tag-level filters to let customers categorize their own dashboards, shifting taxonomy management to the user.
* **The "Wait for the Scream" Roadmap**: Aggressively drops pending features (like Tap-to-Filter on charts or extra date/template filtering APIs) for the MVP. Focuses entirely on stabilizing the core metrics.

---

## 3. Comparison Table: Idea 1 vs. Idea 2

| Dimension | Idea 1: "Universal Translator" | Idea 2: "Golden Output Metrics" |
| :--- | :--- | :--- |
| **Primary Focus** | **Internal Inputs**: Standardizes checkpoint-level tags. | **External Outputs**: Standardizes high-level results. |
| **Mathematical Metric** | **Compliance Ratio**: Percent of passed tagged checks. | **Completion % / TTR / Issue Counts**: Classic operational KPIs. |
| **User Experience** | Rich, detailed views into cross-template categories (e.g. "Hygiene"). | Simplified, clean dashboards that focus on task resolution. |
| **Backend Complexity** | **High**: Requires deep JSON parsing and checkpoint counting. | **Low**: Standardizes simple column aggregates. |
| **SaaS Scalability** | **Medium**: Customers must tag checklists perfectly. | **High**: Works instantly out-of-the-box for any market. |
| **MVP Scope** | **Medium**: Requires adding the Audit Type Selector UI. | **Lean**: Deletes complex pending features; focuses on stability. |

---

## 4. Areas of Complete Agreement (Shared Core Principles)

Both ideas share foundational product principles. These represent the **"Checkly Architectural Law"**:

1. **Leveraging Category Tags**: Both strategies agree that `CategoryTags` are the most powerful weapon to organize dynamic structures without changing the database schema.
2. **Segmenting Work Types**: Both agree that mixing different styles of work (like a qualitative survey and a graded safety audit) on the same score chart is mathematically incorrect and must be forbidden.
3. **Native Geographical Filtering**: Both agree on standardizing regional boundaries to `Province ──► District` using the pre-existing `StoreAddress` data.
4. **Caching & Speed**: Both agree that the dashboard must load instantly using nightly cached pre-computed snapshots, protecting PostgreSQL database performance.

---

## 5. Areas of Disagreement (Divergences)

The two ideas diverge on **how to measure compliance** and **how fast to build**:

```
                       [How to Standardize?]
                                 │
            ┌────────────────────┴────────────────────┐
            ▼                                         ▼
   [Checkpoint Tag Ratio]                    [Universal Golden Metrics]
   - Idea 1 Method                           - Idea 2 Method
   - Deep and detailed                       - High-level and operational
   - Harder to code                          - Simpler to scale
```

1. **Math Granularity**:
   * **Idea 1** calculates detailed percentages *inside* the checklists.
   * **Idea 2** ignores internal checklist math and tracks only high-level status (Pass/Fail/Flagged).
2. **Competitive Comparison**:
   * **Idea 1** allows store leaderboards to cross-compare using compliance ratios.
   * **Idea 2** keeps leaderboards restricted to direct archetype or template matches.
3. **Roadmap Execution**:
   * **Idea 1** advocates for an active three-step roadmap including new UI widgets.
   * **Idea 2** advocates for extreme MVP leanest-scope ("Wait for the Scream"), postponing new features until customer feedback demands them.

---

## 6. Pros and Cons Matrix

### Idea 1: "Universal Translator"
* **Pros**:
  * Gives corporate executives deep insights into specific operational categories (e.g. "How is our food safety doing across all retail and food templates?").
  * Provides a highly polished, unified metric (Compliance Ratio) that makes dynamic templates comparable.
* **Cons**:
  * High database query and sync complexity. Counting individual tagged checkpoints across millions of dynamic JSON snapshots is expensive.
  * Relies heavily on perfect customer data entry (if they forget to tag checkpoints, the reporting breaks).

### Idea 2: "Golden Output Metrics"
* **Pros**:
  * Highly scalable and lightweight backend footprint.
  * Very easy for customers to understand (Completion, TTR, and Issue counts are standard business terms).
  * Extremely fast time-to-market. By dropping the complex date/template filtering and chart gestures, we can launch immediately.
* **Cons**:
  * Board members do not get deep category compliance analysis immediately (they can only see overall audit status).
  * Executives cannot easily compare store performance if different stores are running completely different archetypes.

---

## 7. Product Manager's Strategic Recommendation

### The Hybrid Winner Strategy: "Standardize the Outputs First, Tag the Failures Second"

To sell successfully to multiple markets immediately without building a bloated codebase, the optimal path is to **launch with Idea 2 (Golden Metrics MVP) and bridge to Idea 1 (Category Compliance) as a premium upsell**.

```
  [Stage 1: Launch MVP] ──► Standardize Golden Metrics (Completion Rate + TTR + Status)
            │
            ▼
  [Stage 2: Expand]     ──► Implement Category Tags strictly on FAILURE events (Action Plans)
```

1. **Phase 1: Deliver Golden Metrics (Idea 2)**
   * Keep it simple. Standardize on **Completion Rate, Time to Resolve (TTR), and Action Plan Counts**.
   * Segment templates into three clean **Archetypes** (Scored Audits, Task Campaigns, and Fault Logs) to keep the metrics accurate.
   * Close the two pending tasks as "Out of Scope for MVP" to ensure stability.
2. **Phase 2: Add Category Tag Risk Analysis (Idea 1 Hybrid)**
   * Instead of calculating a complex checkpoint-level compliance ratio, map `CategoryTags` strictly to **Failed Items that trigger Action Plans**.
   * The boardroom dashboard can then display a simple, powerful card: **"Failing Risk Categories"** (e.g. "We have 12 open safety issues and 4 hygiene issues").
   * This provides the depth of Category Reporting without the mathematical complexity of cross-template average calculations.
