# Product Research: Boardroom Analytics Three-Way Strategic Comparison

**Date**: 2026-05-28 | **ShortID**: c3563378
**Topic**: PM Strategic Options Comparison (Idea 1 vs Idea 2 vs Idea 3)
**Status**: Research & Evaluation Phase

---

## 1. Executive Summary & Strategy Map

When selling Checkly to multiple distinct markets (Quick Service Restaurants, Retail, Hospitality, Manufacturing), we face a conflict: **operations teams want custom, dynamic checklists**, while **executives want uniform boardroom metrics**.

This document compares three distinct strategic product management approaches to solve this issue:
* **Idea 1: The "Universal Translator"** (translates input checkpoints into unified category percentages).
* **Idea 2: "Golden Output Metrics"** (standardizes overall output data and separates templates by archetype).
* **Idea 3: "Tag-Weighted Risk Scorecard"** (normalizes dynamic checklists using corporate-wide risk weights assigned to categories/tags).

### Dynamic Strategy Flowchart

```
                 [Dynamic Multi-Market Checklists]
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
  [Idea 1: Translator]   [Idea 2: Golden Output]  [Idea 3: Risk Scorecard]
  Checkpoint Tag Ratio   Completion % & TTR      Corporate Tag Weights
  High input complexity  Simple output KPIs      Risk-adjusted index
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
* **Performance Control**: Utilizes static pre-computed snapshots by default (loaded in <50ms) to ensure premium speed.

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
* **The "Wait for the Scream" Roadmap**: Aggressively drops pending features (like Tap-to-Filter on charts or extra date/template filtering APIs) for the MVP. Focuses entirely on stabilizing the core metrics.

---

### Idea 3: Tag-Weighted Risk Scorecard (Dynamic Risk-Adjusted Index)
Idea 3 standardizes the checklists by assigning **Universal Severity Weights** to category tags at the corporate level. It evaluates compliance based on **Risk Exposure** rather than raw question counts.

* **How it works**:
  1. Corporate administrators assign weights to universal category tags in their dashboard settings:
     * `Critical Safety / CCP` = Weight 100
     * `High Hygiene` = Weight 50
     * `Low Maintenance` = Weight 10
  2. When any dynamic audit is completed, the system calculates a **Dynamic Risk-Adjusted Index (DRAI)** specifically for that submission:
     $$\text{DRAI} = \frac{\sum(\text{Passed Checkpoint Weights})}{\sum(\text{Answered Checkpoint Weights})} \times 100$$
  3. This completely neutralizes checklist length. A 5-question audit and a 50-question audit both calculate a pure 0-100 index based on the importance of the questions answered.
* **Operational Impact**: If a store fails a single `Critical Safety` checkpoint, their compliance index drops significantly, reflecting actual operational risk.

---

## 3. Three-Way Comparison Table

| Dimension | Idea 1: "Universal Translator" | Idea 2: "Golden Output Metrics" | Idea 3: "Tag-Weighted Risk Scorecard" |
| :--- | :--- | :--- | :--- |
| **Primary Focus** | **Internal Inputs**: Standardizes checkpoint-level tags. | **External Outputs**: Standardizes high-level results. | **Input Importance**: Standardizes value of category tags. |
| **Mathematical Metric** | **Compliance Ratio**: Percent of passed tagged checks. | **Completion % / TTR / Issue Counts**: Classic operational KPIs. | **Risk-Adjusted Index**: Weighted compliance percentage. |
| **User Experience** | Detailed views into dynamic checklist categories. | Simplified, clean dashboards that focus on task resolution. | High-fidelity corporate safety and operational risk matrices. |
| **Backend Complexity** | **High**: Deep JSON checkpoint counts. | **Low**: Standardizes simple column aggregates. | **Medium**: Dynamic weight lookups on sync endpoints. |
| **SaaS Scalability** | **Medium**: Customers must tag checklists perfectly. | **High**: Works instantly out-of-the-box for any market. | **High**: Perfect for heavy enterprise (QSR, Industrial, Retail). |
| **MVP Scope** | **Medium**: Requires Audit Type Selector UI. | **Lean**: Deletes complex pending features. | **Medium**: Requires Tag Weight configuration settings. |

---

## 4. Areas of Complete Agreement (Shared Core Principles)

Across all three ideas, the core foundational rules of Checkly remain unchanged:

1. **Leveraging Category Tags**: All strategies agree that `CategoryTags` are the key to standardizing dynamic structures without modifying the underlying database tables.
2. **Segmenting Work Types**: All agree that mixing different styles of work (like a qualitative survey and a graded safety audit) on the same score chart is mathematically incorrect and must be prevented.
3. **Geography Standard**: All agree on utilizing our robust `Province ──► District` geographical filtering.
4. **Caching & Speed**: All agree that the dashboard must load instantly using nightly cached pre-computed snapshots, protecting PostgreSQL database performance.

---

## 5. Areas of Disagreement (Divergences)

The three ideas diverge on **how to measure compliance** and **where the complexity is managed**:

```
                       [How to Standardize?]
                                 │
        ┌────────────────────────┼────────────────────────┐
        ▼                        ▼                        ▼
