<latent_space_scratchpad>
Audit scope is the current workspace state on April 25, 2026, with emphasis on the newly added notification/device-token slice plus repo-wide hygiene. The highest-risk changes are the backend finalize flow and the new mobile inbox/local notification path because both introduce cross-boundary behavior but only partial wiring is visible. The scan also needs to separate true source issues from generated artifacts, since this worktree currently contains a large amount of build output and runtime data that can mask real review signal.
</latent_space_scratchpad>

# Audit Code Report

Date: 2026-04-25
Persona: Sentinel
Workflow: /audit-code
Active Skills: `de-sloppify`, `verification-loop`

## Rules Compliance
- QA persona respected: read-only audit, no production code changes.
- Governance references reviewed: `.agents/persona/qa_persona.md`, `.agents/workflows/audit-code.md`, `.agents/rules/orchestration-standards.md`, `server/Common/GEMINI.override.md`, `server/Features/ActionPlans/GEMINI.override.md`, `server/Features/Submissions/GEMINI.override.md`.

## Scope
- Targeted scan of current modified/untracked workspace state.
- Focused review on newly introduced FCM/device-token and inbox notification changes.
- Hygiene scan for secrets, stale markers, oversized files, generated artifact drift, and coverage gaps.

## Severity Matrix

### 🔴 Critical

1. Finalize path emits notifications even when the transaction returns a non-success result.
   - Evidence: [server/Features/Submissions/FinalizeSubmission.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:233) returns `Conflict(...)` from inside the execution strategy, but the post-transaction notification block runs unconditionally at [line 282](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:282) through [line 303](C:\Users\HP\Documents\GitHub\Checkly\server\Features\Submissions\FinalizeSubmission.cs:303).
   - Risk: false `audit_submitted` notifications and FCM pushes can be sent for requests that did not actually finalize successfully, especially concurrency-conflict paths.
   - Exact fix path: gate the notification block on a proven success result, or move notification creation into the success branch after commit using an explicit success flag / typed result inspection.
   - Trade-offs:
     - Gate after `result is Ok<SubmissionDto>`: smallest patch, but depends on result-shape knowledge.
     - Move notification creation into the transaction success branch: clearer flow ownership, but expands transaction scope and mixes external side effects with persistence.
   - Coverage gap: current tests only cover happy-path insertion and missing store manager behavior, not conflict/failure suppression. See [server/tests/Checkly.Api.Tests/Features/Submissions/FinalizeNotificationTests.cs](C:\Users\HP\Documents\GitHub\Checkly\server\tests\Checkly.Api.Tests\Features\Submissions\FinalizeNotificationTests.cs:17).

### 🟡 Warning

2. `NotificationSyncManager` is registered but never initialized or triggered in app runtime.
   - Evidence: service registration exists at [lib/locator.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\locator.dart:140), but the only runtime startup work in [lib/main.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\main.dart:12) initializes theme/auth only. Search results show no production call sites for `NotificationSyncManager.init()` or `onTickle()`.
   - Risk: the new local-notification sync layer is effectively dead code in production; tests exercise it, but the app never starts it.
   - Exact fix path: initialize it during startup or app lifecycle boot, and wire `onTickle()` to the real push/socket/background event source.
   - Trade-offs:
     - Initialize in `main()`: simple and predictable, but adds startup work every cold boot.
     - Initialize lazily when auth/session is ready: avoids unnecessary setup for signed-out users, but requires a clear session lifecycle hook.

