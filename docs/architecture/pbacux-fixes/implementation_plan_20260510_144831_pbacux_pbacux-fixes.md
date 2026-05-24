# Task: PBAC UX Fixes
Workflow: /analyze-feature | Track: A

<latent_space_scratchpad>
- Need to fix three UX heuristic violations (H1, H2, H8).
- H1: Inline spinner on Admin Grid. We need to track `_mutatingCapability` in `RoleDetailPage` instead of a boolean `_isMutating`. Pass it to `OnlineCapabilityGrid`. If `mutatingCapability == cap`, show a trailing spinner.
- H2: Human-readable strings. Need a static `CapabilityDictionary` class in `_shared/constants/capability_dictionary.dart`. It should have `label`, `description`, and `group` fallback getters.
- H8: Group capabilities visually. In `ProfileCapabilitiesSection`, instead of a single Wrap, group by `CapabilityDictionary.getGroup(cap)`. Render headers with a smaller Wrap under each.
- No backend changes required.
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `c:\Users\HP\.gemini\antigravity\brain\182e4fa4-1644-4cf6-8974-b9aa24cf769d\ux_heuristic_eval_pbac.md`

## Executive Summary & Out of Scope
This plan addresses three UX heuristic violations on the PBAC capabilities UI. It introduces a static frontend dictionary to humanize technical strings, replaces a global loading spinner with an inline spinner for exact feedback, and groups the Profile page capabilities to reduce visual density.
**Out of Scope**: We will not modify the backend `/admin/capabilities/catalog` endpoint. If the backend doesn't send descriptions, the frontend dictionary will seamlessly act as the fallback.

## System Context
- **Offline/Online**: `RoleDetailPage` remains strictly online-only (ADR Option A).
- **APIs**: Unchanged.
- **RBAC**: Requires `admin:manage_roles` to mutate roles.

## Lifecycle Context
- **Loading**: `RoleDetailPage` will now show an inline spinner on the exact checkbox being toggled.
- **Empty**: Fallbacks gracefully to "No capabilities assigned/available."
- **Error**: Continues to show a SnackBar on mutation failure.
- **Success**: Capabilities display cleanly sorted and grouped in human language.

## Test Contracts
| ID | Exact Text | State Matrix | Why it fails first |
|---|---|---|---|
| UX-01 | Inline spinner replaces global spinner | Loading: Inline spinner active | The UI state only tracks a boolean `isMutating`, so it cannot pinpoint which capability to spin. |
| UX-02 | Dictionary provides fallback strings | Success: Human-readable label/desc | The grid currently falls back to the raw string if the backend meta is missing. |
| UX-03 | Profile capabilities are grouped | Success: Domain headers exist | Profile currently uses a flat `Wrap` for all capabilities. |

## Test Fixture & Payloads
- Requires a seeded Admin user.
- No new payloads needed.

## Tools & Commands
- **Testing**: `rtk flutter test`
- **Formatting**: `rtk dart format .`
- **Linting**: `rtk flutter analyze`

## Proposed Changes
- `[NEW]` `lib/_shared/constants/capability_dictionary.dart`
- `[MOD]` `lib/features/admin/pages/role_detail_page.dart`
- `[MOD]` `lib/features/admin/widgets/online_capability_grid.dart`
- `[MOD]` `lib/features/profile/widgets/profile_capabilities_section.dart`

## Concept Diagram
```text
[Dictionary] --> (Provides labels/groups/descriptions)
                      |
[Profile Section] <---|---> [Admin Grid]
(Groups by Domain)          (Shows Inline Spinner)
```

## Risk Assessment
- **Risk Level**: Low.
- **Architectural Cost**: Negligible. The changes are strictly localized to the UI presentation layer and rely on a simple `Map` dictionary for lookups. No database, backend, or fundamental logic is changed. 

## Verification Plan
- **Pre-Flight**: Run `rtk flutter analyze` and `rtk dart format .` to ensure zero static analysis warnings.
- **Visual Check**: Run the Flutter app locally.
- **Check 1**: Navigate to Profile page, ensure capabilities are grouped correctly and use human-readable strings (e.g. "Create Submissions").
- **Check 2**: Navigate to Admin -> Role Management -> Select a role. Verify capabilities have plain English descriptions and labels.
- **Check 3**: Toggle a capability in the Admin grid. Verify an inline `CircularProgressIndicator` appears *only* on the toggled capability.

## Execution Slices

### Execution Phase
**Complexity**: Low
**Reason**: UI-only changes. No complex state math, just presentation mapping and tracking a String instead of a boolean.

**Micro-Spec**:
- **Plain English Summary**: Create `CapabilityDictionary` with hardcoded human-readable labels, descriptions, and groups. Update `RoleDetailPage` to track `_mutatingCapability` instead of `_isMutating`. Update `OnlineCapabilityGrid` to use the dictionary for fallbacks and display an inline spinner on the mutating item. Update `ProfileCapabilitiesSection` to group capabilities by their domain and use the dictionary labels.
- **Value Delivered**: Solves H1, H2, and H8 heuristic violations. Greatly improves admin and user readability.
- **Entry State Required**: Admin app with existing capabilities rendering raw strings.
- **Exit State Guaranteed**: Dictionary-backed UI with domain grouping and inline spinners.
- **Scope**: `capability_dictionary.dart`, `role_detail_page.dart`, `online_capability_grid.dart`, `profile_capabilities_section.dart`.
- **Acceptance Criteria**: 
  - `admin:manage_roles` displays as "Manage Roles" with a clear description.
  - Toggling a checkbox shows a spinner strictly on that row.
  - Profile capabilities are clustered under bold headers (e.g., "Admin", "Submissions").

<command_logs>
- `grep_search` and `view_file` to review current UX implementations.
</command_logs>

## Handoff Block
Route fixes through `/implement` as these are UI/visual changes that do not alter the business logic or network math.

**Route 2: Visuals/Simple (Direct Build)**
`@[/implement]` Execute build for Execution Phase: `c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\implementation_plan_20260510_144831_pbacux_pbacux-fixes.md`