[Checkpoint Tag Ratio]    [Golden Output Metrics]   [Tag Weight Index]
- Idea 1 Method           - Idea 2 Method           - Idea 3 Method
- Equal weights           - Ignores internal checks - Dynamic risk weights
- High SQL overhead       - Ultra-low SQL overhead  - Balanced SQL overhead
```

1. **Math Granularity**:
   * **Idea 1** calculates detailed percentages *inside* the checklists.
   * **Idea 2** ignores internal checklist math and tracks only high-level status (Pass/Fail/Flagged).
   * **Idea 3** applies a corporate-wide importance factor (weights) to tag aggregates.
2. **Competitive Comparison**:
   * **Idea 1** allows store leaderboards to cross-compare using compliance ratios.
   * **Idea 2** keeps leaderboards restricted to direct archetype or template matches.
   * **Idea 3** allows global store comparisons using the Risk-Adjusted compliance score.
3. **Complexity Location**:
   * **Idea 1** puts complexity on the **Backend Database** (parsing millions of dynamic JSON values).
   * **Idea 2** puts complexity on the **Product Definition** (restricting features to match archetypes).
   * **Idea 3** puts complexity on the **Enterprise Setup** (requiring corporate admins to configure tag weights).

---

## 6. Pros and Cons Matrix

### Idea 1: "Universal Translator"
* **Pros**: Deep category insights; high flexibility.
* **Cons**: High database query and sync complexity; relies on perfect checklist tag entry.

### Idea 2: "Golden Output Metrics"
* **Pros**: High scalability; lightweight database footprint; extremely fast time-to-market.
* **Cons**: No deep category compliance analysis immediately; harder to compare stores running different templates.

### Idea 3: "Tag-Weighted Risk Scorecard"
* **Pros**:
  * Perfectly handles dynamic/mixed checklists. Neutralizes checklist length.
  * Measures **real operational risk** (CCP failure impacts the score directly).
  * Highly attractive to enterprise corporate accounts (QSR, Industrial, Retail).
* **Cons**:
  * Requires adding a Corporate Tag Weights configuration screen in the admin dashboard.
  * Slightly higher onboarding setup for customers.

---

## 7. Product Manager's Strategic Recommendation

### The Ultimate SaaS Winner Roadmap: "Golden Outputs MVP ──► Tag-Weighted Scaling"

The most profitable and developer-clean way to scale Checkly to multiple markets is a **three-phase rollout**:

```
 [Phase 1: Golden MVP (Idea 2)] ──► [Phase 2: Tag Weights (Idea 3)] ──► [Phase 3: Deep Translator (Idea 1)]
 Standardize completion & TTR       Enable Risk Weights for enterprise  Provide deep tag-level query upsell
```

1. **Phase 1: Deliver Golden Metrics (Idea 2)**
   * Keep the launch simple. Standardize on **Completion Rate, Time to Resolve (TTR), and Action Plan Counts**.
   * Close the two pending tasks as "Out of Scope for MVP" to ensure stability.
2. **Phase 2: Introduce Corporate Tag Weights (Idea 3)**
   * Add a simple corporate-wide setting page where admins assign risk weights to tags.
   * Automatically calculate the **Dynamic Risk-Adjusted Index (DRAI)** for submissions. This allows QSR and Retail stores to compare scores fairly.
3. **Phase 3: Dynamic Drill-Down (Idea 1)**
   * Introduce fine-grained checkpoint tag compliance query APIs once the database scale requires a dedicated analytics data-warehouse layer.
