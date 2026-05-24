# Research: Profile Capabilities Display

> [ORIGIN_IDEA]: "show the current role capabilities on the profile page, so that i don't need to switch to admin to view"

<latent_space_scratchpad>
Goal: Show current user capabilities directly on the profile page.
Status Quo: `ProfilePage` (`lib/features/profile/pages/profile_page.dart`) reads `AuthManager` from `GetIt`. `AuthManager` exposes `ValueListenable<Set<String>> capabilities`.
Since capabilities can change in the background (e.g., auto-refresh after 5 mins), the UI must react to `auth.capabilities` using a `ValueListenableBuilder`.
Visuals: A raw list of capabilities (e.g., `submissions:create`, `templates:update`) can be long (up to 18 items). Displaying them inline will destroy the UI hierarchy. Best to put them inside an `ExpansionTile` or a dedicated list under a "My Permissions" section at the bottom of the Profile UI.
</latent_space_scratchpad>

## E2E Workflow Map
- **Upstream Source**: `AuthManager.capabilities` (`ValueListenable<Set<String>>`).
- **Downstream Effect**: Displaying a list of chips in the `ProfilePage`.
- **Friction/Status Quo**: Currently, users must navigate to the Admin Dashboard (if they have access) to see what permissions they have. This is opaque for non-admins who just want to know why a button is missing.
- **Context Handoff**: `ProfilePage` will inject a new widget (e.g., `CapabilitiesSection`) that listens to `AuthManager.capabilities`.

## Comparative Decision Matrix
### Option A: Standard ExpansionTile (Strict Native Fit)
- **Description**: Add a new `SettingsSectionGroup` or `ExpansionTile` at the bottom of the profile list titled "My Capabilities". Inside, render a `Wrap` of `Chip` widgets showing each capability string.
- **Pros**: Clean, simple, doesn't clutter the main UI. Uses native components.
- **Cons**: Might be slightly technical for non-admin users (seeing strings like `stores:write`).

### Option B: Inline Badges under Name (Pragmatic Balance)
- **Description**: Display capabilities directly under the user's role in the header, hiding the rest in a scrollable horizontal row.
- **Pros**: Highly visible.
- **Cons**: UI hierarchy will be cluttered. System tokens don't look good as subtitle badges.

### Option C: Dedicated Permissions Page (Enterprise Overhaul)
- **Description**: A whole new screen `/profile/permissions` showing a detailed breakdown of what each capability allows.
- **Pros**: Very clear for users.
- **Cons**: Massive overkill for a simple "show me my capabilities" request.

**Verdict**: Go with Option A.

## Blind Spots (NFRs)
1. **Payload Size / Screen Real Estate**: If an admin user has all 18+ capabilities, rendering 18 chips inline will take up significant vertical space. An `ExpansionTile` completely mitigates this.
2. **Reactivity**: If we don't use a `ValueListenableBuilder`, the capabilities list will go stale if updated in the background. It must be reactive.
3. **Translation**: The capabilities are system tokens (`templates:create`), which are inherently technical. We can apply basic string formatting (e.g., replacing `:` with a space and capitalizing) to make the chips more readable.

## Conflicts
- **Rule Conflict**: The "Keep Files Small" rule (Files over 400 lines confuse AI). `ProfilePage` is currently 157 lines. Adding a large capabilities builder section might bloat it. We must extract the `CapabilitiesSection` into a separate widget file (e.g., `lib/features/profile/widgets/profile_capabilities_section.dart`) to respect this rule.

<forensic_evidence>
Executed `grep_search` for `class ProfilePage` and `class AuthManager`.
Viewed `lib/features/profile/pages/profile_page.dart` (157 lines).
Viewed `lib/features/auth/manager/auth_manager.dart` confirming the presence of `ValueListenable<Set<String>> capabilities`.
</forensic_evidence>

## Handoff Block
- **Final Verdict**: Viable. Proceed with Option A (ExpansionTile with Chips).
- **Effort Sizing**: Track A (Fast). 2 files (modify `ProfilePage`, create `ProfileCapabilitiesSection`).
- **AI Agent Mission Brief**: Create a `ProfileCapabilitiesSection` widget that uses `ValueListenableBuilder` on `AuthManager.capabilities` to display the user's active PBAC tokens as a wrapped list of chips inside an `ExpansionTile`. Inject this into `ProfilePage`.
- **Next Command**: `@[/analyze-feature] c:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260510_1307_v123_profile-caps.md`