3. Git hygiene rules are incomplete for generated outputs and runtime data.
   - Evidence: `.gitignore` covers only `server/bin/`, `server/obj/`, and top-level `.agents/tmp/` at [lines 48-56](C:\Users\HP\Documents\GitHub\Checkly\.gitignore:48), but current status still shows tracked child-project artifacts under `server/tests/Checkly.Api.Tests/bin`, `server/tests/Checkly.Api.Tests/obj`, untracked `server/.agents/tmp/debug.txt`, untracked `server/data/photos/...`, plus root `test_results.json`.
   - Risk: review noise, accidental commits of test/build output, and runtime file growth inside the repo.
   - Exact fix path: extend ignore rules to recursive `**/bin/`, `**/obj/`, `**/TestResults/`, `server/data/photos/`, `**/.agents/tmp/`, and machine output files like `test_results.json`.
   - Trade-offs:
     - Broad recursive ignores: best long-term hygiene, but requires care if any generated artifact is intentionally versioned.
     - Narrow per-path ignores: less risk of over-ignoring, but easier to regress as new projects/subfolders are added.

4. Large UI and persistence files are past the workflow warning threshold and are getting harder to audit safely.
   - Evidence:
     - [lib/features/admin/pages/audit_approval_page.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\audit_approval_page.dart:1) is 682 lines.
     - [lib/features/admin/pages/store_management_page.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\features\admin\pages\store_management_page.dart:1) is 668 lines.
     - [lib/features/audit/pages/history_page.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\features\audit\pages\history_page.dart:1) is 630 lines.
     - [lib/features/audit/pages/audit_form_page.dart](C:\Users\HP\Documents\GitHub\Checkly\lib\features\audit\pages\audit_form_page.dart:1) is 617 lines.
     - [server/Common/Persistence/AppDbContext.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Common\Persistence\AppDbContext.cs:1) is 640 lines.
   - Risk: lower reviewability and higher regression probability for unrelated edits.
   - Exact fix path: split each page into view sections/widgets; extract `AppDbContext` entity configuration into per-entity configuration classes or partial methods.
   - Trade-offs:
     - Extraction improves maintainability and testability, but increases file count and navigation surface.
     - Keeping monolith files preserves locality, but further edits will continue compounding audit cost.

### 🟢 Optimization

5. `FcmDispatchService` contains test-only fallback behavior in production code.
   - Evidence: when Firebase is unavailable, [server/Common/Services/FcmDispatchService.cs](C:\Users\HP\Documents\GitHub\Checkly\server\Common\Services\FcmDispatchService.cs:51) removes only the literal token `"invalid-token-123"` before returning.
   - Risk: production path is carrying a hardcoded test shim that does not represent real runtime behavior.
   - Exact fix path: move this expectation into tests by mocking the Firebase boundary, or expose a seam that lets tests simulate `MessagingErrorCode.Unregistered`.
   - Trade-offs:
     - Mocking the boundary keeps production clean, but requires slightly more test setup.
     - Leaving the shim keeps tests simple, but couples behavior to a fake token string and hides real failure modes.

## Scan Summary
- Dead code found: Yes, behaviorally dead notification sync path.
- Architectural drift detected: Yes, production service contains test fallback logic; repo also accumulates runtime artifacts inside source control boundaries.
- Secrets leaked: No production secret leak found in source scan. Matches were documentation/test-output related.
- Docs updated: Partial. Router comments were updated for the inbox tab, but repo hygiene/docs do not reflect the new runtime artifact locations.

## Structural Health
- Files breaking `>500` threshold: 5 production files flagged above.
- Files breaking `>1000` threshold: no production source files flagged; only generated/test artifacts and SQL dumps exceeded that size.
- Class density scan: no production file surfaced as a high-class-density hotspot above the workflow threshold from the sampled scan.
- Method-size note: no single audited method was measured above 150 lines in the sampled hotspots, but `FinalizeSubmission.HandleAsync` remains large enough that post-commit side effects are now hard to reason about safely.

## Coverage & Hygiene
- Coverage gaps:
  - No test proving notification suppression on finalize failure/conflict.
  - No production wiring test proving `NotificationSyncManager` is initialized from startup/session lifecycle.
