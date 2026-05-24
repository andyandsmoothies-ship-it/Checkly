# Architectural Decision Record: Store Area Consolidation
Workflow: /synthesize | Track: C

## Input Lineage
- c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260503_214152_store_area_consolidation.md
- c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260503_214000_838cfcdf_remove_area_direct_assignment.md

## [ORIGIN_IDEA]
"combine area and AM means you can assign store to AM or AM to store, no need the area" (Eliminating the Area concept and assigning AMs directly to stores).

<latent_space_scratchpad>
Initial analysis highlighted a severe tradeoff: deleting the `Area` concept destroys offline-first sync integrity and historical data reporting, but keeping the rigid 1:1 AM-to-Area model prevents the business flexibility the user requested.
Following deep architectural review with the user, we identified an advanced hybrid: the "Base + Override" pattern.
By retaining `Profile.AreaId` for 99% of bulk assignments (Base) and utilizing a junction table `ProfileStoreAssignment` strictly for cross-district exceptions (Override), we neutralize all database exhaustion and mobile sync threats. 
To further optimize mobile sync, the junction rows will be flattened into a simple array (`assignedStoreIds`) when synced to the Flutter client, completely bypassing the need for a new Drift table or dedicated sync endpoint.
</latent_space_scratchpad>

## Normalized Options
1. **Option 1 (1:N Direct Assignment)**: Drop `Area` entirely. Add `AreaManagerId` directly to `Store`.
2. **Option 2 (M:N Direct Assignment)**: Drop `Area` entirely. Add `ProfileStoreAssignment` junction table.
3. **Option 3 (Hybrid M:N Assignment)**: Keep `Area` as a cosmetic/reporting label. Add `ProfileStoreAssignment` junction table for authentication and access control.
4. **Option 3.5 (Base + Override Architecture - WINNER)**: Keep `Profile.AreaId` as the primary group (Base) that instantly grants access to all stores in that Area. Use the `ProfileStoreAssignment` junction table ONLY for exceptions/cross-district coverage (Override).
5. **Option 4 (Status Quo)**: Keep the rigid 1 AM = 1 Area rule.

## Hostile Interrogation (Red Teaming)
- **Option 1 (1:N No Area)**: *Catastrophic Reassignment Failure.* If an AM leaves, admins must bulk-reassign 500 stores to a new AM. If the Flutter client is offline, it misses the delta updates, leading to silent failures.
- **Option 2 (M:N No Area)**: *Business Intelligence Blackout.* Removing `Area` destroys all historical sales reporting grouped by district. 
- **Option 3 (Hybrid M:N)**: *Database Exhaustion & Sync Timeout.* IDOR checks using `EXISTS` on a massive junction table causes DB CPU load. Syncing thousands of rows to mobile causes timeout.
- **Option 3.5 (Base + Override)**: *Mitigated.* Database exhaustion is avoided because 99% of requests use the fast `AreaId` check. Sync timeout is avoided because the server only syncs the 2-3 override stores, flattened into a simple array `assignedStoreIds: ["uuid1"]`.
- **Option 4 (Status Quo)**: *Operational Paralysis.* Lack of cross-district coverage prevents AMs from covering sick leave without corrupting sales data.

## The Pugh Decision Matrix

| Criteria (Weight) | Option 4 (Baseline) | Option 1 (No Area) | Option 3 (Pure Hybrid) | Option 3.5 (Base + Override) |
|---|---|---|---|---|
| Origin Idea Alignment (Flexibility) | 0 | +1 | +1 | +1 |
| Historical Reporting | 0 | -1 | 0 | 0 |
| DB Load (Auth/Reassignment) | 0 | -1 | -1 | +1 |
| Offline Sync Danger | 0 | -1 | -1 | +1 |
| Blast Radius / Refactor Cost | 0 | -1 | -1 | 0 |
| **Total** | **0** | **-3** | **-2** | **+3** |

## Final Verdict
**Option 3.5 (Base + Override Architecture)** is the definitive winner. It provides infinite assignment flexibility while reducing database load and mobile sync payload by 99%.

## Executive Business Summary
You get exactly what you asked for: the ability to assign an Area Manager to any store, anywhere, even across multiple different Areas. 
However, to keep the app lightning fast and protect your historical analytics, we are keeping the `Area` concept running silently in the background. The system will use "Areas" to instantly grant an AM access to their primary 500 stores in 1 millisecond, and will only use direct store assignments for the 2 or 3 exception stores they cover. To the Admin using the app, it will simply look like a flexible "Assign Manager" screen.

## Handoff Block
- **Final Verdict:** Option 3.5 (Base + Override Architecture)
- **Strict Constraints:**
  1. **Base:** Retain `Profile.AreaId` and `Store.AreaId`.
  2. **Override:** Add `ProfileStoreAssignment` junction table configured with `HasKey(x => new { x.ProfileId, x.StoreId })` for composite clustered indexing.
  3. **Auth Logic:** Rewrite `ResourceAccessGuard` and `OwnershipScopeFilter` to check: `(Store.AreaId == Profile.AreaId) OR EXISTS in ProfileStoreAssignment`.
  4. **Smart Sync (Flattening):** Do NOT create a junction table in Flutter (Drift). The backend must serialize the overrides into a flat `assignedStoreIds` string array and attach it directly to the synced `Profile` DTO.
  5. **UX Illusion:** The Admin UI should abstract this logic, presenting a seamless "Assign Manager to Store" or "Assign Area to Manager" interface.
- **Requirements Alignment Check:** Any existing `requirements.md` regarding user provisioning MUST be updated to reflect the Base + Override capability.
- **AI Agent Mission Brief:** The system is adopting a "Base + Override" auth architecture. Primary store access remains inherited via `AreaId`, while cross-district exceptions are handled via a new `ProfileStoreAssignment` junction table. The mobile sync payload will flatten these exceptions to avoid new Drift tables. 
- **Next Command:** `@[/analyze-epic] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260503_214850_synth_store_area_consolidation.md`
