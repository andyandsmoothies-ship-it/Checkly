# Diagnostic Report: Area Campaigns Data Validation for user 'am2'

## Input Lineage
- **Source Input**: `am2` Area Campaigns Screen (User prompt and screenshot)
- **Target Analysis**: `GetAreaCampaignProgress.cs` and underlying database state.

## Root Cause / Finding
**Verdict: The data displayed on the screen is 100% CORRECT and accurately reflects the database state.**

There is no technical bug or mathematical discrepancy. The user `am2` oversees exactly 6 stores. The values shown (e.g., "0 of 2", "0 of 6") reflect the exact number of stores *within am2's scope* that have been assigned each specific campaign, and their current `pending` statuses.

## Explicit Code Trace (Premises + Proof)

1. **Area Manager Store Scope**:
   We ran a SQL query to fetch all stores assigned to `am2@checkly.local` via `profile_store_assignments`.
   *Proof*: The database returned exactly 6 stores (Checkly Binh Thanh, D1 - Bui Vien, D10, D2, D1 - Nguyen Hue, D3).

2. **Campaign Assignment Scoping**:
   `GetAreaCampaignProgress.cs` accurately filters program assignments to only count stores that the Area Manager manages:
   ```csharp
   .Where(a => assignedStoreIds.Contains(a.StoreId))
   ```
   *Proof*: We ran a query replicating this logic. 
   - `Campaign MKT Urgent`: Assigned to all 6 stores.
   - `Check new MKT campage June 2026`: Assigned to only 2 of am2's stores.
   - `Check POSM`: Assigned to all 6 stores.
   - `MKT thang 6 2026 Lan 2`: Assigned to only 2 of am2's stores.
   This perfectly matches the "of X Stores" denominators in the UI screenshot.

3. **Completion Calculation**:
   The UI shows "0 Stores Completed" for all campaigns. We queried the `status` of all assignments scoped to `am2`.
   *Proof*: Every single assignment currently has a status of `pending`. None have reached `submitted`, `verified`, or `needs_revision` (the `CompletedStatuses` array). Thus, 0 completed stores is accurate.

4. **Global Data Check**:
   We checked if the campaigns were somehow globally restricted. 
   *Proof*: "Campaign MKT Urgent" has 10 assignments globally, but `am2` only sees 6, proving the PBAC/Area scoping isolation is working flawlessly.

## Proposed Scope-Limited Fix
**No code changes are required.** The system is operating exactly as designed.

**Trade-offs / Pros & Cons**:
- *UX Consideration*: If the Area Manager is confused why a campaign says "2 Stores" when they manage 6 stores, it's because the system (or another admin) only assigned that campaign to 2 of their specific stores. The UI grammatically states "X of Y Stores Completed", which correctly implies Y is the target participating subset. 
- *Recommendation*: If this is causing user confusion, a future UX enhancement could be adding a tooltip or phrasing like "2 Participating Stores in your Area", but currently, the data mapping is mathematically sound.

<forensic_evidence>
Executed:
- `query.sql`: Confirmed `GetAreaCampaignProgress` backend grouping logic matches UI.
- `query_global.sql`: Confirmed total assignments exceed `am2`'s scope, proving area-isolation works.
- `query_status.sql`: Confirmed all `am2` scoped assignments are in 'pending' status.
- `query_am2_stores.sql`: Confirmed `am2` manages exactly 6 stores.
</forensic_evidence>

## Handoff Block

**Final Diagnostic Verdict**: The Area Campaigns screen data for `am2` is 100% correct. No bugs found.
**Blast Radius**: None.
**AI Agent Mission Brief**: The diagnostic investigation is complete and proves the data is mathematically sound. No implementation is needed.

### Execution Queue
- [x] Review diagnostic report
- [x] Close investigation
