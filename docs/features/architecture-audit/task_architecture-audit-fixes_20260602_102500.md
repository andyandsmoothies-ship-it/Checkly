---
conversationId: "eff00973-14e1-4499-8eb8-460c7cb83703"
---

# Task: Architecture Audit Fixes

## Input Lineage
- **Source Report**: `docs/reports/diagnostics/audit_arch_report_20260602_095500.md`
- **Target Files**:
  - `lib/_shared/services/sync_engine.dart`
  - `lib/_shared/services/photo_queue_service.dart`
  - `server/Common/Persistence/DistributedLockManager.cs`

## Steps
- [x] Slice 1: Wrap `sync_engine.dart` module iterations in `try-catch` blocks and verify with existing tests.
- [x] Slice 2: Implement `_activeUploads` concurrency check in `photo_queue_service.dart` and add new unit tests.
- [x] Slice 3: Update `DistributedLockManager.cs` to enforce a strict timeout cancellation token and verify.

## Artifact Inventory
| Status | File Path | Type |
| ------ | --------- | ---- |
| [NEW]  | docs/features/architecture-audit/task_architecture-audit-fixes_20260602_102500.md | Task |
| [EDIT] | lib/_shared/services/sync_engine.dart | Implementation |
| [EDIT] | lib/_shared/services/photo_queue_service.dart | Implementation |
| [EDIT] | test/_shared/services/photo_queue_service_test.dart | Tests |
| [EDIT] | server/Common/Persistence/DistributedLockManager.cs | Implementation |
| [EDIT] | server/tests/Checkly.Api.Tests/Features/Notifications/DistributedLockManagerTests.cs | Tests |
