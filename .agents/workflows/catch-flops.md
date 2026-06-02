---
description: SRE Failure Mode & Flop-Catcher Review.
---

# Workflow: /catch-flops

> [!CAUTION]
> **SRE Red-Team Mode Enabled**. Role: **Failure Analyst**.
> Do not assume everything will work perfectly. Your mission is to find the hidden "flops" (critical failure modes, database crashes, logic/math errors, and UX edge cases) in the proposed design or modified code before it reaches production.

```text
[ Analysis Plan / Code ] 
           │
           ▼
  [ /catch-flops Audit ] ──► [ Check Failures: DB, Math, Sync, UI ]
           │
           ▼
   [ Failure Report ] ──► [ Feed directly into Tests & Implementation ]
```

---

## Step 1: Preparation & Setup
- [ ] **Create Task Tracker**: Create `docs/features/flop_audit/task_[YYYYMMDD_HHMMSS]_flop_audit.md` using this strict schema:
```markdown
# Task: Catch Flops / Failure Modes Audit
Workflow: /catch-flops | Track: C
## Input Lineage
- **Source Plan/Code**: `[Absolute_Path_to_Plan_or_Code_File]`
## Steps
- [ ] Step 1: Preparation & Setup
- [ ] Step 2: Database & Data Integrity Interrogation
- [ ] Step 3: Calculation & Logical Border Sweeps
- [ ] Step 4: Offline Sync & State Checks
- [ ] Step 5: Visual, Layout & Animation Checks
- [ ] Step 6: First Principles Gate, Verdict & Action Plan
```
- [ ] **Identify the Target**: Locate the absolute path of the epic plan, feature plan, or active code files to be audited.

---

## Step 2: Database & Data Integrity Interrogation
Analyze the database, entities, and repository layers. Look for these specific database "flops":
- [ ] **Duplicate ID / Guid Collisions**: Does the save/update operation track entities with client-provided IDs? Will a duplicate GUID in the payload trigger an EF Core primary key tracking crash (`System.InvalidOperationException`)?
- [ ] **PostgreSQL Null Inequality Bug**: Does any query use inequality filters like `x.Status != "rejected"`? In Postgres, this silently excludes all rows where `Status` is `NULL`. Ensure it is written as `(x.Status == null || x.Status != "rejected")`.
- [ ] **Unique Index Constraint Violation**: Does the database schema enforce a unique index (like `ProfileStoreAssignmentConfiguration` enforcing a unique `StoreId`)? Will bulk assignments trigger a Postgres `23505` duplicate key violation?
- [ ] **Cascading Delete Risks**: If deleting a parent record (like a Template or a Store), will related records in dependent tables cause constraint violations or orphan data?

---

## Step 3: Calculation & Logical Border Sweeps
Review all mathematical formulas, calculators, and core logic components:
- [ ] **Empty / Zero Input Errors**: What happens to calculators (like `ScoringEngine`) if a list is empty? Will it throw a divide-by-zero exception or return an incorrect `100%` / `0%` score?
- [ ] **Null Section Scores**: If calculating section averages, does the serialization match the expected Drift/JSON format? (For example, Flutter expects UUID keys with nested `"title"`, `"score"`, and `"maxScore"` properties).
- [ ] **Purity / Mixed Mode Violations**: What happens if an admin mixes scored criteria and unscored criteria in the same section? Will the final score render as `NULL` on dashboards as expected, or will it miscalculate?
- [ ] **Risk Trigger Overrides**: If a failed item triggers a critical `IsRisk = true` event, does the calculator properly override the entire score to `0%` instantly?

---

## Step 4: Offline Sync & State Checks
Check synchronization boundaries, serialization, and offline databases:
- [ ] **Drift / SQLite Array Serialization**: SQLite does not support array types natively. When storing lists (like `categoryTags`), ensure they are serialized as comma-separated strings and split/sanitized correctly (e.g. removing empty strings via `.where((t) => t.isNotEmpty).toList()`) during retrieval.
- [ ] **Sync Step completeness**: If adding a new capability or table, verify that all 7 Sync Steps are fully mapped (Entity, DbContext, Server DTO, Endpoint Projections, Sync Endpoint, Flutter DTO, Seed files).
- [ ] **Idempotency & Double-Tap**: Can a slow network cause a user to tap a button twice? Will the API save duplicate records, or is there an advisory database locking guard?

---

## Step 5: Visual, Layout & Animation Checks
Verify layout scaling, animation disposes, and accessibility tags in Flutter:
- [ ] **Card Title Flex Overflow**: In narrow layout environments, will long horizontal header rows containing text and icons crash the renderer? Ensure the text is wrapped inside `Expanded` or `Flexible`.
- [ ] **Asynchronous Timer Hangs**: Do animated components (like BouncyListWrapper or StaggeredListItem) cancel their timers in `dispose()`? If not, widget tests will fail with a `"A Timer is still pending..."` error.
- [ ] **Reduced Motion Compliance**: Are micro-animations checking for reduced motion settings via `MediaQuery.disableAnimationsOf(context)`? If enabled, animations must snap instantly.
- [ ] **Widget Type Assertions**: Do unit tests assert exact classes like `Card` or `ElevatedButton`? Ensure custom stylized containers or buttons do not break existing test assertions.

---

## Step 6: Create Verdict & Action Plan
- [ ] **First Principles Gate**: Answer the 4 First Principles questions to identify deeper system-level constraints and failure modes:
  1. *Physics & Limit*: What is the ultimate ceiling/scale limit (e.g. TPS, DB locks, memory) and at what exact scale will this implementation fail?
  2. *Simplicity*: How can this design be implemented with 50% fewer files/classes/lines of code, and what bloat/complexity is being introduced?
  3. *Blast Radius*: If this component fails (e.g., deadlocks, timeout, DB down), what other systems are impacted and how does it fail-gracefully?
  4. *Observability*: What metric, log, or telemetry proves this feature is healthy, and what is the exact alert condition for failure?
- [ ] **Generate Report**: Save `audit_failure_report_[YYYYMMDD_HHMMSS].md` inside the absolute workspace folder `docs/reports/diagnostics/[topic]/`. Ensure it includes the **First Principles Gate** answers explicitly.
- [ ] **Write the Failure Scenarios**: Explicitly list the discovered flops, categorizing them by severity:
  - `🔴 Critical`: Causes system crash, database error, or data corruption.
  - `🟡 Warning`: Causes visual/layout bugs, test hanging, or incorrect calculations.
- [ ] **Map to Actionable Tasks**: Convert every discovered flop into an explicit test case or guard check inside your implementation plan.

---

## ## Handoff Block
- **Audit Verdict**: [Fatal/Brittle/Resilient]
- **Failure Report Path**: `docs/reports/diagnostics/[topic]/audit_failure_report_[YYYYMMDD_HHMMSS].md`
- **Next Steps**: A short 1-2 sentence TL;DR for the next agent to implement the required fixes.