# Architecture Audit: SyncSubmissions

**Target**: `server/Features/Submissions/SyncSubmissions.cs`
**Date**: 2026-05-12
**Auditor**: Sentinel (Chief Architect / SRE)

## Verdict: 🔴 Fatal (Bricks the system / Data Corruption / DDoS)

The current synchronization endpoint is structurally broken and guarantees both database collapse under load and silent data corruption on mobile clients.

---

## The Interrogation

### Critic 1: The Zombie (Stateless Illusion)
**Failure**: The `CountAsync(ct)` operation on an open-ended date filter (`UpdatedAt >= since`) forces the database to evaluate the entire index segment for every single paginated request.

### Critic 2: The Split-Brain (State & Sync)
**Failure**: **Offset Pagination on a Mutating Stream**. Using `Skip((page - 1) * pageSize)` over an `OrderBy(UpdatedAt)` is catastrophic. If an existing submission is updated (moving it to the end of the `UpdatedAt` index) while a mobile client is paginating from Page 1 to Page 2, the records shift. The client will **permanently miss records** (Split-Brain) or download duplicates. This breaks the fundamental promise of offline sync.

### Critic 3: The 2 AM Landmine (Resilience & Observability)
**Failure**: **The Thundering Herd**. If 500 mobile auditors turn on their devices at 8:00 AM, they will simultaneously hit this endpoint. Because the endpoint defaults to `DateTimeOffset.MinValue` for full syncs and executes a `CountAsync()`, 500 massive table scans will hit the primary database at once, locking rows and causing a self-inflicted DDoS.

### Critic 4: The Brick (Boundary & Exploit Risk)
**Pass**: IDOR checks via `ResourceAccessGuard` are correctly implemented, preventing tenant bleed.

### Critic 5: Cognitive Debt (The Easy Button)
**Pass**: The code is flat and readable without fake-smart abstractions, but the mechanics are naive.

---

## Actionable Fix & Trade-offs

### 1. Replace Offset Pagination with Keyset (Cursor) Pagination
Replace `Skip()` and `Take()` with a strict cursor-based query using the last seen `UpdatedAt` and `Id`.
```csharp
query.Where(s => s.UpdatedAt > cursor.UpdatedAt || (s.UpdatedAt == cursor.UpdatedAt && s.Id > cursor.Id))
     .OrderBy(s => s.UpdatedAt).ThenBy(s => s.Id)
     .Take(pageSize + 1); // +1 to check for next page
```
* **Complexity**: **Low**. This is a standard EF Core query refactor. No new infrastructure needed.
* **Trade-offs / Pros & Cons**: 
  * **Pro**: Mathematically guarantees zero missed records or duplicates during active syncs. O(1) query time.
  * **Con**: Breaks API contract. Mobile clients must be rewritten to pass cursors instead of `page=2`.

### 2. Eradicate `CountAsync()` (Drop TotalCount)
Remove the `total` property from the `PagedResult`. Return a boolean `HasNextPage` instead (calculated by pulling `pageSize + 1`).
* **Complexity**: **Low**. Simple deletion of the DB query and DTO property.
* **Trade-offs / Pros & Cons**: 
  * **Pro**: Instantly saves the primary database from the 8 AM Thundering Herd. Queries execute in milliseconds regardless of table size.
  * **Con**: Mobile UI can no longer show a determinate "10 of 500" progress bar during initial sync. It must use an indeterminate spinner.

---

## Handoff Block

1. **Verdict**: 🔴 FATAL. `SyncSubmissions.cs` is mathematically guaranteed to corrupt offline client state via Offset Pagination on a mutating index.
2. **2AM Landmines**: `CountAsync()` on a massive table will trigger a DDoS when workers clock in.
3. **Mission Brief**: The Builder must rewrite the `/api/sync/submissions` endpoint to use Keyset (Cursor) pagination (`UpdatedAt`, `Id`) and completely remove the `CountAsync()` operation. Mobile clients must be updated to expect a cursor and `HasNextPage` instead of total counts.
4. **Next Workflow**: `/analyze-epic` or `/implement`
