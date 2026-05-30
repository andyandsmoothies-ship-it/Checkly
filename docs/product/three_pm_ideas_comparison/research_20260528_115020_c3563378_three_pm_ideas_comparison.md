# Product Research: Boardroom Analytics Three-Way Standardization Strategy

**Date**: 2026-05-28 | **ShortID**: c3563378
**Topic**: PM Strategic Comparison (Idea 1 vs Idea 2 vs Idea 3)
**Status**: Comprehensive Strategic Evaluation

---

## 1. Executive Summary & Strategy Map

To scale Checkly across multiple industries (Quick Service Restaurants, Retail, Hospitality, Manufacturing), we must solve a core conflict: **operations teams need dynamic, custom checklists**, while **executives need standardized corporate analytics**.

This document compares three product strategies to solve this conflict:
* **Idea 1: The "Unified Compliance Index" (UCI)**: Standardizes input scoring by translating completed audits into a 0-100 score based on severity weights.
* **Idea 2: "Golden Output Metrics"**: Standardizes high-level metadata (Completion Rate, Time to Resolve, and Pass/Fail counts) at the template archetype level, keeping the backend very simple.
* **Idea 3: The "Operational Risk Exposure" (ORE) Index**: Translates failures into "Risk Points" representing operational and financial liability, showing active corporate risk that decreases as issues are resolved.

### Dynamic Strategy Flowchart

```
                                 [Dynamic Checklist Data]
                                             │
             ┌───────────────────────────────┼───────────────────────────────┐
             ▼                               ▼                               ▼
[Idea 1: Unified Compliance]     [Idea 2: Golden Outputs]         [Idea 3: Risk Exposure]
- Normalizes checkpoints (0-100) - Tracks Completion % & TTR     - Sums unresolved failure points
- Compares cross-template tags   - Segmented by Archetype         - Links directly to Action Plans
- High complexity, rich detail   - Low complexity, fast launch    - High value, risk-focused
```

---

## 2. Detailed Breakdown of Each Idea

### Idea 1: The "Unified Compliance Index" (UCI)
Focuses on standardizing **internal checkpoints (inputs)**. Every failure is assigned a standard severity tier (Critical, Major, Minor).

* **How it works**: Translates diverse scoring structures (weighted, unweighted, or checklist) into a standardized compliance score from 0 to 100 based on the number and severity of failures.
* **Semantic Tagging**: Leverages cross-template `CategoryTags` to aggregate performance under universal categories (e.g., "Hygiene", "Brand Safety") even if sections are named differently.
* **Audience Segmentation**: Segregates views between a macro Executive view (BOD) focusing on compliance rates, and a micro Operations view (requires choosing a template before showing leaderboards).

---

### Idea 2: Standardize the Output (Golden Metrics & Archetypes)
Focuses on standardizing the **final results of the submission (outputs)**. It ignores internal checklist differences and tracks only universal business metrics.

* **Golden Metrics Model**:
  * **Completion Rate**: The percentage of assigned checklists that were completed.
  * **Time to Resolve (TTR)**: How fast store managers close out issues.
  * **Compliance Status**: Pass / Fail / Flagged counts.
* **Template Archetypes**: Segregates templates into three strict bins: **Scored Audits** (0-100 scores), **Task Campaigns** (0-100% completion rates), and **Fault Logs** (raw issue counts). The dashboard never mixes them.
* **Roadmap Speed**: Recommends dropping pending features (like Tap-to-Filter on charts and custom date APIs) for the MVP. We "wait for the scream" (customer feedback) before writing complex backend code.

---

### Idea 3: The "Operational Risk Exposure" (ORE) Index (The Liability Model)
Focuses on standardizing **business risk and liability (outcomes)**. Instead of calculating percentage compliance, it measures active unresolved compliance failures as a dynamic "Risk Score."

* **How it works**: Every checklist failure is assigned standard **Risk Points** based on business impact:
  * **Critical (CCP / Risk)**: 50 risk points.
  * **Major**: 10 risk points.
  * **Minor**: 2 risk points.
* **The Metric**: The dashboard displays the store or region's active **Risk Exposure Index (REI)**:
  $$\text{REI} = \sum (\text{Active Unresolved Failures} \times \text{Risk Weighting})$$
* **Mitigation-Driven**: The score is dynamic. As soon as a store manager resolves an Action Plan, the risk points are deducted and the store's Risk Exposure Index drops back down.
* **Why it sells**: Corporate boards understand risk and financial liability. A store with a 95% score might seem healthy, but if the 5% failure represents a blocked fire exit (Critical Risk), the business liability is massive. This index flags exactly that.

