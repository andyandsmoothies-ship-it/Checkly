---
ConversationID: e806043a-d178-457b-b974-d1e2c68fce54
---

# Walkthrough: Smart Audit Safeguards - Slice 3A (HUD Debouncing)

This document contains a structured walkthrough of the successfully completed **Slice 3A (HUD Debouncing)** of the Smart Audit Source Safeguards epic.

---

## 1. Architectural Architecture Design

Before implementing, we analyzed the state machine and the timing requirements:

```
[Auditor Mutates Input]
          │
          ├──► Update local answer immediately inside _answers
          ├──► Call notifyListeners() (Snappy UI toggle)
          ├──► Cancel pending Timer (_scoreDebounceTimer)
          └──► Start new Timer (200ms)
                     │
            (Inactivity for 200ms)
                     │
                     ▼
           Execute _recalculateScore()
           Call notifyListeners() (HUD updates smoothly)
```

### Critical Concurrency Protection
To prevent a checkout race condition (where the auditor edits an answer and hits submit immediately under 200ms, submitting stale score telemetry), the submission pipeline synchronously flushes the debounce logic:
- Synchronously cancels the active timer.
- Forces an immediate, synchronous `_recalculateScore()` call.

---

## 2. Implementation Summary

We modified the following files to implement the architecture:

### 1. `lib/features/audit/manager/audit_manager.dart`
- Added private variable `Timer? _scoreDebounceTimer`.
- Implemented `void _recalculateScoreDebounced()` to reset/re-initialize the 200ms debounce timer.
- Refactored `setAnswer()`, `clearAnswerValue()`, `setCcp()`, and `setRisk()` to use `_recalculateScoreDebounced()`.
- Refactored `submitAudit()` to cancel the debounce timer and execute `_recalculateScore()` synchronously.
- Overrode the `dispose()` method of the `AuditManager` to clean up and cancel the timer.
- Refactored `startAudit()` initialization to compute score calculation synchronously at the beginning of the lifecycle, preventing race conditions with test event loops during asynchronous SQLite draft loading.

---

## 3. Automated Test Verification Results

To verify the implementation under strict timing constraints, we authored a dedicated unit test suite:

### Test File: `test/features/audit/audit_manager_debounce_test.dart`
- **TC-DEBOUNCE-01**: Verifies rapid answer updates are debounced by 200ms.
- **TC-DEBOUNCE-02**: Verifies submit cancels the debounce timer and triggers immediate synchronous calculation.

### Test Execution Commands & Results
All tests passed with zero stutters or leaks:

```powershell
rtk flutter test ../test/features/audit/audit_manager_debounce_test.dart
```

```
00:00 +0: loading C:/Users/HP/Documents/GitHub/Checkly/test/features/audit/audit_manager_debounce_test.dart
00:00 +0: (setUpAll)
00:00 +0: AuditManager Compliance Score Calculation Debounce Tests TC-DEBOUNCE-01: Rapid answer updates debounce score recalculation by 200ms
00:00 +1: AuditManager Compliance Score Calculation Debounce Tests TC-DEBOUNCE-02: Submit cancels debounce timer and triggers immediate calculation
00:00 +2: (tearDownAll)
00:00 +2: All tests passed!
```

---

## 4. Full Audit Regression Verification

We ran a comprehensive verification across all existing audit manager test suites to ensure zero regression across draft saving, submission pipelines, scoring modes, and offline queues:

```powershell
rtk flutter test ../test/features/audit/audit_manager_online_path_test.dart ../test/features/audit/audit_manager_test.dart ../test/features/audit/manager/audit_manager_draft_test.dart ../test/features/audit/manager/audit_manager_submit_test.dart ../test/features/audit/audit_manager_scoring_mode_test.dart ../test/features/audit/audit_manager_offline_test.dart ../test/features/audit/audit_manager_debounce_test.dart
```

```
All tests passed!
Exit code: 0
```

---

## 5. Handoff to Slice 3B

Slice 3A is completely verified, green-lit, and fully integrated with existing tests. We are ready to hand off or proceed with **Slice 3B (Offline Geofencing)** of the implementation plan!
