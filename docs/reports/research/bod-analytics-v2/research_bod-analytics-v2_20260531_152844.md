---
conversation_id: dcbfac81-a3e9-4fad-af42-bc281b403b75
created_at: 2026-05-31T15:28:44+07:00
topic: bod-analytics-v2
type: research
status: VIABLE
---

# Research: BOD Analytics V2 — Leveraging Audit Data for Enterprise Boardroom Reporting

## [ORIGIN_IDEA]

> Re-design BOD Analytics to: (1) Surface role-aware, actionable insights for each role in the system (Admin, Area Manager, Store Manager), and (2) Provide honest, high-value metrics (Section-based grouping and SLA overdue buckets) for boardroom decisions.

---

## 1. Role-Scoped Dashboards & Access Model

The backend will expose three role-tailored views using existing JWT claims and user tenancy checks:

```
[BOD V2 Access Model]

Role              │ New Endpoint                    │ Data Scope
──────────────────┼─────────────────────────────────┼──────────────────────────────
Admin             │ GET /api/analytics/bod           │ Global corporate average
                  │                                 │ + Geofence bypass telemetry
──────────────────┼─────────────────────────────────┼──────────────────────────────
Area Manager      │ GET /api/analytics/bod/area      │ Tenancy-scoped to AM's stores
                  │                                 │ + Regional averages & Store comparison
──────────────────┼─────────────────────────────────┼──────────────────────────────
Store Manager     │ GET /api/analytics/bod/store     │ Scoped to single StoreId
                  │                                 │ + Store Score vs. Regional Average
                  │                                 │ + Regional peer ranking/quartile indicator
                  │                                 │   (e.g., "Top 30% in Region") to motivate
                  │                                 │   store-level performance.
```

---

## 2. Key Boardroom Features

### Feature 1: Section-Based Analytics (No custom tags needed)
Instead of requiring managers to type and manage custom tags (which leads to unmaintained, empty charts), the boardroom dashboard will aggregate scores using the **existing Section Titles** that are already present in every audit template. This is 100% reliable and requires zero extra maintenance.

```
[Submission Created] ──► Section: "Food Safety" ──► Score: 80%
                         Section: "Equipment" ───► Score: 70%
                                      │
                                      ▼
[Boardroom Query] ──────► Groups and aggregates scores directly by Section Title
```

---

### Feature 2: SLA Overdue Action Plan Buckets
To prevent store managers from quickly closing action plans poorly just to lower their "average days to close" metric, we will track plans inside **SLA Overdue Buckets**:
*   **0-7 Days Overdue**
*   **8-30 Days Overdue**
*   **31+ Days Overdue**

This shows the boardroom a high-value, honest view of outstanding compliance items.

---

## 3. Implementation Plan

*   **Slice 1 (BOD Scoped Endpoints)**:
    - Implement `GET /api/analytics/bod/area` (tenancy-scoped regional data).
    - Implement `GET /api/analytics/bod/store` (store-specific benchmarks).
*   **Slice 2 (Section Score Projections)**:
    - Update C# analytics query to aggregate scores by section title across store groups.
*   **Slice 3 (SLA Overdue Buckets)**:
    - Write SQL rollup query to bucket outstanding action plans by overdue thresholds.
    - Expose SLA buckets in the boardroom dashboards.
