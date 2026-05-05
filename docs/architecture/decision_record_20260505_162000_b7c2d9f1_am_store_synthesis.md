# Decision Record: AM Store Synthesis

## Input Lineage
- `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260505_150555_1a2b_am_store_limit.md`
- `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260505_160100_q9w8_am_store_concurrency.md`

**[ORIGIN_IDEA]**: Determine whether Area Manager to Store assignment should remain many-to-many (multiple AMs can manage one store) or be constrained to one AM per store, balancing operational flexibility against data integrity and reporting clarity.

<latent_space_scratchpad>
The two research artifacts are directionally identical and describe the same architecture choices:
- Option A: keep current M:M behavior.
- Option B: enforce 1 AM per store through guard logic.
- Option C: keep overlap but add a Primary AM marker.

Key synthesis finding: the true decision hinge is not only role assignment; it is downstream analytics integrity and operational conflict ownership. If product reporting and accountability models are still scalar ("the AM for store X"), unconstrained M:M creates ambiguous business ownership. If the business model is inherently collaborative coverage, M:M is valid but must be explicit in reporting semantics.

Bias trap avoided: "zero code changes" is not equivalent to "lowest risk." Option A has latent, silent data interpretation risk. Option B has immediate operational rigidity risk. Option C has implementation complexity but resolves ambiguity by design.
</latent_space_scratchpad>

## Normalized Option Summary

### Option A - Pragmatic Balance (Status Quo M:M)
- **Hypothesis**: Keep existing junction-table behavior where multiple AMs can share the same store.
- **Blast Radius**: Low code blast radius, higher business-logic ambiguity blast radius (reporting, accountability, conflict resolution).
- **Operational Effect**: Maximum flexibility, minimum engineering effort.

### Option B - Strict Native Fit (Enforce 1:M)
- **Hypothesis**: Introduce guard checks to ensure each store maps to at most one AM.
- **Blast Radius**: Moderate backend + admin UX changes; lower ambiguity in ownership.
- **Operational Effect**: Clear accountability, less flexible staffing coverage.

### Option C - Enterprise Overhaul (Primary + Secondary AM)
- **Hypothesis**: Preserve overlap but add explicit primary ownership metadata.
- **Blast Radius**: Highest (schema migration, API/DTO changes, UI changes, reporting changes).
- **Operational Effect**: Flexible and accountable, but expensive and slower to deliver.

## Red Team Attack Vectors (Hostile Interrogation)

### Attack on Option A
Catastrophic scenario: Quarterly AM performance dashboard double-counts stores with overlapping AM assignments, inflating sales ownership by 12-18%, causing bonus misallocation and HR disputes. No code crashes, but financial trust in BI is compromised.

### Attack on Option B
Catastrophic scenario: During illness/leave periods, emergency reassignment is blocked by strict uniqueness guard, leaving no authorized AM assigned in time. Store compliance tasks are missed, triggering regulatory penalties.

### Attack on Option C
Catastrophic scenario: Partial migration rollout creates mixed records (missing primary flags). Mobile/API clients interpret null primary inconsistently, leading to conflicting write authority and stale sync behavior across AM devices.

## Pugh Decision Matrix
Baseline selected: **Option A** (`0` scoring reference).  
Scoring rule: Better than baseline = `+1`, Worse than baseline = `-1`, Equal = `0`.

| Criteria (Weight) | Option A (Baseline) | Option B | Option C |
|---|---:|---:|---:|
| Origin Idea Alignment (5) | 0 | -1 | +1 |
| Operational Flexibility (4) | 0 | -1 | +1 |
| Ownership Clarity (4) | 0 | +1 | +1 |
| Reporting Integrity (4) | 0 | +1 | +1 |
| Delivery Speed / Effort (3) | 0 | -1 | -1 |
| Implementation Risk (3) | 0 | 0 | -1 |
| **Weighted Total** | **0** | **(-5 -4 +4 +4 -3 +0) = -4** | **(+5 +4 +4 +4 -3 -3) = +11** |

## Final Verdict (Mathematical Winner)
**Winner: Option C (Primary + Secondary AM model)** with weighted score `+11`.

Rationale: Option C is the only path that preserves the user's origin idea (multi-AM capability) while directly addressing ownership and reporting ambiguity. Option A appears cheap but externalizes risk into BI correctness and accountability. Option B simplifies ownership at the cost of undermining the multi-AM use case.

## Executive Business Summary
If the business truly needs shared AM coverage, the current "just allow overlap" model is eventually expensive because disputes move from code to operations, incentives, and reports. Option C costs more upfront, but it prevents recurring ambiguity by defining who is accountable per store while still allowing backup AM coverage. If budget/timeline is tight, Option A can be tolerated only with an explicit temporary policy and reporting caveat; it should be treated as a short-term compromise, not a final architecture.

## Strict Implementation Constraints & Human Reminders
- Do not implement guard or schema changes until Product confirms that "primary AM ownership" is an accepted business concept.
- Any implementation must keep legacy data valid during migration (backfill strategy required for `Primary` marker).
- Reporting queries must explicitly consume the primary ownership model to avoid accidental double-counting.
- Admin UI must visually indicate primary vs supporting AM assignments to prevent accidental misuse.
- Human-in-the-loop approval is mandatory before changing auth/assignment boundaries.

## Handoff Block
- **Final Verdict**: Implement Option C (Primary + Secondary AM assignment model) as the target architecture.
- **Strict Constraints**:
  1. No silent migration; require explicit backfill and compatibility window.
  2. Preserve existing M:M rows while introducing deterministic primary ownership.
  3. Reporting must be updated in lockstep with schema/API changes.
  4. Admin UX must expose ownership role labels.
- **Execution Slices**:
  1. Data model + migration slice.
  2. API contract + validation slice.
  3. Admin UI ownership controls slice.
  4. Reporting alignment slice.
- **Requirements Alignment Check**: Yes. Because the winning architecture introduces a new ownership concept ("Primary AM"), the requirements artifact should be updated to include assignment semantics, conflict resolution, and reporting rules.
- **AI Agent Mission Brief**: Build a phased rollout that adds explicit primary ownership to AM-store assignments while preserving shared coverage. Ensure reporting and admin UX are updated concurrently so business semantics remain consistent end-to-end.
- **Next Workflow Command**: `/analyze-feature "C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260505_162000_b7c2d9f1_am_store_synthesis.md"`
