# Diagnostic Report: PBAC UI Prevention Leak
Workflow: /diagnose

## Input Lineage
- **Source Input**: User report indicating users without capability can still see the "Start Audit" button, create a submission, and fail at sync.

## Root Cause
The root cause is a **UI Gating Leak** and a **Router Gating Leak**:
1. **`template_detail_page.dart`**: The "START AUDIT" button located in the `bottomNavigationBar` is not wrapped in a `PolicyManager.can(AppCapabilities.submissionsCreate)` check. It is completely exposed to all authenticated users who can view templates.
2. **`app_router.dart`**: The routes `/stores/select` and `/audit` (which launch the actual audit flow) lack a `redirect` guard for `AppCapabilities.submissionsCreate`. Therefore, even if the button were hidden, a user could theoretically navigate to the URL manually or via deep-link.

Because the UI allows them to start, the local database records the draft. When the background Sync Engine tries to push it to the C# API, the C# API correctly blocks it (returning HTTP 403 Forbidden because PBAC is enforced on the backend). The app then accurately reports it as "unsynced". 

## Explicit Code Trace (Premises + Proof)
<forensic_evidence>
Searched `template_detail_page.dart` lines 30-50, finding `ElevatedButton.icon(label: const Text('START AUDIT'))` inside the `bottomNavigationBar` block without any conditional check.
Searched `app_router.dart` lines 113-127, finding routes `/stores/select` and `/audit` lacking a `redirect:` guard.
</forensic_evidence>
1. **Premise**: User lacks `submissions:create`.
2. **Path**: User taps the `+` menu on the Dashboard → "Start New Audit" is correctly hidden. 
3. **Leak Path**: User taps on the "Templates" tab → Taps a Template card → Arrives at `template_detail_page.dart`.
4. **Execution**: The `bottomNavigationBar` statically renders `ElevatedButton.icon(label: 'START AUDIT')` without checking the PolicyManager.
5. **Execution**: User taps it and proceeds to `/stores/select` → No route guard in `app_router.dart` → User starts audit at `/audit` → No route guard.

## Proposed Scope-Limited Fix
1. **`template_detail_page.dart`**: Import `PolicyManager` and `AppCapabilities`. Use `final canCreate = _di<PolicyManager>().can(AppCapabilities.submissionsCreate);` to conditionally render the bottom navigation bar.
2. **`app_router.dart`**: Add a `redirect:` guard to `/stores/select` and `/audit` routing blocks to return the user to `/home` if they lack `submissions:create`.

### Trade-offs / Pros & Cons
- **Pros**: Completely plugs the visual and functional holes. Users without the capability won't waste time filling out forms that will ultimately be rejected by the backend.
- **Cons**: Requires restarting the Flutter app locally to test the new Router configuration.

## Handoff Block

**Verdict:** The Flutter UI and Router are missing PBAC capability checks for `submissions:create` on the Template Detail page and the Audit execution routes.
**Blast Radius:** Frontend Only (`lib/_shared/router/app_router.dart`, `lib/features/templates/pages/template_detail_page.dart`).

### AI Agent Mission Brief
Fix the PBAC UI Gating leak by hiding the "START AUDIT" button on `TemplateDetailPage` when the user lacks `submissions:create`. Additionally, apply router redirect guards to `/stores/select` and `/audit` in `app_router.dart` for the same capability.

### Execution Queue
- [ ] @[/implement] docs/diagnostics/failure_report_20260510_110637_diag_pbac-ui-prevention.md
