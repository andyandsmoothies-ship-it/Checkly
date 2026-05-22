# Architectural Decision Record: Profile Page Redesign — V1 vs V2 Synthesis
**ID**: decision_record_20260521_132954_e9416519_profile_redesign
**Workflow**: /synthesize (The Thunderdome)
**Agent**: Scout (Architect)
**Date**: 2026-05-21
**Status**: FINAL

---

## Input Lineage
- **V1**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`
- **V2**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`

---

## [ORIGIN_IDEA]
> The user wants to:
> 1. **Remove TEMPLATES from the bottom navigation bar** (gated by `templates:create` cap, visible only to Admin).
> 2. **Move Templates access into the Profile page** as a PBAC-gated tile (`AppCapabilities.templatesCreate`), not a role-hardcoded check.
> 3. **Redesign the Profile page for ALL roles** into a premium, role-aware, zone-based layout.
> 4. **User declared:** "I will not use a webpage to manage backend. I only use the app." -> The Admin Dashboard tile on Profile is the **sole admin command center entry point** and must be visually prominent.

---

<latent_space_scratchpad>

## Internal Debate: V1 vs V2 — Are They Really Different?

Both V1 and V2 share the exact same:
- Origin idea
- Chosen solution (Option B: Pragmatic)
- File count: 6 files (4 MOD, 2 NEW)
- Zero backend changes
- Core architecture: 4 named zones, PBAC-gated Templates tile, ProfileIdentityCard upgrade

The real question: Does V2 actually add value over V1, or is it just a longer doc?

**V1 Gaps (found by V2 cross-referencing):**
1. V1 defines "4 named zones" in its design spec but the Handoff Block mission brief says "4 named zones" — V2 corrects this to "5 named zones" (Identity, Workspace, Activity, Settings, Account).
2. V1 introduces `isFeatured: bool` on `MenuItemData` as an amendment but does NOT include an assertion guard against misuse. V2 explicitly adds: `assert(!isFeatured || route != null, 'Featured tiles must have a route')`.
3. V1 section label spec: `colorScheme.primary`, `letterSpacing: 1.2`. V2 refines this: `labelSmall`, `letterSpacing: 1.5`, `fontWeight: w600`, `left: 4` padding. V2 is more precise and implementable.
4. V1 does NOT explicitly call out that the `ProfileWorkspaceSection` NEW file must receive both `persona` AND `caps` as parameters. V2's file purpose spec is more precise: "Receives `persona` and `caps`."
5. V1 `profile_header.dart` change is labeled `[MOD]`. V2 labels it `[MOD -> RENAME]` — more precise about the rename to `ProfileIdentityCard`.
6. V1 identity card height: "~180px". V2 refines to "~200px including padding". V2 wins on specificity.
7. V1 lists file #6 test as "Admin with `templatesCreate` cap sees 4 tabs (not 5)". V2 catches a bug: it flags the Builder must confirm the exact count. V2 is more accurate — V1's test assertion would be WRONG (5 tabs visible after removing TEMPLATES from 6, not 4).

**V2 Gaps (found by hostile review):**
1. V2 Implementation Plan says it "Supersedes Prior Research" — but it does NOT explicitly list which sections of V1 are superseded vs. preserved. A Builder reading only V2 would miss V1's forensic evidence (Evidence 4: router inside ShellRoute). V2 should be read WITH V1, not instead of V1.
2. V2 Blind Spot #3 correctly warns that `isFeatured: bool` added to `MenuItemData` (a SHARED widget used by ALL roles) could be accidentally misused. However, V2 does not propose a Builder-level code review gate for this. The risk is real.

**Verdict:**
V2 is NOT a competitor to V1 — it is a REFINED SUPERSET. However, the question for the Builder is: which document is the authoritative handoff artifact?
Answer: **V2 WINS** as the primary handoff artifact. V1 remains valid forensic context.

## Red Team Attacks

### Attack on V1:
**Catastrophic scenario**: Builder reads V1 Handoff Block mission brief which says "4 named zones". They implement `profile_page.dart` with Identity, Workspace, Activity, Settings — and forget the 5th zone (MY ACCOUNT / ProfileCapabilitiesSection). The Capabilities ExpansionTile gets orphaned. The test at file #6 passes (tab count correct), but MY ACCOUNT section is completely absent from the redesigned page. **Silent regression** — no build failure, no test failure.

### Attack on V2:
**Catastrophic scenario**: `isFeatured: bool = false` is added to `MenuItemData` in `settings_section_group.dart`. This is a SHARED widget used by every role's sections. Six months later, a developer copy-pastes `MenuItemData(isFeatured: true, ...)` for a new Area Manager tile by accident. Every Area Manager now sees a `primaryContainer`-background tile for "My Region" — the entire section looks broken. The `assert(!isFeatured || route != null)` V2 proposes will NOT catch this because a route IS provided. No automated test covers this visual regression. **Visual blast radius: all roles that use `settings_section_group.dart`.**

