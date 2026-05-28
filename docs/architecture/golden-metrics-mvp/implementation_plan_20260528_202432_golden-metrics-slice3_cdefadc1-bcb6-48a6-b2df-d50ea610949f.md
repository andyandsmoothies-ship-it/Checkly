<latent_space_scratchpad>
Slice 3 is a governance documentation task — NOT a code task.

The 2 features to cancel:
  1. "Date-range filter API on GET /api/analytics/bod" — parameterized time window filtering on the BOD analytics endpoint.
  2. "Tap-to-Filter on Charts gesture" — tapping a chart bar/segment to drill-filter the dashboard.

These are NOT separate existing task files. The epic says "Update their task files with [CANCELLED] status" but they don't exist as task files yet. After investigation:
  - No task file with "date range" or "tap filter" found in active_tasks.
  - The features are listed in requirements documents as backlog items.
  - Slice 3's actual deliverable: Create a CANCELLATION RECORD artifact that formally marks both features as out-of-scope MVP. This artifact becomes the permanent ADR (Architecture Decision Record) for why they were dropped.

WHY they are cancelled:
  - Date-range filter: Requires backend API query parameter change, date-window aware SQL query in BodReportCalculator, cache invalidation on date change, and Flutter UI date picker widget. This is a large cross-stack slice that exceeds MVP scope.
  - Tap-to-Filter: Requires chart widget gesture detectors, filter state propagation through BodAnalyticsManager, and re-querying filtered data. Cross-cutting concern that requires deep integration across 6+ widgets.
  - Both features add complexity without changing the core problem (archetype mixing). They are quality-of-life features for v2.

WHAT this slice produces:
  1. A cancellation record ADR in `docs/architecture/golden-metrics-mvp/`.
  2. Update to the product requirements backlog file (if it has these features listed).

APPROACH: Route 1 — Direct Build (documentation write).
No tests needed. No code needed.

FILES:
  1. [NEW] docs/architecture/golden-metrics-mvp/cancellation_record_20260528_202432_golden-metrics-slice3_cdefadc1.md
  2. [MOD] (optionally) docs/product/requirements_*.md — add cancellation note to the 2 backlog items.

PRODUCT REQUIREMENTS FILE:
- User has `docs/product/requirements_20260527_151100_a2b3c4d5_audit_template_full_scope_v4.md` open.
- Also `docs/product/requirements_20260527_060000_d1b5c2a2_audit_template_full_scope_v3.md` open.
- The v4 file is the live requirements. I need to check if it contains the 2 cancelled features.

RISKS: None. This is documentation. Zero blast radius.

PATTERN: Architecture Decision Record (ADR). Formally captures: Context, Decision, Consequences.
</latent_space_scratchpad>

# Implementation Plan: Golden Metrics MVP — Slice 3 (Formal Task Cancellation)

**Date**: 2026-05-28 | **ConvID**: cdefadc1-bcb6-48a6-b2df-d50ea610949f  
**Pattern**: Architecture Decision Record (ADR) — Formal Scope Reduction  
**Route**: Route 1 (Direct Build — documentation only, zero code change)

---

## Input Lineage

