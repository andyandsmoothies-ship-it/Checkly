# Research: Profile Page Capabilities Display

>[ORIGIN_IDEA]: "show the current role capabilities on the profile page, so that i don't need to switch to admin to view"

<latent_space_scratchpad>
Goal: Display active PBAC capabilities directly on the Profile UI.
Status Quo: ProfilePage is currently a simple StatelessWidget that reads AuthManager.currentUser once. AuthManager holds capabilities in a ValueNotifier<Set<String>> capabilities.
Reactivity: Since capabilities can be updated dynamically via the PBAC debounce listener, the ProfilePage needs a ValueListenableBuilder or watch_it binding to update the UI without requiring an app restart or logout.
Visuals: Capabilities are raw strings (e.g., "submissions:create"). Displaying 15 of these directly under the user's name will destroy the UI hierarchy. An ExpansionTile or a dedicated section at the bottom is safer.
</latent_space_scratchpad>

## E2E Workflow Map
- **Upstream Source**: `AuthManager.capabilities` (a `ValueNotifier<Set<String>>`).
- **UI Destination**: `lib/features/profile/pages/profile_page.dart`.
- **Reactivity Gap**: `ProfilePage` must be updated to listen to `capabilities` changes dynamically so the UI updates instantly when the backend PBAC listener triggers.

## Comparative Decision Matrix

| Option | Approach | Tradeoffs | Verdict |
|---|---|---|---|
| **A. Inline Wrap (Native Fit)** | Add a `Wrap` of Material `Chip` widgets directly under the Profile Header containing all raw capability strings. | **Pros:** Simplest code. <br>**Cons:** Clutters UI. Breaks aesthetics if a role has 20+ capabilities. | **Reject**. Bad UX. |
| **B. Expandable Section (Pragmatic)** | Add a "My Capabilities" `ExpansionTile` at the bottom of the profile page. Wrap the capabilities in a `ValueListenableBuilder` tied to `AuthManager.capabilities`. | **Pros:** Hides technical strings until clicked. UI stays clean. Updates dynamically when PBAC cache reloads. | **Approve**. Best balance of visibility and clean UI. |
| **C. Dedicated Debug Route (Enterprise)** | Build a new `/profile/capabilities` page showing raw capability grids, implicit vs explicit origins, and PBAC cache timestamps. | **Pros:** Max visibility. <br>**Cons:** Overkill. Violates Keep it Simple rule. | **Reject**. |

### Required NFR Blind Spots
1. **Layout Overflow**: High-privilege roles have many capabilities. A strict `Row` or `ListView` will overflow; the UI must use a `Wrap` widget to allow chips to flow to the next line.
2. **Reactivity Gap**: A simple read of `auth.capabilities.value` in `build()` will not update if the backend changes roles mid-session. The UI must wrap the widget in a `ValueListenableBuilder`.
3. **UX Tone**: Raw capability strings (e.g., `templates:manage`) are system tokens, not user-friendly copy. They should be styled like "code" tokens or muted pills, not primary text.

### Architectural Conflicts
- **Conflict (GEMINI.md - Keep Files Small)**: `profile_page.dart` is currently 157 lines. Adding a complex expandable capability block directly inside the `build` method will bloat the file. The capability display logic MUST be extracted into a standalone file (e.g., `lib/features/profile/widgets/capabilities_section.dart`).

<forensic_evidence>
```text
C:\Users\HP\Documents\GitHub\Checkly> grep -n "class ProfilePage" lib/
lib\features\profile\pages\profile_page.dart:13:class ProfilePage extends StatelessWidget {

C:\Users\HP\Documents\GitHub\Checkly> cat lib\_shared\services\policy_manager.dart
...
  bool can(String capability) {
    final caps = _auth.capabilities.value;
...
```
</forensic_evidence>

## Handoff Block
- **Final Verdict**: Viable (Option B).
- **Effort Sizing**: Track A (Tactical addition). Will take <10 minutes to implement a standalone widget and inject it.
- **AI Agent Mission Brief**: Implement an expandable capability viewer in `ProfilePage`. Extract it to `capabilities_section.dart`. Bind it to `AuthManager.capabilities` using a `ValueListenableBuilder` so it updates in real-time when the PBAC cache reloads.
- **Next Step**: Execute the `/analyze-feature` workflow by referencing this document:
  `@[/analyze-feature] file:///c:/Users/HP/Documents/GitHub/Checkly/docs/product/research_20260510_130500_profile-capabilities.md`
