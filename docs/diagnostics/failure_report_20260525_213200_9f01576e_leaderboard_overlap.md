# Failure Report: Leaderboard Overlap Diagnosis

## Input Lineage
- **Source Input**: `c:\Users\HP\Documents\GitHub\Checkly\server\Features\Analytics\BodReportCalculator.cs`

## Root Cause
When the total count of stores in the database ($N$) is less than or equal to the leaderboard limit (which is 5), taking the top 5 and bottom 5 stores will retrieve the **exact same set of stores**. 
- The **Top Performing** list sorts them **descending** (92.8%, 92.8%, 92.8%, 85.7%).
- The **Bottom Performing** list sorts them **ascending** (85.7%, 92.8%, 92.8%, 92.8%).

Since there are only 4 stores in total, the bottom list correctly starts with the worst store (Landmark 81 at 85.7%), but must list the remaining 3 stores to fill the slots. Because the remaining stores all have 92.8%, they are listed as the "next worst" stores.

## Explicit Code Trace

### Premise 1: Database contains exactly 4 stores
We have 4 active stores with audits in the last 30 days:
1. `Checkly Go Vap - Quang Trung` (92.8%)
2. `Checkly D1 - Bui Vien` (92.8%)
3. `Checkly D10 - Su Van Hanh` (92.8%)
4. `Checkly Binh Thanh - Landmark 81` (85.7%)

### Premise 2: Bottom Stores Query
In [BodReportCalculator.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/BodReportCalculator.cs#L251-L256), the code queries bottom stores as follows:
```csharp
bottomStores = storeStats
    .OrderBy(x => x.AvgScore)
    .ThenBy(x => x.AuditCount)
    .Take(5)
    .Select(x => new BodStoreRankEntry(x.StoreId, x.StoreName, Math.Round(x.AvgScore, 1), x.AuditCount, null))
    .ToList();
```

### Proof of Overlap
1. `storeStats` contains 4 elements.
2. `.OrderBy(x => x.AvgScore)` sorts them ascending:
   - Index 0: Landmark 81 (85.7%)
   - Index 1: Bui Vien (92.8%)
   - Index 2: Su Van Hanh (92.8%)
   - Index 3: Go Vap (92.8%)
3. `.Take(5)` takes all 4 elements since $4 \le 5$.
4. Therefore, the list displays Landmark 81 at the top of the "Bottom" list, followed by the three 92.8% stores.

## Proposed Scope-Limited Fix / Actions
There is **no bug in the code**. The system is executing correct sorting logic. However, if this visual overlap is confusing for the user, here are two options:

### Option A: Do nothing (Standard Industry Behavior)
- **Pros:** Correctly shows all stores in the chain. When the chain grows to 10+ stores, the lists will automatically separate and stop overlapping.
- **Cons:** Looks overlapping when the user only has 4 stores during development/testing.

### Option B: Filter out high-performing stores from the bottom list
We can modify the query so that the bottom list **only** displays stores with a score lower than a threshold (e.g. `< 90%` or `< 85%`).
- **Pros:** The bottom list will only show truly low-performing stores.
- **Cons:** If all stores are performing excellently (e.g., all have 95%), the bottom list would be completely empty, which is also confusing.

---

## Forensic Evidence
<forensic_evidence>
Searched and reviewed `BodReportCalculator.cs` lines 244-256 to isolate the sorting and taking logic for both top and bottom performing stores.
</forensic_evidence>

---

## Handoff Block
1. **Final Diagnostic Verdict:** Mathematically correct behavior. The overlap happens because the total store count (4) is less than the list capacity limit (5).
2. **Blast Radius:** None.
3. **AI Agent Mission Brief:** Explain the mathematical sorting behavior clearly to the user, highlighting that it will automatically resolve as more stores are added to the database.
4. **Execution Queue:**
   - [x] Diagnostic explanation completed.