---

## 3. Comparison Table: The Three Strategies

| Dimension | Idea 1: Unified Compliance | Idea 2: Golden Outputs | Idea 3: Operational Risk (ORE) |
| :--- | :--- | :--- | :--- |
| **Primary Focus** | Checkpoint-level inputs & severity. | High-level submission results. | Active business liability & resolution. |
| **Mathematical Metric** | **Compliance Ratio (0-100%)** | **Completion Rate & TTR** | **Active Risk Points (0 to 100+)** |
| **Backend Complexity** | **High**: Requires parsing dynamic JSON. | **Low**: Simple column aggregates. | **Medium**: Tracks active vs resolved states. |
| **User Value** | High: Deep insights into categories. | Medium: Straightforward checklist tracking. | **Very High**: Focuses on liability & action. |
| **SaaS Scalability** | **Medium**: Requires tag standardization. | **High**: Works instantly for any market. | **High**: Universal across all templates. |
| **Time-to-Market** | Slow (requires heavy UI/API work). | **Fastest (ideal for MVP launch)**. | Medium (needs risk-pointing database fields). |

---

## 4. Areas of Complete Agreement (Shared Core Principles)

Across all three ideas, several foundational product principles are universally accepted:

1. **No Mixed Score Averages**: We must never mix mathematically incompatible formats (e.g. surveys and scored audits) on a single scoreboard.
2. **Category Tags are Key**: Standardizing metadata using `CategoryTags` is the most scalable way to query cross-template metrics.
3. **Instant Loading Performance**: The dashboard must default to loading a pre-computed nightly snapshot in <50ms.
4. **Geographical Anchors**: High-performance filtering should remain anchored to standard regional boundaries (`Province ──► District`).

---

## 5. Areas of Disagreement (Divergences)

The strategies diverge on **what we present to the executive board** and **the mathematical baseline**:

1. **The Core Metric Shown**:
   * **Idea 1** wants to show standard compliance scores.
   * **Idea 2** wants to show completion rates and status totals.
   * **Idea 3** wants to show active risk exposure values.
2. **Dynamic Behavior**:
   * **Idea 1** and **Idea 2** view scores as historical snapshots (once saved, the score remains static).
   * **Idea 3** views score as a dynamic, living index that changes in real-time as store managers resolve issues.
3. **Local Store Leaderboards**:
   * **Idea 1** compares stores using normalized compliance ratios.
   * **Idea 2** compares stores only if they run the exact same template.
   * **Idea 3** compares stores by their active risk reduction speed.

---

## 6. Pros and Cons Matrix

### Idea 1: Unified Compliance Index (UCI)
* **Pros**: Deep, category-level analysis. Executives see exactly where standards are failing.
* **Cons**: High backend parsing cost. Breaks if users do not tag their checkpoints perfectly.

### Idea 2: Golden Output Metrics
* **Pros**: Fastest time-to-market. Simple to build and understand. Scales easily across all markets.
* **Cons**: Lacks granular category detail. Does not show executives the severity or risk of specific failures.

### Idea 3: Operational Risk Exposure (ORE) Index
* **Pros**: Directly maps operational data to executive business risk. Drives immediate action (resolving Action Plans drops the risk score).
* **Cons**: Requires standardizing risk weights across all checklist items during setup.

---

## 7. Product Manager's Strategic Recommendation

### The Phased Winner: "Standardize Outputs first, Risk-Weight the Failures second"

To launch Checkly successfully to multiple markets immediately, the best path is a **phased roadmap** that combines the speed of Idea 2 with the deep business value of Idea 3:

```
[Phase 1: Launch MVP] ──► Standardize Golden Metrics (Idea 2: Completion Rate + TTR)
          │
          ▼
[Phase 2: Premium Upsell] ──► Enable Operational Risk Index (Idea 3: Risk Points on Action Plans)
```

1. **Launch Phase (Phase 1)**: Deploy the simple **Golden Output Metrics** (Idea 2). Focus entirely on completion rates, TTR, and Pass/Fail counts. Drop all complex date/template dynamic filtering to guarantee stability and speed.
2. **Growth Phase (Phase 2)**: Introduce the **Operational Risk Exposure Index** (Idea 3) as a premium feature. Tie risk points (`Critical = 50`, `Major = 10`) directly to **failed checkpoints that spawn Action Plans**. This provides executives with a high-value risk dashboard without needing complex cross-template math.
