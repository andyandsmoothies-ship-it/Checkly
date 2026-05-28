# Architecture Decision Record (ADR): Scope Cancellation for Golden Metrics MVP

**Date**: 2026-05-28  
**Status**: CANCELLED / SUPERSEDED (Scope Reduction)  
**Topic**: Checkly Golden Metrics MVP  
**Epic Identifier**: `c3563378-9cd7-4609-ae6d-2aba9f71c9ff`

---

## 1. Context

During the Epic Analysis for the "Golden Metrics MVP," two complex data-filtering features were originally proposed to enhance the interactivity and analytical granularity of the Board of Directors (BOD) dashboard:

1.  **Date-range filter API** on `GET /api/analytics/bod`: Allowing the client to query arbitrary time-windows and have the backend recompute and serve scores on demand.
2.  **Tap-to-Filter on Charts gesture**: Allowing the user to tap individual bars, segments, or legend categories on visual charts to automatically filter the entire dashboard by that category/segment.

These features were intended to provide advanced navigation and real-time query manipulation for executive stakeholders.

---

## 2. Decision

We have formally **CANCELLED** these two features from the scope of the Golden Metrics MVP. 

They are deferred to the **v2 Milestone** and must not be implemented by any agent working on the current MVP slice.

---

## 3. Rationale

### Feature 1: Date-Range Filter API on GET /api/analytics/bod

*   **Excessive Complexity**: Parameterizing the time window on this high-aggregation OLAP endpoint requires a cross-stack migration:
    *   **Backend**: Adding parameter validation to controllers, modifying SQL aggregation queries in `BodReportCalculator`, and updating caching strategies (which currently cache the nightly boardroom rollup snapshot as a JSONB block).
    *   **Frontend**: Designing and building a date picker widget, updating `BodAnalyticsManager` state machine, and handling asynchronous loading skeletons.
*   **Not Essential for the MVP**: The primary objective of the Golden Metrics MVP is resolving the **archetype-mixing data defect** (where audits of different store types contaminate the boardroom averages). This critical business correctness is fully resolved by the `Archetype Filter Gate` (Slice 1). Date filtering is a quality-of-life feature that can be decoupled safely.

### Feature 2: Tap-to-Filter on Charts Gesture

*   **High Component Coupling**: Tap-to-filter requires injecting event handlers, gesture detector layers, and feedback animations across 6+ visual chart widgets (Score Line Chart, Section Radar, AP Funnel, etc.).
*   **State Machine Overhead**: This feature introduces cyclic state dependencies: a change in one chart must filter all other charts, necessitating a complex multi-directional filter state manager.
*   **YAGNI (You Aren't Gonna Need It) for MVP**: Standard dropdown filters (implemented in Slice 1) already provide full capacity to filter the dashboard. Gestures on visual components add high interaction complexity without providing new analytical capabilities.

---

## 4. Consequences

*   **Future Scope Boundary**: Future agents, developers, or SRE reviewers MUST NOT implement date-range filtering or interactive chart filters as part of the `c3563378` epic.
*   **No Code Bleed**: No date-range validation, query parameters, date picker widgets, or chart gesture handlers should be written during this phase.
*   **Clean Implementation**: The code remains lightweight, focused strictly on the core vertical slices (Archetype Filter Gate and KPI Card Promotion).

---

## 5. Re-Scope & Deferred to v2

These features may be re-considered for implementation only under the following conditions:

1.  **Production Verification**: The core Archetype Filter Gate (Slice 1) and KPI Promotion (Slice 2) have been successfully compiled, tested, and validated in production.
2.  **Explicit Epic Authorization**: A new Epic Analysis document is created specifically authorizing interactive filtering and date parameterization.
3.  **Advisory Lock Resolution**: The nightly OLAP background rollup generation must be modified to support dynamic slicing without causing PostgreSQL database degradation or lock contention.