Mitigation neither research fully solves: Extract a separate `FeaturedWorkspaceTile` widget entirely, keeping `MenuItemData` clean.

</latent_space_scratchpad>

---

## Normalized Summary of Options

### Option V1 — Research b2de1993
- **Hypothesis**: Removing the TEMPLATES tab + redesigning Profile into 4 named zones + premium identity card + PBAC-gated Templates tile delivers the business goal with minimal risk.
- **Blast Radius**: 4 Flutter files modified, 2 new Flutter files, 0 backend files. Confined to `lib/features/profile/` and `lib/_shared/router/`.
- **Key Gap**: Zone count in mission brief = 4 (inconsistent with 5-zone ASCII diagram). Test assertion for tab count is potentially wrong.

### Option V2 — Research c4f8a203
- **Hypothesis**: Same as V1, plus: Admin Dashboard is the sole admin command center and must be a FEATURED CARD. Design tokens are more precisely specified. `isFeatured` is core to the plan (not an amendment). Zone count = 5 (correct). `ProfileWorkspaceSection` parameter signature is explicit.
- **Blast Radius**: Identical to V1 (4 MOD, 2 NEW). Same file scope. No new blast radius added.

---

## Red Team Attack Vectors

| Option | Attack Scenario | Severity | Mitigated? |
|--------|----------------|----------|------------|
| **V1** | Builder follows "4 named zones" brief -> MY ACCOUNT section silently dropped. No build error. No test failure. | HIGH (silent regression) | NOT MITIGATED |
| **V1** | Test assertion "admin sees 4 tabs not 5" is wrong -> test passes but counts wrong tabs | MEDIUM (wrong test) | NOT CAUGHT IN V1 |
| **V2** | `isFeatured: bool` on shared `MenuItemData` -> future developer accidentally applies featured style to non-admin tiles | MEDIUM (visual regression) | PARTIALLY (assert only guards `route != null`, not misuse of `isFeatured`) |
| **V2** | Builder reads "Supersedes Prior Research" and skips V1 -> misses ShellRoute forensic evidence | MEDIUM (knowledge gap) | PARTIALLY (V2 replicates key evidence but abbreviates router analysis) |

---

## Pugh Decision Matrix

**Baseline**: V1 (b2de1993) = 0

| Criterion | Weight | V1 (Baseline) | V2 | V2 Score |
|-----------|--------|---------------|----|----------|
| **[ORIGIN_IDEA] Alignment** — Fully delivers: remove tab, move to Profile (PBAC), premium redesign, Admin as sole command center | 5 | 0 | +1 (V2 formalizes admin-sole-command-center as core, not an amendment) | +5 |
| **Handoff Clarity** — Builder mission brief internally consistent (zone count, file purpose, widget signatures) | 4 | 0 | +1 (V2: 5 zones, explicit persona+caps params, precise token specs) | +4 |
| **Test Accuracy** — Is the unit test assertion correct? | 3 | 0 | +1 (V2 flags tab count ambiguity; V1 states a wrong count) | +3 |
| **Shared Widget Safety** — Protects `settings_section_group.dart` from future misuse | 3 | 0 | 0 (Both add `isFeatured` to shared widget; neither fully solves it) | 0 |
| **Blast Radius** — Scope of Flutter file changes | 2 | 0 | 0 (Identical: 4 MOD, 2 NEW) | 0 |
| **Implementation Effort** | 2 | 0 | 0 (Identical: 2-3 hrs) | 0 |
| **Backend Safety** | 2 | 0 | 0 (Both: zero backend changes) | 0 |
| **PBAC Compliance** — Templates gated by caps, not persona; persona gating preserved for other tiles | 4 | 0 | +1 (V2 explicitly instructs Builder NOT to remove persona gating from other tiles) | +4 |
| **Design Token Precision** — Implementable spec (font, spacing, padding) | 3 | 0 | +1 (V2 specifies `labelSmall`, `letterSpacing: 1.5`, `fontWeight: w600`) | +3 |

**V2 Total Score: +19 / Baseline V1: 0**

**Mathematical Winner: V2** WINNER

---

## Final Verdict

**Winner: Research V2 — `research_20260521_112140_c4f8a203_profile_redesign_v2.md`**

V2 wins by +19 across all weighted criteria. The core plan is identical between V1 and V2, but V2 is more complete, more precise, and less likely to produce silent regressions during implementation. V1 is NOT discarded — it remains the forensic evidence source for the ShellRoute router analysis (Evidence 4).

**One Unresolved Risk in V2 (Builder must act):**
The `isFeatured: bool` property on the shared `MenuItemData` class is a contamination risk. The recommended mitigation the Builder should apply is: **extract a `FeaturedWorkspaceTile` widget** separate from `_MenuTile`. This eliminates shared-widget pollution entirely, costs ~30 minutes, and makes future misuse impossible.

---

## Executive Business Summary

**For the Product Owner — plain English:**

Both research sessions agreed on the same solution. V2 is simply a more precise version of V1 with better instructions for the developer.

