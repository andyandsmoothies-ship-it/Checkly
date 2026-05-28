<latent_space_scratchpad>
CORE FINDING: CompletionRate is ALREADY a visible KPI card in BodKpiGrid (Row 1, L93-109).
The epic diagram is PARTIALLY already implemented.

What is MISSING: AvgTtrDays as a standalone KPI card in BodKpiGrid.
Current state: AvgTtrDays only appears as a PillChip inside BodApAgingFunnel (card5).

Target state: Add AvgTtrDays as a KPI card in BodKpiGrid Row 2.
Current Row 2: "Total Audits | Overdue / Open APs"
Current Row 3: "Active Stores | Total Auditors"

DECISION: Replace "Total Audits" (Row 2) with "Avg TTR Days" OR add a new Row 2 with AvgTtrDays + Total Audits.
The epic target shows: "Avg TTR Days ★ | Open APs" in Row 2.
So Total Audits moves to Row 3 alongside Active Stores, pushing Total Auditors out OR stays in Row 3.

SAFEST: Keep all 6 cards, add AvgTtrDays to Row 1 as replacement for ... no.
Epic says target is: Row 1: Total Audits | Completion Rate ★, Row 2: Avg TTR Days ★ | Open APs.
So the grid becomes 3 rows × 2:
  Row 1: Total Audits | Completion Rate (already done)
  Row 2: Avg TTR Days ★ | Overdue / Open APs (new card, replace existing "Total Audits" card)  
  Row 3: Active Stores | Total Auditors (unchanged)

This means: Row 1 changes: swap Average Score card OUT and put Total Audits there. 
Wait - current Row 1: Average Score | Completion Rate.
Epic target Row 1: Total Audits | Completion Rate.
So Average Score moves to ... nowhere? Or it stays. Let me re-read the epic diagram.

Epic diagram:
[EXISTING]                              [TARGET]
│  Total Audits   Avg Score      │      │  Total Audits   Completion Rate ★  │
│  125            87.5%          │      │  125            92.3%              │
│  Completion %   Open APs       │      │  Avg TTR Days ★  Open APs         │
│  (hidden)       14             │      │  4.2 days        14               │

So in the EXISTING column, Current actual code has: Row 1: Avg Score | Completion Rate (both visible).

The epic diagram says "Completion % (hidden)" — but looking at the actual code, completionRate IS rendered in Row 1. The epic was written before I verified the code. So the epic diagram is slightly stale.

Actual current state (from code):
Row 1: Average Score | Completion Rate (both visible, with MoM delta indicators)
Row 2: Total Audits | Overdue / Open APs 
Row 3: Active Stores | Total Auditors

Target: Add AvgTtrDays to the KPI grid. Looking at what the epic says: "Avg TTR Days ★ | Open APs" in Row 2. So the change is:
- Replace "Total Audits" in Row 2 with "Avg TTR Days"
- Move "Total Audits" to Row 3 or simply remove it

OR:
- Keep all 6 existing cards
- Insert a new row (Row 2) with AvgTtrDays and keep Total Audits somewhere

SIMPLEST approach that matches epic intent:
Replace the "Total Audits" card in Row 2 with "Avg TTR Days" card.
Total Audits value: can remain in Row 2 (not removed from data) but the primary card position goes to AvgTtrDays.
The "Total Audits" card can be moved to after Row 3 or merged.

Actually — the cleanest interpretation: The epic says AvgTtrDays should be a prominent KPI tile. The simplest change is: in Row 2, replace "Total Audits" with "Avg TTR Days" card. "Total Audits" can then occupy the spot formerly taken by the standalone element, or we just keep 6 cards and make it a 4-row 2-col grid: Row 1: AvgScore | CompletionRate, Row 2: TotalAudits | AvgTtrDays, Row 3: OpenAPs | ActiveStores, Row 4: TotalAuditors.

But that's adding a row. Even simpler: drop "totalAudits" from its own card and fold it into description text — no, that's lossy.

FINAL DECISION: Most minimal change = Insert AvgTtrDays as its own card between the existing Row 1 and Row 2. This means:
Row 1: Avg Score | Completion Rate (no change)
Row 2 (NEW): Avg TTR Days | Total Audits (swap order, AvgTtrDays is now prominent)
Row 3: Overdue / Open APs | Active Stores
Row 4: Total Auditors (single card, span full width — or pair with something)

