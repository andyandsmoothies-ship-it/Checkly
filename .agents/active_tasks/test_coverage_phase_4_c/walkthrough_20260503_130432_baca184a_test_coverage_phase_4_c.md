## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260503_125300_baca184a_test_coverage_phase_4.md`

## Summary
I have implemented the test coverage backfill for Phase C: `AuditManagerSubmit` and `AuditManagerDraft` (Steps 11 and 12 of the consolidated plan).

### Tests Written
#### AuditManagerSubmit
- **TC-11-01**: Verified `submitAudit` uses an internal mutex flag (`_isSubmitting`) to silently drop rapid concurrent button presses.
- **TC-11-02**: Verified submitting with an empty set of answers sets the user-friendly `error` property and halts execution.
- **TC-11-03**: Verified submitting atomicity (inserting to outbox while simultaneously purging the local Draft file).
- **TC-11-04**: Verified the UX telemetry flag `wasQueuedOffline` is cleanly toggled when the ConnectivityService indicates no network.
- **TC-11-05**: Verified internal database exceptions are gracefully caught and exposed via the `error` property to prevent crash-to-desktop scenarios.

#### AuditManagerDraft
- **TC-12-01**: Verified modifying answers triggers a request to `DraftService.scheduleSave` to debounce SQLite commits.
- **TC-12-02**: Verified restoring drafts successfully maps the nested `DraftData` JSON into `AuditAnswer` entities in memory.
- **TC-12-03**: Verified that corrupted draft schemas (e.g., missing required fields) are silently swallowed without halting the app or breaking the primary audit flow.
- **TC-12-04**: Verified the explicit `discardDraft` function forces `DraftService` cleanup routines.
- **TC-12-05**: Verified `forceSave` overrides the timer and synchronously flushes state to disk.

### Execution Command
The Builder can run these tests via:
```bash
rtk flutter test test/features/audit/manager/audit_manager_submit_test.dart test/features/audit/manager/audit_manager_draft_test.dart
```

## Decision Log
- Decided to structure the `scoringLogicConfig` as valid JSON `{"scoringMode":"penalty"}` in the test fixture to prevent `FormatException` console spam inside `ScoringInputMapper`.
- Used `fake_async` implicitly by running normal asynchronous Dart closures, as time passage (debounce) is handled synchronously by `flushSave` in TC-12-05, and `scheduleSave` is cleanly mocked without timer waiting.

## Verification Handoff
Tests have been executed and passed. All metrics and criteria have been formally mocked, avoiding real SQLite initialization overhead but preserving complex logical branches.

<forensic_evidence>
<test_trace>
```text
C:\Users\HP\Documents\GitHub\Checkly> rtk flutter test test/features/audit/manager/audit_manager_submit_test.dart test/features/audit/manager/audit_manager_draft_test.dart
00:00 +10: All tests passed!
```
</test_trace>
</forensic_evidence>
