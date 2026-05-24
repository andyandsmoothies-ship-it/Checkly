# Implementation Plan: Visual Hierarchy & HeroCard Abuse

## Input Lineage
`C:\Users\HP\.gemini\antigravity\brain\23e73e2b-79b2-47a5-b3f4-e8bafbd088d8\visual_qa_report.md.resolved`

## Executive Summary & Out of Scope
**Goal:** Resolve the severe visual hierarchy contradiction on the Manager Dashboard by demoting the "All Clear" status to the CompactStatusPanel and refactoring the `ActionRequiredWidget` to stop abusing the `HeroCard`.
**Out of Scope:** We will not touch backend APIs, routing, state managers, or any other dashboard widgets beyond the two specific UI files flagged. 

## Risk Assessment
> [!WARNING]
> **Risk/ROI Warning**: Risk is Very Low. This is a pure UI layout change with no state or logic modifications.

## System Context
- **Environment**: Offline-first hybrid app.
- **Roles**: Affects Store Managers and Area Managers (via `manager_dashboard_variant.dart`).
- **Data Flow**: Consumes existing `DashboardManager` and `PendingAssignmentVm` streams. No data layer changes.

## Lifecycle Context
- **Success State (Fire)**: If `overdueActionPlans > 0`, the amber `HeroCard` remains at the top.
- **Success State (All Clear)**: The giant green `HeroCard` is removed entirely. The 0 count is still communicated silently by the `CompactStatusPanel`.
- **Pending Assignments**: Displayed as a compact list under a "Pending Campaigns" header rather than a wall of amber `HeroCard`s.

## Verification Plan

### Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| TC-01 | "All Clear HeroCard should not render" | `overdueActionPlans == 0` | The `else` branch in `manager_dashboard_variant.dart` currently renders a green HeroCard. |
| TC-02 | "Overdue HeroCard should render" | `overdueActionPlans > 0` | (Existing behavior preserved). |
| TC-03 | "Pending Campaigns list should render as ListTiles, not HeroCards" | `vms.length > 1` | `action_required_widget.dart` currently maps everything to `HeroCard`. |

## Test Fixture & Payloads
- **Required State**: `ManagerDashboardState` with `overdueActionPlans = 0` to verify All Clear removal. `DashboardManager.watchActionRequired()` yielding multiple `PendingAssignmentVm`s to verify the new compact list styling.

## Tools & Commands
- **Skills Needed**: `flutter-api` (for standard UI widgets like `Card`, `ListTile`, `Column`).
- **Test Command**: `rtk flutter test`

## Proposed Changes

### Dashboard UI Updates
#### [MOD] `manager_dashboard_variant.dart`
- Demote "All Clear" state: Remove the `else` block containing the green `HeroCard`.

#### [MOD] `action_required_widget.dart`
- Restructure multiple campaigns: Replace the mapping to `HeroCard` with standard Material `Card` + `ListTile`. Add a `Text` header like "Pending Campaigns" if `vms.isNotEmpty`.

## Concept Diagram
```text
[Manager Dashboard State] --> Is Overdue Plans > 0?
  ├── Yes --> [Amber HeroCard]
  └── No --> [No HeroCard rendered] --> [CompactStatusPanel: 0 Plans]
  
[Pending Assignments Stream] --> Count > 0?
  ├── Yes --> ["Pending Campaigns" Header]
  │             ├── [Compact ListTile 1]
  │             └── [Compact ListTile 2]
```

## Execution Slices

### Execution Phase: Demote HeroCards
- **Summary**: Remove the All Clear `HeroCard` and convert the `ActionRequiredWidget` to use standard cards.
- **Value Delivered**: Fixes "banner blindness" and logical contradiction, saving 40% vertical space on mobile.
- **Entry State**: Manager Dashboard rendering identical massive banners for all alerts.
- **Exit State Guaranteed**: Manager Dashboard cleanly separates severe alerts (HeroCard) from pending tasks (ListTile).
- **Scope**: `manager_dashboard_variant.dart`, `action_required_widget.dart`
- **Acceptance Criteria**: TC-01, TC-02, TC-03.
- **Complexity**: Low. Simple widget tree modification.
- **Pros & Cons**: 
  - *Pro*: Immediate UX improvement, matches Material design hierarchy.
  - *Con*: Requires the Builder to have good taste in spacing the new ListTiles.

---

## Handoff Block
Plan ready for Builder to execute.

> **Route 2: Visuals/Simple (Direct Build)**
> @[/implement] Execute build for The Feature: c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260513_201500_DB02_visual_hierarchy.md
