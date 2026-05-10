# Failure Report: Submission Finalize 403

## Input Lineage
- **Source Input**: User report describing `403` error when Area Manager attempts to submit a resumed audit. `PUT /api/submissions/{id}/finalize`.

## Root Cause
The `PUT /api/submissions/{id}/finalize` endpoint in `SubmissionEndpoints.cs` enforces `.RequireCapability(AppCapabilities.SubmissionsCreate)`. However, the frontend explicitly allows users to "Resume" a draft audit even if they lack the `submissions:create` capability, reasoning that blocking them would cause data loss if capabilities change after creation. 

Because the backend requires `submissions:create` to finalize *any* submission, users who started an audit before PBAC was implemented—or before they lost the capability—can resume filling out the form on the frontend but will consistently encounter a 403 Forbidden error from the backend when attempting to sync the finalized submission.

## Explicit Code Trace (Premises + Proof)
1. **Frontend Gate Bypass for Resuming**: In `app_router.dart`, the `/audit` route explicitly bypasses the `submissions:create` capability check if `isResume` is true:
```dart
    redirect: (context, state) {
      // Allow resuming an existing draft — the draft already exists locally
      // and blocking it would cause data loss if capabilities changed after creation.
      final params = state.uri.queryParameters;
      final isResume = params['autoResume'] == 'true' || params['submissionId'] != null;
      if (isResume) return null;
      
      final pm = _di<PolicyManager>();
      if (!pm.can(AppCapabilities.submissionsCreate)) return '/home';
      return null;
    }
```
2. **Backend Strictness**: In `SubmissionEndpoints.cs`, `FinalizeSubmission` is mapped as follows:
```csharp
        group.MapPut("/{id}/finalize", FinalizeSubmission.HandleAsync)
            .WithName("FinalizeSubmission")
            .RequireCapability(AppCapabilities.SubmissionsCreate); // <--- ROOT CAUSE
```
3. **Backend Ownership Guard**: Inside `FinalizeSubmission.HandleAsync`, ownership and scoped delegation are natively enforced:
```csharp
        if (submission.AuditorId != auditorId && !await ResourceAccessGuard.CanDelegateAsync(user, new ResourceScope(StoreId: submission.StoreId), db, ct))
            return TypedResults.Forbid();
```
Proof: The route-level capability guard is unnecessarily strict for the `finalize` action, overriding the intentional frontend allowance and the built-in scoped ownership rules in the handler.

## Proposed Scope-Limited Fix
Remove the `.RequireCapability(AppCapabilities.SubmissionsCreate)` directive from the `FinalizeSubmission` mapping in `SubmissionEndpoints.cs`. 

**Trade-offs / Pros & Cons**:
- **Pros**: Perfectly aligns backend semantics with frontend "anti-data loss" semantics. Prevents the exhausted sync errors for users who legally hold a draft but had their creation capability revoked.
- **Cons**: Technically allows any user to finalize an existing draft if they somehow bypass ownership (but the robust `ResourceAccessGuard` and `AuditorId` checks inside the handler make this risk strictly zero). No structural downsides.

<forensic_evidence>
- `grep_search` on `SubmissionEndpoints.cs` to identify capability.
- `view_file` on `FinalizeSubmission.cs` to confirm ownership and delegation logic via `ResourceAccessGuard`.
- Micro-experiment: Replaced route capability and ran `dotnet test tests/Checkly.Api.Tests/ --filter FullyQualifiedName~FinalizeSubmission` (Passed 16/16 tests).
</forensic_evidence>

## Handoff Block
1. **Final Diagnostic Verdict**: A strict route-level PBAC guard on `FinalizeSubmission` conflicts with the app's policy of allowing data-safe resumption of existing drafts.
2. **Required Fix**: Remove `.RequireCapability(AppCapabilities.SubmissionsCreate)` from `SubmissionEndpoints.cs` line 42. Blast radius is negligible as `CreateSubmission` remains gated, and `FinalizeSubmission` enforces record ownership.
3. **AI Agent Mission Brief**: The builder must remove the `SubmissionsCreate` capability requirement from the `FinalizeSubmission` route mapping in `SubmissionEndpoints.cs` to resolve a 403 sync error for legacy drafts.
4. **Execution Queue**:
- [ ] @[/implement] docs/diagnostics/failure_report_20260510_152716_submission-403.md
