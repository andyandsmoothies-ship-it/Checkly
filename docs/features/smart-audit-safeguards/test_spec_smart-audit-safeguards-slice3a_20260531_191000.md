---
ConversationID: 7e84733f-638e-4569-87dd-9901b796b109
---

# Test Specification: Smart Audit Safeguards - Slice 3A (HUD Debouncing)

This document lists the test cases, expected assertions, and verification parameters for client-side HUD calculation debouncing inside the `AuditManager`.

## 1. Compliance Score Debouncing Tests

### Test Case Dart-01: Compliance Score Calculation Debounce
- **Method**: `TC-DEBOUNCE-01`
- **Verification**:
  - Updates answers immediately inside the answers map.
  - Does NOT trigger synchronous score recalculation stutters on mutations under 200ms.
  - The score remains unchanged during rapid updates.
  - After 200ms of inactivity, `_recalculateScore` executes exactly once and updates `liveScore` smoothly.

### Test Case Dart-02: Submit Concurrency Guard
- **Method**: `TC-DEBOUNCE-02`
- **Verification**:
  - Calling `submitAudit()` immediately cancels any active debounce timer.
  - Executes `_recalculateScore()` synchronously and instantly to guarantee the score is accurate at the exact moment of checkout.

---

## 2. Running Verification

To execute these tests, run:
```powershell
cmd /c flutter test test/features/audit/audit_manager_debounce_test.dart
```
