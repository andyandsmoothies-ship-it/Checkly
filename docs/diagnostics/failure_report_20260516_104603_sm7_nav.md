# Diagnostic Report: SM7 Action Plan Tab Missing
Workflow: /diagnose

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\lib\_shared\router\main_shell.dart`

## Root Cause
The `PLANS` tab in the bottom navigation bar is erroneously guarded by the `AppCapabilities.programsList` capability. 
Because Store Managers (like SM7) do not have the `programsList` capability (which is intended for managing Programs/Campaigns, not Action Plans), the tab is hidden from their UI. 
However, the `/plans` route itself correctly maps to the `ActionPlansPage` and is accessible without that capability constraint (which is why Store Managers can still access it by tapping the dashboard card).

## Explicit Code Trace (Premises + Proof)
1. **Symptom:** Store Managers cannot see the Action Plans bottom navigation tab.
2. **Proof 1 (`main_shell.dart:43-48`):** 
   ```dart
   _ShellTab(
     icon: Icons.fact_check,
     label: 'PLANS',
     route: '/plans',
     requiredCapability: AppCapabilities.programsList,
   ),
   ```
   The tab explicitly requires `AppCapabilities.programsList`.
3. **Proof 2 (`app_router.dart:76`):**
   ```dart
   GoRoute(
     path: '/plans',
     builder: (context, state) => ActionPlansPage(...),
   ),
   ```
   The `/plans` route belongs to the Action Plans domain, not Programs.
4. **Proof 3 (`app_router.dart:350-376`):**
   The `authRedirect` method has NO capability guard for the `/plans` prefix, proving that Action Plans are globally accessible to authenticated users (unlike `/programs`, which is correctly guarded).

## Proposed Scope-Limited Fix
- **File:** `lib/_shared/router/main_shell.dart`
- **Fix:** Remove the `requiredCapability: AppCapabilities.programsList` line from the `PLANS` `_ShellTab` definition. Alternatively, map it to a globally shared capability if preferred (e.g., leaving it `null` exposes it to everyone, which matches the routing logic).

**Trade-offs / Pros & Cons:**
- *Pros:* Instantly restores the tab for Store Managers, accurately reflecting the routing rules. Very low risk (1 line removal).
- *Cons:* If there are external users (like a super-restricted guest) who shouldn't see Action Plans, a `null` capability would expose the tab to them. However, since the route itself has no guard, it's already exposed logically, so this just aligns the UI with the Router.

<forensic_evidence>
- `grep_search` for bottom navigation definitions in `lib/`.
- `view_file` on `lib/_shared/router/main_shell.dart`.
- `view_file` on `lib/_shared/constants/app_capabilities.dart`.
- `view_file` on `lib/_shared/router/app_router.dart`.
</forensic_evidence>

## Handoff Block
1. **Final Verdict:** The missing tab is a bug caused by a PBAC capability mismatch on the `PLANS` navigation item.
2. **Fix & Blast Radius:** Remove `requiredCapability` on the `PLANS` tab. Blast radius is isolated solely to the visibility of the bottom nav item.
3. **AI Agent Mission Brief:** Remove `AppCapabilities.programsList` from the `PLANS` tab in `main_shell.dart` to make it globally visible, aligning it with the router configuration.

- [ ] `@[/implement] docs/diagnostics/failure_report_20260516_104603_sm7_nav.md`
