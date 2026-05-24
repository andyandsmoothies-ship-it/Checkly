# Diagnostic Report: Boardroom Analytics GET 404 Response

## 1. Executive Summary

- **Symptom**: Tapping the **BOD Analytics** dashboard displays the *"Boardroom Dashboard Empty"* screen and logs:
  `[19:00:11 INF] HTTP GET /api/analytics/bod responded 404 in 13.6786 ms`
- **Root Cause**: This is **by design** and is the expected architectural behavior. Since boardroom analytics are heavy OLAP calculations, they are pre-computed nightly at `02:00 AM` and stored in the database (`bod_report_snapshots`). On a clean database, no snapshot exists yet, so the endpoint correctly returns a `404 Not Found`.
- **Resolution**: This is a standard empty state. Tapping the **"Trigger Recomputation"** button in the UI executes a `POST /api/analytics/bod/refresh` to calculate the dashboard on-demand, which will populate the dashboard seamlessly.

---

## 2. Technical Evidence

### A. Server Design
In [GetBodReport.cs](file:///c:/Users/HP/Documents/GitHub/Checkly/server/Features/Analytics/GetBodReport.cs), the server explicitly returns `404 Not Found` if no pre-computed snapshot exists:

```csharp
var snapshot = await db.Set<BodReportSnapshot>()
    .OrderByDescending(x => x.Date)
    .FirstOrDefaultAsync(ct);

if (snapshot == null)
{
    return TypedResults.NotFound(new { error = "No BOD report snapshot has been generated yet. Nightly computation runs at 02:00 AM." });
}
```

### B. Client Design
In [bod_analytics_manager.dart](file:///c:/Users/HP/Documents/GitHub/Checkly/lib/features/analytics/manager/bod_analytics_manager.dart), the mobile client handles a `404` error specifically to trigger the empty state:

```dart
try {
  final res = await _api.getReport();
  _report = res;
  _isLoading = false;
  notifyListeners();
} catch (e) {
  _isLoading = false;
  _report = null;
  final errStr = e.toString();
  if (errStr.contains('404')) {
    _isEmpty = true; // Displays "Boardroom Dashboard Empty" UI
  }
  notifyListeners();
}
```

---

## 3. Interaction Diagram

```
[User Taps BOD Analytics]
          │
          ▼
[App GET /api/analytics/bod] ────(Empty DB)────► [Server returns 404]
                                                          │
                                                          ▼
                                            [App shows Empty State UI]
                                                          │
                                                          ▼
                                            [User clicks "Trigger Recomputation"]
                                                          │
                                                          ▼
                                            [App POST /api/analytics/bod/refresh]
                                                          │
                                                          ▼
                                            [Background Worker computes report]
                                                          │
                                                          ▼
                                            [Snapshot saved to DB]
                                                          │
                                                          ▼
                                            [App polls every 5s until success]
                                                          │
                                                          ▼
                                            [Dashboard renders premium UI!]
```

---

## 4. Verification & Testing

All backend integration tests verify this bimodal behavior and pass:

1. **`GetBodReport_EmptyDatabase_ReturnsNotFound`**: Verifies that when there are no snapshots, GET returns `404` with the descriptive error message.
2. **`RefreshBodReport_AsAdmin_TriggersRefresh`**: Verifies that calling `POST /api/analytics/bod/refresh` initiates the background computation worker on demand.

> [!NOTE]
> Everything is working completely as designed! The `404` log you saw is the completely normal initial state of a fresh database before any nightly or manual computations have run.