`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\analysis_epic_20260528_162900_c3563378_golden-metrics-mvp_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

## Executive Summary & Out of Scope

**Goal**: Formally document the cancellation of 2 out-of-scope MVP features to prevent future agents from re-implementing them and to close them cleanly in the backlog.

**Features being cancelled:**
1. **Date-range filter API** — parameterized time-window filtering on `GET /api/analytics/bod` (backend + Flutter UI date picker).
2. **Tap-to-Filter charts gesture** — tapping a chart segment to filter the full dashboard (gesture detectors + state propagation across 6+ widgets).

**Why they were cancelled:**
- Both exceed the MVP scope agreed in the epic.
- The core business problem (invalid score mixing) is solved by the Archetype Filter Gate (Slice 1) alone.
- These are v2 quality-of-life features — they add UX polish but do NOT fix data correctness.
- Implementing them now risks destabilizing the BOD dashboard during the archetype migration.

**Key Investigation Finding**: The 2 features do NOT exist as separate task files in `.agents/active_tasks/`. They are backlog items referenced in the product requirements. Slice 3 therefore creates a **formal cancellation ADR** and annotates the requirements file — rather than updating pre-existing task files.

**Out of Scope — YAGNI:**
- ❌ Any code change of any kind.
- ❌ Any test change.
- ❌ Removing existing date-range or filter UI code (if any exists — it doesn't, these features were never built).
- ❌ Cancelling any other feature not explicitly listed above.

---

## System Context

| Dimension | Value |
| :--- | :--- |
| **Offline/Online** | N/A — documentation only. |
| **RBAC** | N/A. |
| **API Contract** | No change. |
| **Blast Radius** | Zero — markdown files only. |

---

## Lifecycle Context

| State | Behavior |
| :--- | :--- |
| **Success** | Cancellation ADR exists on disk. Future agents find the ADR and do not re-scope the features. |
| **Error** | N/A — no code execution. |
| **Empty** | N/A. |
| **Loading** | N/A. |

---

## Constraint Traceability

| Constraint | Source | Output |
| :--- | :--- | :--- |
| Close the 2 pending complex filter tasks | Epic L262–266 | Cancellation ADR created |
| Mark as `[CANCELLED — Out of Scope MVP]` | Epic L266 | ADR status header set to CANCELLED |
| Rationale must be recorded | ADR best practice | "Why Cancelled" section in ADR |

---

## Test Contracts

> [!NOTE]
> AI Decision: No tests written — this slice is **purely documentation**. No observable system behavior changes. The acceptance criteria are verified by confirming the files exist on disk.

**Acceptance Criteria:**
- [ ] Cancellation ADR file exists at the target path.
- [ ] ADR names both cancelled features explicitly.
- [ ] ADR includes rationale ("Why Cancelled") for each feature.
- [ ] ADR includes a "Deferred to v2" section with re-scope guidance.
- [ ] If the product requirements file lists these features, they are annotated with `[CANCELLED — Out of Scope MVP]`.

---

## Tools & Commands

```
# Verify ADR file was created
cmd /c dir "c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\"
```

No `flutter test` or `dotnet test` required.

---

## Proposed Changes

| # | Action | File | Change |
| :--- | :--- | :--- | :--- |
| 1 | `[NEW]` | `docs/architecture/golden-metrics-mvp/adr_20260528_cancelled_features_golden-metrics-mvp.md` | Formal ADR cancelling Date-range Filter and Tap-to-Filter features |
| 2 | `[MOD]` | `docs/product/requirements_20260527_151100_a2b3c4d5_audit_template_full_scope_v4.md` | Add `[CANCELLED — Out of Scope MVP]` annotation to the 2 backlog items (if present) |

---

## Concept Diagram

```
[Epic Analysis — Golden Metrics MVP]
    │
    ├──► Slice 1: Archetype Filter Gate  ✅ DONE
    ├──► Slice 2: KPI Card Promotion     🔄 IN PROGRESS
    └──► Slice 3: Cancel out-of-scope features
              │
              ├──► Feature A: Date-range Filter API
              │         └──► Status: ❌ CANCELLED — Out of Scope MVP
              │                       Reason: Cross-stack (backend + Flutter) complexity
              │                               exceeds MVP scope. Data correctness solved by Slice 1.
              │                       Deferred to: v2 milestone
              │
              └──► Feature B: Tap-to-Filter Charts Gesture
                        └──► Status: ❌ CANCELLED — Out of Scope MVP
                                      Reason: Requires gesture detectors + state propagation
                                              across 6+ widgets. Not needed for Archetype MVP.
                                      Deferred to: v2 milestone