- Dependencies:
  - New dependency observed: `FirebaseAdmin` in [server/Checkly.Api.csproj](C:\Users\HP\Documents\GitHub\Checkly\server\Checkly.Api.csproj:11).
  - New Flutter dependency observed: `flutter_local_notifications` in [pubspec.yaml](C:\Users\HP\Documents\GitHub\Checkly\pubspec.yaml:49).
  - Nothing clearly stale from a static audit, but these additions now require actual wiring and operational docs.
- Stale markers:
  - No actionable TODO/FIXME/HACK markers found in active source folders; hits were mostly workflow/template material and test output.
- Duplication:
  - Inbox tile code explicitly notes WET duplication from `notification_drawer_page.dart`; worth consolidating once the new inbox flow is stable.

## Actionable Fixes
1. Guard `FinalizeSubmission` notification side effects behind a confirmed success path and add a failing regression test for conflict/no-notify.
2. Wire `NotificationSyncManager` into app startup/session bootstrap and connect `onTickle()` to the real notification event source.
3. Expand `.gitignore` to recursive build/test/runtime output rules and clean the worktree noise.
4. Split the oversized UI pages and `AppDbContext` configuration surface into smaller ownership units.
5. Remove the `"invalid-token-123"` fallback from production FCM dispatch code and replace it with a test seam.

## Strict Implementation Constraints & Human Reminders
- Sentinel audited only. Production code remains untouched.
- Preserve existing user changes in the dirty worktree; cleanup must avoid reverting unrelated modifications.
- Builder should execute fixes one slice at a time because the current workspace spans Flutter + ASP.NET + test assets.
- Backend changes in finalize/notification flows should be followed by hostile testing around concurrency and delegated-finalization cases.

## Handoff Block
- Primary report path: `C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_qa_audit_code\audit_code_report_20260425_qa_audit_code.md`
- Failure report path: `C:\Users\HP\Documents\GitHub\Checkly\brain\20260425_qa_audit_code\failure_report_finalize_notification_20260425_qa_audit_code.md`
- Routing: Pass audit report to Builder agent (@Forge) for /implement (Track B).

<forensic_evidence>
grep_search equivalents executed via `rg` and targeted `Get-Content` reads:
- git status --short
- Get-Content .agents/persona/qa_persona.md
- Get-Content .agents/workflows/audit-code.md
- Get-Content .agents/rules/orchestration-standards.md
- rg --files .agents | rg "audit|dead_code|verify_workflow|task_"
- Get-Content server/Common/GEMINI.override.md
- Get-Content server/Features/ActionPlans/GEMINI.override.md
- Get-Content server/Features/Submissions/GEMINI.override.md
- rg -n --hidden --glob '!**/bin/**' --glob '!**/obj/**' --glob '!**/.git/**' "sk_live|Bearer\\s+[A-Za-z0-9\\-\\._]+|password=|\\.env" .
- rg -n --hidden --glob '!**/bin/**' --glob '!**/obj/**' --glob '!**/.git/**' "TODO|FIXME|HACK|XXX" lib server test .agents
- line-count scan across lib/server/test excluding generated paths
- git diff --stat
- git diff -- server/Checkly.Api.csproj server/Program.cs server/Common/Services/FcmDispatchService.cs server/Common/Persistence/Entities/UserDeviceToken.cs server/Common/Persistence/AppDbContext.cs server/Features/Users server/Features/Submissions/FinalizeSubmission.cs server/Features/ActionPlans/AddComment.cs
- Get-Content server/Common/Services/FcmDispatchService.cs
- Get-Content server/Features/Submissions/FinalizeSubmission.cs
- Get-Content server/Features/Users/RegisterDeviceToken.cs
- Get-Content server/tests/Checkly.Api.Tests/Features/Submissions/FinalizeNotificationTests.cs
- rg -n "onTickle\\(|NotificationSyncManager|init\\(" lib test
- Get-Content lib/features/notifications/manager/notification_sync_manager.dart
- Get-Content lib/main.dart
- Get-Content lib/locator.dart
- Get-Content .gitignore
</forensic_evidence>
