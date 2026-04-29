# GEMINI.md — lib/_shared/database/

## Gotcha: Math in SQL WHERE Clauses Suppresses Indexes (OOM Risk)

**Problem:** Applying math (`/ 1000`) or standard SQLite functions (`date()`) to a column on the left side of a `WHERE` clause completely suppresses SQLite's ability to use indexes. This forces an `O(N)` Full Table Scan. For high-volume offline tables (like `cached_action_plans`), this will cause the app to freeze/ANR on startup.

**Fix:** NEVER perform math on columns directly in SQL logic if querying a large table. Always compute the static cutoff boundaries entirely in Dart, then pass them into `customStatement` via bind variables (`?`).

```dart
// WRONG ❌ — Forces Full Table Scan
await customStatement('''
  DELETE FROM cached_submissions 
  WHERE completed_at / 1000 < CAST(strftime('%s', 'now', '-90 days') AS INTEGER)
''');

// CORRECT ✅ — O(1) Index-Friendly Execution
// Calculate in Dart first, bind as parameter
final cutoffSeconds = DateTime.now().subtract(const Duration(days: 90)).millisecondsSinceEpoch ~/ 1000;
await customStatement('''
  DELETE FROM cached_submissions
  WHERE completed_at < ?
''', [cutoffSeconds]);
```

**Discovered in:** Pillar A GC's `_pruneStaleAudits`. The Hostile Interrogation (Red Team Gate) flagged the `/ 1000` math as a critical performance bug that would have hung low-RAM Android devices on boot.

---

## Gotcha: Test Isolation Leaks (`late AppDatabase db`)

**Problem:** In `flutter_test`, tests are run sequentially in the same process footprint. If a shared test variable is reassigned mid-test without disposing of the previous handle, that handle leaks into memory and corrupts the suite state.

```dart
test('AC1a — Reboot Simulation', () async {
  // WRONG ❌ — Re-assignment breaks the teardown cycle
  await db.close(); 
  db = AppDatabase.forTesting(NativeDatabase.memory()); 
});
```

**Fix:** Test components in absolute isolation. Do NOT simulate app reboots by reassigning the `db` instance inside a specific test case. If you need a fresh DB state, let the `setUp()` block handle it natively. If you need to test startup logic (`beforeOpen`), just manually call the initialization method (`db.pruneStaleAuditsForTesting()`) rather than fighting the test framework's memory sandbox.

---

## Gotcha: `MigrationStrategy.beforeOpen` — NOT `onOpen`

**Problem:** Drift's `MigrationStrategy` uses `beforeOpen` (not `onOpen`) for post-open hooks.

```dart
// WRONG ❌
MigrationStrategy(onOpen: (details) async { ... })

// CORRECT ✅
MigrationStrategy(beforeOpen: (details) async { ... })
```

**Note:** `customStatement` is available inside `beforeOpen` as a method on the `AppDatabase` instance (`this`). Do NOT try to access it through `details`.

**Note:** Do NOT wrap `customStatement` calls inside `beforeOpen` with a `transaction()` call — nested transactions in this context may cause issues.

---

## Gotcha: `@visibleForTesting` requires explicit `meta` import

`@visibleForTesting` from `package:meta/meta.dart` is **not re-exported** by the `drift` package. Always import explicitly:

```dart
import 'package:meta/meta.dart';
```

---

## Gotcha: Drift OOM Risk (Unbounded `.get()`)

**Problem:** Using `.get()` on a Drift query without applying `.limit(N)` instructs SQLite to load every matching record into memory simultaneously. In an offline-first app, tables like `pending_submissions` or `pending_photos` can silently accumulate thousands of records. When background sync runs, an unbounded `.get()` will immediately trigger an Out-Of-Memory (OOM) crash on lower-end mobile devices.

**Fix:** ALWAYS append a deterministic `.limit(N)` (e.g., 50 or 100) when fetching lists of entities meant for processing loops. Never assume a "pending" queue is small.

```dart
// WRONG ❌ — OOM Crash waiting to happen
Future<List<PendingSubmission>> getEligiblePending() async {
  return (_db.select(_db.pendingSubmissions)
        ..where((s) => s.syncStatus.equals('pending')))
      .get();
}

// CORRECT ✅ — Safe batch processing bounds
Future<List<PendingSubmission>> getEligiblePending() async {
  return (_db.select(_db.pendingSubmissions)
        ..where((s) => s.syncStatus.equals('pending'))
        ..limit(100)) // Bounded batch
      .get();
}
```

**Discovered in:** Pillar D Sync Engine. Verification identified `OutboxDao.getEligiblePending()` loading unbounded rows to evaluate exponential backoff.

---

## Gotcha: Drift Table vs. Domain Class Naming Collisions

**Problem:** If you have a domain data class named `PendingSubmissionRisk` (e.g., in `sync_interfaces.dart`), and you create a Drift table class named `PendingSubmissionRisks`, Drift will automatically generate a row data class also named `PendingSubmissionRisk`. When you import both files into a DAO or service, you will hit an `ambiguous_import` compiler error. Using `hide` everywhere becomes unmaintainable.

**Fix:** Avoid naming Drift outbox tables with the exact plural of the domain class. Instead, append `Entries` or `OutboxEntries` to the table class name.

```dart
// WRONG ❌ — Drift generates 'PendingSubmissionRisk' (collides with domain model)
class PendingSubmissionRisks extends Table { ... }

// CORRECT ✅ — Drift generates 'SubmissionRiskOutboxEntry' (no collision)
class SubmissionRiskOutboxEntries extends Table { ... }
```

**Discovered in:** Global Risks Epic (Slice 4.1). SyncEngine required importing both the Drift table and the SyncApi interface models.