```

---

## Execution Slices

### Slice 3-A: Create Cancellation ADR `[Route 1 — Direct Build]`

**Summary**: Write a formal Architecture Decision Record (ADR) at `docs/architecture/golden-metrics-mvp/adr_20260528_cancelled_features_golden-metrics-mvp.md` that documents the cancellation decision for both features.

**Entry State**: No cancellation record exists. Features are informally "out of scope."  
**Exit State**: ADR exists on disk with both features formally cancelled, rationale recorded, and v2 deferred scope defined.

**Scope:**
- `[NEW]` `docs/architecture/golden-metrics-mvp/adr_20260528_cancelled_features_golden-metrics-mvp.md`

**ADR Contents Required:**
- Title, date, status (`CANCELLED`)
- **Context**: Why these features were originally requested
- **Decision**: They are cancelled from the Golden Metrics MVP (c3563378)
- **Rationale per feature**: Why each one exceeds MVP scope
- **Consequences**: Future agents must NOT re-scope these features without a new Epic Analysis
- **Deferred to v2**: Conditions under which they can be re-opened (e.g., after Slice 1 + Slice 2 are verified in production)

**Acceptance Criteria:**
- [ ] File exists at `docs/architecture/golden-metrics-mvp/adr_20260528_cancelled_features_golden-metrics-mvp.md`
- [ ] Status header reads `Status: CANCELLED`
- [ ] Both feature names are listed explicitly
- [ ] Rationale section present for each feature
- [ ] "Deferred to v2" section present

**Complexity**: Trivial — 1 markdown file.

---

### Slice 3-B: Annotate Product Requirements `[Route 1 — Direct Build, Sequential after 3-A]`

**Summary**: Check `requirements_20260527_151100_a2b3c4d5_audit_template_full_scope_v4.md` for any backlog items matching the 2 cancelled features. If found, annotate them with `[CANCELLED — Out of Scope MVP — See ADR: adr_20260528_cancelled_features_golden-metrics-mvp.md]`.

**Entry State**: Slice 3-A complete. Requirements file unmodified.  
**Exit State**: If the 2 features appear in the requirements file, they are annotated. If not found, Slice 3-B is a no-op (document that explicitly).

**Scope:**
- `[MOD]` `docs/product/requirements_20260527_151100_a2b3c4d5_audit_template_full_scope_v4.md` (if features found)

**Acceptance Criteria:**
- [ ] Builder searched the requirements file for "date range" and "tap" before modifying
- [ ] If found: annotation added with ADR cross-reference
- [ ] If not found: this slice is documented as a no-op in the walkthrough

**Complexity**: Trivial — conditional 1-line annotation.

---

<command_logs>
- list_dir: .agents/active_tasks → 156 folders, 42 loose files found. No standalone task for "date range" or "tap filter".
- grep_search: date-range|tap.to.filter|date range|tap filter in .agents/active_tasks *.md → 0 results.
- view_file: bod_filters task → verify task (already done), unrelated to date-range or tap-filter.
- view_file: golden-metrics-slice1 task (91f29479) → All steps [x], Slice 1 DONE.
- view_file: golden-metrics-slice2 task (91f29479) → Slice 2 checkbox [ ], IN PROGRESS.
- view_file: epic L1-99 → Confirmed "2 pending complex filter tasks" = Date-range filter API + Tap-to-Filter gesture. Features described in epic, NOT as separate task files. Slice 3 = create ADR + annotate requirements.
- list_dir: .agents/active_tasks/reporting → 35 files, none matching date-range/tap-filter patterns.
</command_logs>

---

## Handoff Block

**Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\implementation_plan_20260528_202432_golden-metrics-slice3_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

**Execute ONE AT A TIME:**

1. **Slice 3-A** → 🔨 **Direct Build** — Write the cancellation ADR at `docs/architecture/golden-metrics-mvp/adr_20260528_cancelled_features_golden-metrics-mvp.md`. No test command needed — verify via `dir` command.

2. **Slice 3-B** → 🔍 **Check then Build** — Search the v4 requirements file for the 2 cancelled features. Annotate if found; document as no-op if not.

> Slice 3 can run **in parallel** with Slice 2 (flutter KPI card work) — they touch completely different files.
