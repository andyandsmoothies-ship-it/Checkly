# Research: Area Manager Store Concurrency

**[ORIGIN_IDEA]**: The user wants to explore the architectural idea of allowing a single store to be managed by multiple Area Managers simultaneously (many-to-many relationship), vs enforcing a strict 1-to-1 limit like Store Managers have.

<latent_space_scratchpad>
*   **Hypothesis**: The system currently defaults to allowing multiple AMs per store because it relies on the `ProfileStoreAssignment` junction table, and no specific guard prevents overlaps.
*   **Source Checked**: `server/Common/Auth/RoleAssignmentGuard.cs` only guards `FindExistingStoreManager` and the legacy `FindExistingAreaManager` (which used `AreaId`, not store arrays). `server/Features/Admin/UpdateUser.cs` lacks cross-user collision checks.
*   **Architectural Implication**: If we allow M:M, downstream aggregations (like "Who is the AM for Store X?") will return lists. If we restrict to 1:M (1 AM per store), we must build a validation sweep during assignment that blocks the UI if another AM already claims that store.
</latent_space_scratchpad>

<forensic_evidence>
- Searched `RoleAssignmentGuard.cs` and confirmed it lacks M:M store collision logic for AMs.
- `UpdateUser.cs` only validates that `StoreId`s exist, not whether they are claimed.
</forensic_evidence>

## E2E Workflow Map
*   **Upstream Trigger**: Admin selects stores for an AM in the UI and clicks Save.
*   **Backend Validation**: `UpdateUser.cs` validates Store IDs exist -> missing step: does not validate if stores are already claimed.
*   **Downstream Effect**: Junction table `ProfileStoreAssignment` saves mappings.
*   **Reporting/Read Path**: When Flutter clients sync, they receive `ProfileStoreAssignment`. If 2 AMs claim the same store, the store appears on both AM devices.

## Blind Spots & Constraints
1. **Reporting Multiplicity (NFR)**: If a store has 2 AMs, regional sales reports grouping by AM will double-count that store's revenue unless specifically de-duplicated.
2. **Concurrency Conflicts (Business Rule)**: If AM-1 and AM-2 both submit overriding operational audits for the same store, there is currently no "Primary AM" hierarchy to resolve the conflict.
3. **UI Transparency (UX)**: The current Admin UI does not show if a store is *already* assigned to someone else. An admin might accidentally assign an AM to a store not realizing they are stealing/sharing it.

## Architectural Conflicts
*   **Conflict with GEMINI.md Gotchas**: The system relies on `RoleAssignmentGuard.cs` for role limits. If we enforce 1:1, we cannot just hack `UpdateUser.cs`—we must formally extend `RoleAssignmentGuard` and follow the *7 Sync Steps* to ensure consistency.

## Comparative Decision Matrix

| Option | Architecture | Pros | Cons | Effort |
| :--- | :--- | :--- | :--- | :--- |
| **Option A: Pragmatic Balance (Status Quo)** | Leave the M:M architecture as-is. Embrace shared stores. | Zero backend changes. Matches real-world scenarios (e.g., Ops AM + Training AM). | Can cause confusion if sharing was an accident. | Trivial |
| **Option B: Strict Native Fit (Enforce 1:M)** | Add `FindExistingAreaManager` guard to `UpdateUser.cs`. | Clear ownership. 1 store = 1 AM. | Blocks legitimate temporary handoffs/coverage. | Small |
| **Option C: Enterprise Overhaul** | Add `IsPrimary` flag to `ProfileStoreAssignment`. | Supports overlapping coverage while maintaining a clear "boss" for reporting. | Requires DB Migration, DTO updates, UI changes. High complexity. | Large |

---
## Handoff Block

**Final Verdict**: Viable. The M:M relationship (Option A) is actually the most flexible and robust architecture for retail environments. Option B (enforcing 1:1) is easy to build but restricts operational flexibility. Option C is overkill.

**Effort Sizing**: 
- Option A: 0 points (Already implemented).
- Option B: 2 points (Backend Guard + UI Error Handling).

**AI Agent Mission Brief**: The researcher has mapped the implications of allowing multiple AMs per store. The current architecture natively supports it (M:M). The next agent should wait for the user to decide if they want to **keep the flexibility (Option A)** or **enforce strict ownership (Option B)**.

**Next Step for User**: 
Please review the artifact and reply with your decision: "Let's go with Option A" or "Let's go with Option B". 

You can read the full research here:
`docs/product/research_20260505_150555_1a2b_am_store_limit.md`