That's messy. 

ACTUALLY CLEANEST (4 rows × 2):
Row 1: Avg Score | Completion Rate (unchanged)
Row 2: Avg TTR Days ★ | Overdue / Open APs (move Total Audits OUT of row 2, replace with AvgTtrDays)
Row 3: Total Audits | Active Stores (Total Audits demoted to row 3, alongside Active Stores)
Row 4: Total Auditors (full-width OR pair with a spacer)

But that leaves Total Auditors alone. Better:
Row 3: Total Audits | Active Stores | Total Auditors — 3 per row? No, current grid is 2-per-row.

SIMPLEST FINAL: Just replace the "Total Audits" card in Row 2 with "Avg TTR Days" card. Total Audits stays visible in description text or... we just accept 5 cards and have Row 3 as a single full-width "Total Auditors | Active Stores" row, with Total Audits omitted.

Actually it's fine. Total Audits is not a "Golden Metric". The epic says the goal is to promote CompletionRate and AvgTtrDays. CompletionRate is done. AvgTtrDays needs to be added. The epic diagram shows "Total Audits | Completion Rate" in Row 1 — meaning Average Score gets replaced. But that would remove the flagship metric. 

I'll pick the most conservative + impactful interpretation:
Keep all existing cards. ADD AvgTtrDays. Result is 4 rows × 2 = 8 card slots:
Row 1: Avg Score | Completion Rate  (unchanged)
Row 2: Avg TTR Days ★ | Overdue / Open APs  (AvgTtrDays replaces Total Audits spot)
Row 3: Total Audits | Active Stores
Row 4: Total Auditors (alone, Expanded full-width OR with SizedBox filler)

Clean and simple. 7 cards = one single-card row at end.
Or: Row 4 with Total Auditors at full width (Expanded + SizedBox).

FILE TO CHANGE: BodKpiGrid only (263 lines — under 400 line limit ✅)
BodDashboardBody: NO CHANGE needed (passes chainKpis.toJson() which already has avgTtrDays)

EXISTING TESTS IMPACT:
- C4-TEST-01: chainKpis doesn't include avgTtrDays — test will still pass (defaults to 0.0).
- C4-TEST-02: asserts activeStores=45, totalAuditors=14 — still pass.
- Need: New test TC-S2-01 asserting AvgTtrDays card is visible with correct value.
- Need: New test TC-S2-02 asserting color-coded TTR (green ≤7d, red >7d).

