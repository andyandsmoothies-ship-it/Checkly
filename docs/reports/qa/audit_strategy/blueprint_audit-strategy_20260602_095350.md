---
ConversationID: dcbfac81-a3e9-4fad-af42-bc281b403b75
---

# Blueprint: Checkly Global Audit Strategy

This document serves as the master reference guide for running automated and manual quality audits across the Checkly codebase using the `@[/audit-arch]`, `@[/audit-infra]`, and `@[/audit-code]` workflows.

---

## 1. The Audit Sequencing Rule

Always execute audits from the **macro system architecture** down to **micro code files**. This prevents wasting time on formatting or naming conventions for code blocks that will be deleted due to design issues.

```text
       [1. SYSTEM LEVEL: /audit-arch]  <-- Core System Rules (Check First!)
                     │
                     ▼
    [2. STRUCTURAL LEVEL: /audit-infra] <-- Database & Security (Check Second!)
                     │
                     ▼
       [3. LINE-BY-LINE: /audit-code]   <-- Formatting & Code Slop (Check Last!)
```

---

## 2. Directory & Module Mapping

Use this guide to route folders to their appropriate workflow.

### A. Architecture Auditing (`@[/audit-arch]`)
*Target: Concurrency, state machines, offline capabilities, background tasks, lock integrity.*

* **Flutter Shared Services (`lib/_shared/services/`)**:
  * `sync_engine.dart` — Audits the offline-first delta pull/push state machine.
  * `photo_queue_service.dart` — Audits the exponential backoff network engine.
  * `scoring_engine.dart` — Audits the checklist and section scoring calculation logic.
* **Backend Features (`server/Features/`)**:
  * `Sync/` — Audits the backend endpoints that ingest and resolve drift tables.
  * `Submissions/` — Audits the advisory locking and calculations engine (`SectionScoreExploder.cs`).
* **Common Persistence (`server/Common/Persistence/`)**:
  * `DistributedLockManager.cs` — Audits backend database transaction safety.

### B. Database & API Auditing (`@[/audit-infra]`)
*Target: Database configurations, indexes, unbounded OOM queries, authentication guards, data leakage, and mutation logs.*

* **Backend Persistence (`server/Common/Persistence/`)**:
  * `AppDbContext.cs` and `Configurations/` — Audits schema configurations and indexes.
* **API Endpoints (`server/Features/`)**:
  * `Admin/`, `Users/`, `Stores/` — Audits role authentication guards and logs on mutation endpoints (`POST/PUT/DELETE`).
* **Schema parities**:
  * Drift local DB (`lib/_shared/database/app_database.dart`) vs Postgres backend (`server/Common/Persistence/AppDbContext.cs`).

### C. Clean Code & AI Slop Auditing (`@[/audit-code]`)
*Target: File/method sizing, circular dependencies, Single Responsibility Principle (SRP), exposed secrets, and unused code.*

* **Flutter UI Pages & Widgets (`lib/features/`)**:
  * `profile/`, `analytics/`, `dashboard/`, `action_plans/` — Audits screens to prevent them from exceeding 400 lines or containing more than 3 classes.
* **Shared UI Utilities (`lib/_shared/widgets/`)**:
  * `primitives/` (like `stroke_card.dart`, `bubbly_button.dart`) — Enforces token-driven theme compliance.
* **Backend Cleanliness**:
  * Sweeps for stale `TODO`/`FIXME` comments and dead code.

---

## 3. Recommended Audit Schedule (Batches)

For maximum efficiency, split audits into three distinct phases:

### Batch 1: The Offline & Concurrency Core (Run First)
* **Goal**: Find critical 2:00 AM PagerDuty bugs in state and sync logic.
* **Target Files**:
  * `lib/_shared/services/sync_engine.dart`
  * `lib/_shared/services/photo_queue_service.dart`
  * `server/Features/Sync/`
* **Command**: `@[/audit-arch]`

### Batch 2: Database Bottlenecks & Security guards (Run Second)
* **Goal**: Prevent Postgres performance degradation and data leakage risks.
* **Target Files**:
  * `server/Common/Persistence/AppDbContext.cs`
  * `server/Features/ActionPlans/`
  * `server/Features/Submissions/`
* **Command**: `@[/audit-infra]`

### Batch 3: UI Cleanliness & Refactoring (Run Last)
* **Goal**: Simplify giant classes, prune dead imports, and enforce custom theme primitives.
* **Target Files**:
  * `lib/features/analytics/`
  * `lib/features/profile/`
  * `lib/_shared/widgets/primitives/`
* **Command**: `@[/audit-code]`
