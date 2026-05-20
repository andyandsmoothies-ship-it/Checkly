# Global Audit Remediation Roadmap
**Date:** 2026-05-20
**Scope:** Identity, Core Execution, Organization, Observability, System Core, and Offline Sync Domains.

## Source Audit Reports
- [Identity Domain Audit](file:///C:/Users/HP/Documents/GitHub/Checkly/docs/diagnostics/identity_domain/audit_infra_report_20260520_183700_7b54018a_identity_domain.md)
- [Core Execution Code Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_code_report_core_execution_20260520.md)
- [Core Execution Infra Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_infra_report_core_execution_20260520.md)
- [Organization Domain Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_code_report_org_domain_20260520.md)
- [Observability Domain Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_infra_report_observability_domain_20260520.md)
- [System Core Code Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_code_report_20260520_204118_7b54018a_system_core.md)
- [Offline Sync Architecture Audit](file:///C:/Users/HP/.gemini/antigravity/brain/7b54018a-5c3f-4e55-8ce0-077f39f29b02/audit_arch_report_20260520_204908_7b54018a_offline_sync_arch.md)

*(Note: Artifacts in `.gemini/antigravity/brain` should ideally be moved to `docs/diagnostics` as they are addressed, but the links above reflect their current persistent locations for the builder agent.)*

---

## Phase 1: Immediate Security Patches (Drop Everything)
*These vulnerabilities expose data or allow privilege escalation. They are mostly 1-line fixes that must be applied immediately.*

1. **SA-1 (Fatal):** Fix IDOR in `CreateSubmission.cs` (Add caller ownership check to the idempotency key lookup).  
   *Source: [Offline Sync Architecture Audit]*
2. **CRIT-01 (Fatal):** Fix Role Injection in `Register.cs` (Block users from passing `admin` or `store_manager` as their role during open registration).  
   *Source: [Identity Domain Audit]*
3. **OBS-5 (Warning):** Add `.RequireCapability()` guard to the `GetMyStats` analytics endpoint to prevent data leakage across roles.  
   *Source: [Observability Domain Audit]*

## Phase 2: Critical Functional & Infrastructure Resilience 
*These issues cause silent data loss, permanent offline states, or server meltdowns.*

4. **SA-5 & SC-2 (Brittle/Warning):** Fix the `OutboxBackgroundService` by adding the `IsFatalMessageError` Polly predicate to prevent retry storms, and add an `else` block to log unhandled message types to prevent silent data loss.  
   *Source: [Offline Sync Architecture Audit], [System Core Code Audit]*
5. **OBS-1 (Critical):** Implement the missing `POST /notifications/read-all` server endpoint (or rewrite the Flutter client to loop `/{id}/read`) so notifications actually mark as read on the backend.  
   *Source: [Observability Domain Audit]*
6. **OBS-2 (Critical):** Update `GetAnalytics.cs` to actually read and apply the `startDate`/`endDate` parameters so the analytics dashboard isn't silently showing all-time data.  
   *Source: [Observability Domain Audit]*
7. **SA-2 (Brittle):** Add the stream health guard (`onError`/`onDone` with fallback polling) to `SyncEngine.dart` so Android battery optimization doesn't permanently brick offline sync.  
   *Source: [Offline Sync Architecture Audit]*
8. **SA-4 (Brittle):** Add the pre-sync jitter (`Future.delayed`) to `requestSync()` to prevent the thundering herd database exhaustion when 50 devices reconnect to WiFi simultaneously.  
   *Source: [Offline Sync Architecture Audit]*
9. **SA-3 (Brittle):** Fix the sync cursor fallback logic to use a server-provided timestamp rather than the device's local clock to prevent split-brain cursor corruption on devices with drifted clocks.  
   *Source: [Offline Sync Architecture Audit]*

## Phase 3: Performance & Missing Features (Pre-Scale)
*Fix these before the organization grows beyond a few stores to prevent UX degradation and DB locks.*

10. **OBS-3 (Warning):** Refactor the N+1 query loop in `ProvinceBenchmarkCalculator.cs` (currently executing 3 DB roundtrips *per province*).  
   *Source: [Observability Domain Audit]*
11. **OBS-4 (Warning):** Add a PostgreSQL expression index for `stores.address2.province` to prevent full table scans on analytics queries.  
   *Source: [Observability Domain Audit]*
12. **OBS-6 (Warning):** Add `.Where(s => s.IsActive)` to province analytics queries so deactivated stores stop skewing benchmark scores.  
   *Source: [Observability Domain Audit]*
13. **CRIT-02/03:** Implement the missing client-side FCM token registrations and `UpdateGroupMembers` logic.  
   *Source: [Identity Domain Audit]*

## Phase 4: Code Hygiene, Architecture, & Refactoring
*Housekeeping to keep the codebase under complexity thresholds.*

14. **Magic Strings Migration:** Replace raw string literals (submission statuses, program statuses, roles) with centralized `AppRoles` and status constant enums across the Submissions and Programs domains.  
   *Source: [Organization Domain Audit], [Core Execution Code Audit]*
15. **SC-1 (Warning):** Delete the dead `SendScheduleReminders` method from `ReminderService.cs`.  
   *Source: [System Core Code Audit]*
16. **Shared Extractors:** Extract shared validators (`PathValidator`, `StoreAddressValidator`).  
   *Source: [Core Execution Code Audit], [Organization Domain Audit]*
17. **File Decompositions (The 400-Line Rule):** 
    * Split `ScoringVerifier.cs` (SC-5).  
      *Source: [System Core Code Audit]*
    * Split `app_router.dart` (SC-3) and `main_shell.dart` (SC-4).  
      *Source: [System Core Code Audit]*
    * Decompose the large Wizard widgets and `ProgramDashboardPage`.  
      *Source: [Core Execution Code Audit], [Organization Domain Audit]*
18. **ATDD Coverage:** Raise ATDD stubs for untested handlers identified in the Core/Org domains (`CreateStore`, `AddComment`, etc.).  
   *Source: [Core Execution Code Audit], [Organization Domain Audit]*

## Phase 5: Backlog Optimizations
*Low-risk improvements to be done when time permits.*

19. ✅ **SA-6:** Optimize `syncableCount()` in `outbox_dao.dart` from 3 loops to 1 `IN` query. *(Done)*  
   *Source: [Offline Sync Architecture Audit]*
20. ✅ **OBS-7:** Add structured logging to `MarkRead.cs`. *(Done)*  
   *Source: [Observability Domain Audit]*
21. ✅ **OBS-8:** Refactor the Drift 1000-row offline analytics load path to use SQL `WHERE` filters instead of Dart-side memory filtering. *(Done)*  
   *Source: [Observability Domain Audit]*
22. ✅ **SC-7 / SC-8:** Add barrel exports for `lib/_shared/services/` (`services.dart`), and fix the duplicate heading in `GEMINI.md`. *(Done)*  
    ⚠️ **SC-6** (`tables.dart` split): Deferred — requires `build_runner` code regeneration. Low priority.  
   *Source: [System Core Code Audit]*