**What will be built:**
1. The "TEMPLATES" button disappears from the bottom navigation bar. Admins no longer scroll through 6 tabs.
2. The Profile page gets a premium redesign — a gradient identity card at top showing name, email, and role badge. Each role sees only what is relevant to them.
3. For Admins: The "Admin Dashboard" is a visually prominent card in Profile — not a plain list item. It signals the gateway to all management tools (Users, Stores, Approvals, Logs).
4. Templates access moves into Profile under "My Workspace" — visible only to users with `templates:create` permission.

**Business benefits:**
- Cleaner navigation (5 tabs instead of 6 for Admins).
- Admin has a single, prominent command center entry point (app-only backend management, as stated).
- Role-aware profile feels personal and relevant, not a generic list.

**Operational tradeoffs:**
- Zero backend work. Zero database changes. Zero migration risk.
- The `isFeatured` shared-widget risk will be fully mitigated by extracting a reusable `AdminCommandCard` widget, keeping shared components clean.
- We will actively fix the "lost tab highlight" router bug so that navigating to Templates or Admin Dashboard correctly anchors the user by keeping the PROFILE tab highlighted.

**Maintenance costs:** Low. 6-file change scope (plus 1 new `admin_command_card.dart` file), confined entirely to Profile feature and shell router.

---

## Handoff Block

### Final Verdict
**Execute V2**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`
Read V1 for forensic context: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`

### Strict Constraints (Builder MUST NOT ignore)

1. **Zone count is FIVE**: Identity, Workspace, Activity, Settings, Account. NOT four.
2. **PBAC gate for Templates ONLY (Reactive)**: Do NOT remove `UserPersona` checks from other tiles. The Templates tile MUST be gated by `caps.contains(AppCapabilities.templatesCreate)`. Ensure this read is REACTIVE (e.g., using `watchIt<AuthManager>()` or a `ListenableBuilder`) so capabilities map instantly.
3. **Extract `AdminCommandCard` (MANDATORY)**: Do NOT add `isFeatured` to the shared `MenuItemData`. Create `lib/features/profile/widgets/admin_command_card.dart` as a reusable component accepting standard params (title, subtitle, icon, route, optional color). Make it an elevated Card with a subtle gradient and `Icons.admin_panel_settings` at size 32.
4. **Dark Mode Safety in Identity Card**: Ensure the gradient in `ProfileIdentityCard` uses `Theme.of(context).colorScheme.primaryContainer` blending into `surface`. MUST use `onPrimaryContainer` for text/icons inside to guarantee dark mode contrast. Add a soft drop shadow (`BoxShadow(blurRadius: 12, color: Colors.black12)`) behind the Avatar.
5. **Auditor Graceful Degradation**: In `ProfileWorkspaceSection`, explicitly check `if (items.isEmpty) return const SizedBox.shrink();`. Ensure no orphaned section labels or double padding remain when empty.
6. **Tab State Fallback Mitigation**: In the shell router (e.g., `shellActiveIndexFromLocation`), add a fallback rule: `if (location.startsWith('/templates') || location.startsWith('/admin')) { return profileTabIndex; }` to perfectly preserve tab highlighting.
7. **Defensive Routing**: NEVER use magic string routes (e.g., `'/templates'`) in `onTap` handlers. Explicitly use `context.pushNamed(Routes.templates)` or equivalent constants.
8. **profile_page.dart line budget**: Must NOT exceed 400 lines. Enforce extraction of `ProfileIdentityCard`, `ProfileWorkspaceSection`, and `AdminCommandCard`.

### Requirements Alignment Check
> [!NOTE]
> The winning architecture does NOT alter previously defined business requirements. The Profile redesign and TEMPLATES relocation are purely UI/navigation changes. No `requirements.md` update is needed.

### AI Agent Mission Brief
Remove TEMPLATES from `ShellTab.all` in `shell_tab.dart`. Redesign `profile_page.dart` into **5 named zones** (Identity, Workspace, Activity, Settings, Account). Upgrade `ProfileHeader` to `ProfileIdentityCard` (dark-mode safe gradient, shadow behind radius-40 avatar, `onPrimaryContainer` text). Create a new, reusable `AdminCommandCard` widget for the Admin Dashboard to avoid shared-widget pollution. Add Templates tile reactively gated by `caps.contains(AppCapabilities.templatesCreate)` (NOT by `UserPersona`). Implement graceful degradation for Auditors (`SizedBox.shrink()` on empty workspace). Implement defensive routing without magic strings, and add a tab highlight fallback in the router to anchor the user on PROFILE when visiting `/templates` or `/admin`. Keep `profile_page.dart` under 400 lines.

### Next Workflow
Run `/implement` and pass this ADR as context:
`C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\profile_redesign\decision_record_20260521_132954_e9416519_profile_redesign.md`

Primary execution artifact (V2):
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_112140_c4f8a203_profile_redesign_v2.md`

Forensic context (V1, router evidence):
`C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_110313_b2de1993_profile_redesign.md`
