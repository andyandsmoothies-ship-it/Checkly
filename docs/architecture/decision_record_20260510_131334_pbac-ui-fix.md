# Decision Record: Profile Capabilities Display

## Input Lineage
- `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260510_130500_profile-capabilities.md`
- `file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260510_1307_v123_profile-caps.md`

## [ORIGIN_IDEA]
"show the current role capabilities on the profile page, so that i don't need to switch to admin to view"

<latent_space_scratchpad>
Both research artifacts are virtually identical, proposing an `ExpansionTile` containing a `Wrap` of `Chip` widgets, driven by a `ValueListenableBuilder` tied to `AuthManager.capabilities`, and extracted into `lib/features/profile/widgets/profile_capabilities_section.dart` to prevent file bloat in `ProfilePage`.
Since both artifacts propose the same baseline, the synthesis will pit the "Naive Implementation" (Baseline) against a "Defensive Implementation" (Option B) that mitigates the red team attacks.
</latent_space_scratchpad>

## Summary of Options
- **Baseline (Artifacts 1 & 2):** Extract a `ProfileCapabilitiesSection` widget, use an `ExpansionTile`, and bind a `ValueListenableBuilder` to `AuthManager.capabilities`. Apply basic string formatting to capability strings.
- **Option B (Defensive):** Baseline + strict null safety on the capabilities set, boundary checks for string formatting (to prevent `RangeError` if a colon is missing), and explicit empty state handling when capabilities are empty.

## Red Team Attack Vectors (Hostile Interrogation)

### Attack on Baseline (Artifacts 1 & 2)
1. **The RangeError Grey Screen of Death:** The research suggests "replacing `:` with a space". If a developer blindly uses `capability.split(':')[1]` and the backend returns a new capability format without a colon (e.g., `superadmin` or an empty string), it will throw a `RangeError`. This will crash the entire Profile page for the user.
2. **The Null/Empty Trap:** If `AuthManager.capabilities.value` is temporarily null or empty (e.g., during a token refresh or logout transition), rendering a generic ExpansionTile that just crashes or looks broken is a failure.
3. **The Unbounded Wrap Memory Leak:** If a runaway backend bug sends 5,000 capabilities, an unconstrained `Wrap` inside an `ExpansionTile` could cause severe layout jank and memory spikes when opened.

## Pugh Decision Matrix

| Criteria | Baseline (Artifact 1 & 2) | Option B (Defensive) |
|---|---|---|
| **Origin Idea Alignment** | 0 | 0 |
| **Safety (Crash Prevention)** | 0 | +1 |
| **UI Cleanliness (No bloat)** | 0 | 0 |
| **Reactivity (Background sync)** | 0 | 0 |
| **Resilience (Malformed data)** | 0 | +1 |
| **Total** | **0** | **+2** |

## Final Verdict
**Option B (Defensive)** is the mathematical winner.

## Executive Business Summary
The team will add a "My Capabilities" expandable section to the bottom of the user's Profile Page. This allows users to see exactly what permissions they have without navigating to an admin screen. To ensure the app remains highly stable, we will include safeguards so that if the server sends strangely formatted permissions, the profile screen won't crash and will simply display them as best as possible.

## Handoff Block
- **Final Verdict**: Option B (Defensive Implementation of ExpansionTile).
- **Strict Constraints**: 
  1. MUST NOT use unprotected string splits (e.g., `.split(':')[1]`). Use `.replaceAll(':', ' ')` or safe regex.
  2. MUST handle `null` or `empty` states gracefully (e.g., "No capabilities assigned").
  3. MUST extract to `lib/features/profile/widgets/profile_capabilities_section.dart` to respect the 400-line limit on `ProfilePage`.
  4. MUST explicitly sort the capabilities alphabetically (`.toList()..sort()`) to guarantee stable rendering order.
  5. MUST enforce a hard display limit (e.g., `.take(50)`). If exceeded, render a trailing "+X more" chip to prevent layout/memory jank.
  6. MUST apply Title Casing to the formatted strings (e.g., "Submissions Create") to avoid a database-dump aesthetic.
  7. MUST style the `Chip` background using `Theme.of(context).colorScheme.surfaceContainerHighest` and text with `onSurfaceVariant`.
- **Requirements Alignment Check**: N/A (Does not alter core business flow, just surfaces existing state).
- **AI Agent Mission Brief**: Implement `ProfileCapabilitiesSection` with an `ExpansionTile` and `Wrap` of `Chip`s, bound to `AuthManager.capabilities` via `ValueListenableBuilder`. Ensure string formatting is crash-proof and empty states are handled. Inject it into `ProfilePage`.
- **Next Command**: `@[/implement] c:\Users\HP\Documents\GitHub\Checkly\docs\architecture\decision_record_20260510_131334_pbac-ui-fix.md`