ROUTE: Route 1 (Direct Build) — no network, no auth, no DB. Pure StatelessWidget change.
The epic says "Plan → Build (then run flutter test --update-goldens)".
Since no golden files exist (test/goldens doesn't exist), we just run flutter test normally.

WIDGET TEST STRATEGY:
- Extend `bod_drilldown_sheets_test.dart` with 2 new BodKpiGrid tests.
- Test that AvgTtrDays card renders with value "4.2 days" and TTR color pill.
- No golden files needed — use text/widget finders.

FILES CHANGED:
1. [MOD] lib/features/analytics/widgets/bod_kpi_grid.dart — Add AvgTtrDays card to grid (263 lines — safe)
2. [MOD] test/features/analytics/widgets/bod_drilldown_sheets_test.dart — Add 2 new BodKpiGrid tests

Total: 2 files. Within 4-file rule. ✅

LAYOUT SAFETY:
- New card uses same _buildKpiCard() function as existing cards.
- Wrapped in Expanded inside a Row — safe.
- AvgTtrDays value: "4.2 days" format. 
- Color logic: green if ≤7.0, yellow if ≤14.0, red if >14.0.
- Tooltip: "Average days to resolve an action plan".

DI SAFETY: N/A — StatelessWidget, no locator change.

ZERO-VALUE STATE: If avgTtrDays == 0.0, show "N/A" instead of "0.0 days" to avoid misleading execs.
</latent_space_scratchpad>

# Implementation Plan: Golden Metrics MVP — Slice 2 (Flutter KPI Card Promotion)

**Date**: 2026-05-28 | **ConvID**: cdefadc1-bcb6-48a6-b2df-d50ea610949f  
**Pattern**: UI Widget Extension — Additive KPI Card in Existing Grid  
**Route**: Route 1 (Direct Build — UI only, no network, no auth)

---

## Input Lineage

`c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\analysis_epic_20260528_162900_c3563378_golden-metrics-mvp_c3563378-9cd7-4609-ae6d-2aba9f71c9ff.md`

---

## Executive Summary & Out of Scope

**Goal**: Promote `AvgTtrDays` to a visible primary KPI tile in `BodKpiGrid`.

**Critical Discovery from Code Research**: `CompletionRate` is **already a visible KPI card** in Row 1 of `BodKpiGrid` (L93–109). The epic diagram described a partially stale state. The **only missing promotion** is `AvgTtrDays` as a standalone KPI card.

```
[ACTUAL CURRENT — BodKpiGrid]        [TARGET — after Slice 2]
Row 1: Avg Score | Completion Rate   Row 1: Avg Score | Completion Rate (unchanged)
Row 2: Total Audits | Open APs       Row 2: Avg TTR Days ★ | Open APs
Row 3: Active Stores | Total Auditors Row 3: Total Audits | Active Stores
                                      Row 4: Total Auditors
```

`AvgTtrDays` is currently only rendered as a `PillChip` inside `BodApAgingFunnel` (card5). It must become a standalone KPI card in the grid.

**Out of Scope — YAGNI:**
- ❌ Backend changes (no endpoint, no model, no migration).
- ❌ Golden image files (none exist; project does not use `matchesGoldenFile`).
- ❌ `BodDashboardBody` changes (it already passes `chainKpis.toJson()` which includes `avgTtrDays`).
- ❌ Modifying how `BodApAgingFunnel` renders `AvgTtrDays` — leave it as-is.
- ❌ Removing any existing KPI cards.

---

## System Context

| Dimension | Value |
| :--- | :--- |
| **Offline/Online** | Data already in snapshot payload. No network change. |
| **RBAC** | BOD admin-only. No RBAC change. |
| **API Contract** | `BodChainKpis.avgTtrDays` already parsed in `BodChainKpis.fromJson()` (L28–30). `toJson()` includes `avgTtrDays` key (L45). Field is always present. |
| **DI Safety** | N/A — `BodKpiGrid` is a `StatelessWidget`. No service locator change. |
| **Layout Safety** | New card uses same `_buildKpiCard()` + `Expanded` in a `Row`. No overflow risk. |

---

## Lifecycle Context

| State | Behavior |
| :--- | :--- |
| **Success** | AvgTtrDays card shows `"4.2 days"` (green PillChip ≤7d, yellow ≤14d, red >14d). |
| **Empty / Zero** | If `avgTtrDays == 0.0`, card shows `"N/A"` — prevents executives from seeing misleading `"0.0 days"`. |
| **Loading** | `BodKpiGrid` does not handle loading state (managed by parent page). No change. |
| **Error** | `BodDashboardBody` catches exceptions per card via `try/catch`. No change needed. |

---

## Constraint Traceability

| Constraint | Source | Test ID |
| :--- | :--- | :--- |
| AvgTtrDays must be a visible primary KPI tile | Epic L258–260 | TC-S2-01 |
| Zero value renders "N/A" not "0.0 days" | Empty State requirement | TC-S2-02 |
| Color-coded indicator: green ≤7d, red >14d | Epic "speedometer" concept | TC-S2-03 |
| Existing cards are not removed | YAGNI + regression | TC-S2-04 (existing C4-TEST-02) |
| Card layout does not overflow in 400px viewport | Layout Safety | TC-S2-05 |

---

## Test Contracts

| ID | Description | Fail Reason |
| :--- | :--- | :--- |
| **TC-S2-01** | BodKpiGrid shows "Avg TTR Days" label and "4.2 days" value when `avgTtrDays: 4.2` | Card not added — label not found |
| **TC-S2-02** | When `avgTtrDays: 0.0`, card displays "N/A" not "0.0 days" | Zero guard missing — shows "0.0 days" |
| **TC-S2-03** | Green color indicator when `avgTtrDays: 5.0` (≤7) | Color logic missing or wrong threshold |
| **TC-S2-04** | All existing cards still render (Active Stores, Total Auditors, Open APs) | Regression — existing card removed |
| **TC-S2-05** | No RenderFlex overflow at width=400 | Layout broke in narrow viewport |

---

## Test Fixture & Payloads

**Seed `chainKpis` map for TC-S2-01, TC-S2-03:**
```dart
final chainKpis = {
  'totalAudits': 150,
  'avgScore': 78.5,
  'completionRate': 92.0,
  'completionRateDelta': 1.5,
  'openAPs': 12,
  'overdueAPs': 3,
  'activeStores': 45,
  'totalAuditors': 14,
  'avgTtrDays': 4.2,   // ← key under test
};
```

**Seed for TC-S2-02 (zero guard):**
```dart
final chainKpis = { 'avgTtrDays': 0.0, ...other fields... };
// Assert: find.text('N/A') and NOT find.text('0.0 days')
```

---

## Tools & Commands

```
# Run only analytics widget tests
rtk flutter test test/features/analytics/widgets/bod_drilldown_sheets_test.dart

# Full flutter test suite (regression check)
rtk flutter test
```

> No `--update-goldens` needed — project does not use `matchesGoldenFile`.

---

## Proposed Changes

| # | Action | File | Lines | Change |
| :--- | :--- | :--- | :--- | :--- |
| 1 | `[MOD]` | `lib/features/analytics/widgets/bod_kpi_grid.dart` | 263 (✅ under 400) | Add `avgTtrDays` extraction from `chainKpis` (L40 area). Restructure to 4 rows, insert `Avg TTR Days` card in Row 2. |
| 2 | `[MOD]` | `test/features/analytics/widgets/bod_drilldown_sheets_test.dart` | 296 (✅ under 400) | Add 3 new `BodKpiGrid` tests: TC-S2-01, TC-S2-02, TC-S2-03 inside existing `group('BodKpiGrid TDD Tests')`. |

---

## Concept Diagram

```
[BodKpiGrid.build()]
  chainKpis['avgTtrDays'] ── read ──► avgTtrDays (double)
                                            │
                     ┌──────────────────────┤
                     │  avgTtrDays == 0.0   │  avgTtrDays > 0
                     ▼                      ▼
               display: "N/A"       display: "4.2 days"
                                            │
                          ┌────────── threshold check ─────────┐
                          │ ≤ 7d: green PillChip               │
                          │ ≤ 14d: yellow PillChip             │
                          │ > 14d: red PillChip                │
                          └─────────────────────────────────────┘

[Grid layout after change]
  Row 1: ─── Avg Score ─────────── Completion Rate ───
  Row 2: ─── Avg TTR Days ★ ─────── Open APs ──────── (AvgTtrDays replaces old Total Audits slot)
  Row 3: ─── Total Audits ─────── Active Stores ───── (Total Audits demoted to row 3)
  Row 4: ─── Total Auditors ─────── (full-width via Expanded + SizedBox(width: 12) + Expanded filler)
```

---

## Execution Slices

### Slice 2-A: Add AvgTtrDays KPI Card to BodKpiGrid `[Route 1 — Direct Build]`

**Summary**: Restructure `BodKpiGrid` rows to insert `Avg TTR Days` as a primary card in Row 2. Move `Total Audits` to Row 3. Add zero-value guard (`"N/A"`). Add threshold-based color indicator.

**Entry State**: `BodKpiGrid` has 3 rows, no `avgTtrDays` card, `avgTtrDays` is only read by `BodApAgingFunnel`.  
**Exit State**: `BodKpiGrid` has 4 rows, `Avg TTR Days` card is visible in Row 2 with color indicator. All existing tests pass.

**Scope**:
- `[MOD]` `lib/features/analytics/widgets/bod_kpi_grid.dart`

**Exact Changes:**
1. After L40 (existing extractions), add: `final avgTtrDays = chainKpis['avgTtrDays']?.toDouble() ?? 0.0;`
2. Compute display value: `final ttrDisplay = avgTtrDays == 0.0 ? 'N/A' : '${avgTtrDays.toStringAsFixed(1)} days';`
3. Compute color type: `avgTtrDays <= 7.0 ? PillChipType.green : avgTtrDays <= 14.0 ? PillChipType.yellow : PillChipType.red`
4. Row 2 becomes: `Avg TTR Days | Overdue / Open APs` (replaces `Total Audits | Overdue / Open APs`)
5. Row 3 becomes: `Total Audits | Active Stores` (Total Audits demoted)
6. Row 4: `Total Auditors` as single full-width card.

**Acceptance Criteria:**
- [ ] `find.text('Avg TTR Days')` — visible in widget tree
- [ ] `find.text('4.2 days')` — renders with `avgTtrDays: 4.2`
- [ ] `find.text('N/A')` — renders with `avgTtrDays: 0.0`
- [ ] `find.text('Overdue / Open APs')` still present (no regression)
- [ ] `find.text('Total Audits')` still present (no regression)
- [ ] No RenderFlex overflow at 400px width

**Complexity**: Low — 1 file, 15–20 line change, additive.

---

### Slice 2-B: Write Widget Tests for AvgTtrDays Card `[Sequential after 2-A builds GREEN]`

**Summary**: Add 3 new test cases inside the existing `BodKpiGrid TDD Tests` group in `bod_drilldown_sheets_test.dart` to verify the new card behavior.

**Entry State**: Slice 2-A changes are live and `flutter test` passes on existing tests.  
**Exit State**: 3 new tests pass. Full test suite is GREEN.

**Scope**:
- `[MOD]` `test/features/analytics/widgets/bod_drilldown_sheets_test.dart`

**Acceptance Criteria:**
- [ ] TC-S2-01: `avgTtrDays: 4.2` → `find.text('Avg TTR Days')` and `find.text('4.2 days')` found
- [ ] TC-S2-02: `avgTtrDays: 0.0` → `find.text('N/A')` found, `find.text('0.0 days')` NOT found
- [ ] TC-S2-03: `avgTtrDays: 5.0` → green `PillChip` rendered (type assertion via find.byWidgetPredicate)
- [ ] Existing C4-TEST-01 and C4-TEST-02 still PASS

**Complexity**: Low — 1 file, 3 test methods, reuses existing `buildTestWidget()` helper.

---

<command_logs>
- list_dir: lib/features/analytics/widgets → 20 files found
- list_dir: lib/features/analytics/manager → 5 files found (bod_analytics_data.dart confirmed)
- view_file: bod_kpi_grid.dart → 263 lines. Row 1: AvgScore|CompletionRate. Row 2: TotalAudits|OpenAPs. Row 3: ActiveStores|TotalAuditors. No avgTtrDays card present.
- view_file: bod_analytics_data.dart → BodChainKpis.avgTtrDays (L4,14,28-30,45). toJson() includes 'avgTtrDays' key.
- view_file: bod_dashboard_body.dart → 296 lines. Passes chainKpis.toJson() to BodKpiGrid (L49). avgTtrDays already passed to BodApAgingFunnel (L94). No change needed.
- view_file: bod_ap_aging_funnel.dart → avgTtrDays only used as PillChip label (L69-79). Not a standalone card.
- view_file: analytics_kpi_card.dart → Alternate standalone KPI card primitive. Different style. Not used in BodKpiGrid (BodKpiGrid uses internal _buildKpiCard). Decided: use existing _buildKpiCard pattern.
- view_file: bod_drilldown_sheets_test.dart → 296 lines. C4-TEST-01, C4-TEST-02 exist. No avgTtrDays test. chainKpis seed does not include avgTtrDays key (defaults to 0.0 via ?? guard).
- list_dir: test/features/analytics/widgets → 4 test files found. No golden files anywhere.
- grep_search: matchesGoldenFile → 0 results (project does not use golden image tests)
- grep_search: avgTtrDays in lib/features/analytics → Found in BodApAgingFunnel and manager only. NOT in BodKpiGrid.
- epic read L258-260 → Slice 2 = "promote CompletionRate and AvgTtrDays". CompletionRate already done. Only AvgTtrDays missing.
</command_logs>

---

## Handoff Block

**Plan Path**: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\golden-metrics-mvp\implementation_plan_20260528_200757_golden-metrics-slice2_cdefadc1-bcb6-48a6-b2df-d50ea610949f.md`

**Execute ONE AT A TIME:**

1. **Slice 2-A** → 🔨 **Direct Build** — Modify `bod_kpi_grid.dart`. Run `rtk flutter test test/features/analytics/widgets/bod_drilldown_sheets_test.dart` and confirm existing tests are GREEN.

2. **Slice 2-B** → 📝 **Write Tests** — Add TC-S2-01, TC-S2-02, TC-S2-03 to `bod_drilldown_sheets_test.dart`. Run full `rtk flutter test` to confirm all GREEN.

> [!IMPORTANT]
> `[PRODUCTION_LOCK]` — Scout does not write production code. Hand Slice 2-A to the Builder agent.
