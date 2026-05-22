<latent_space_scratchpad>
## Reasoning Scratchpad

### Problem Framing
This is a pure visual reskin. Zero business logic changes. Zero database changes. Zero new features. The risk is NOT architectural — it is EXECUTION risk: 37 screens + 13 shared widgets + 4 theme files = a large surface area. The primary danger is:
1. Drifting widget interfaces (mock vs real) if custom widgets are poorly typed
2. Scope creep (someone adds a new feature during the reskin)
3. Build breaks from replacing Material widget references globally

### Two Shapes (Options)

**Shape A — Theme Override First (Top-Down)**
Strategy: Replace AppColors + AppTheme first, then build custom primitives, then update screens.
- Pros: Fast start. Color/font changes cascade globally through ThemeData with zero screen changes.
- Cons: Some components (BubblyButton, StrokeCard) can't be achieved via ThemeData alone, so screens still need manual intervention.

**Shape B — Primitives First (Bottom-Up)**
Strategy: Build BubblyButton, StrokeCard, etc. as new widgets first. Then wire the theme. Then update screens to use the new primitives.
- Pros: Each primitive is independently testable before we touch any screen.
- Cons: Theme changes will look wrong until screens are updated. More isolated but also more parallel risk.

### Verdict: Shape A is superior because:
- ThemeData overrides give us GLOBAL color + font wins immediately, with zero screen-by-screen changes needed.
- After the Theme Slice is done, every screen *already looks different*, giving us a visible baseline.
- Custom primitives are additive on top, not a prerequisite.

### Slice Breakdown (Risk-driven)
This epic must be sliced to stay under 5-file edits per phase:

Slice 1 [BLOCKING] — Foundation (Colors + Font + ThemeData)
- Files: app_colors.dart, app_theme.dart, app_fonts.dart, pubspec.yaml (if needed)
- Risk: LOW (pure constant replacement, no logic)
- This is the keystone. ALL other slices depend on it.

Slice 2 [SEQUENTIAL after 1] — Core Primitives (BubblyButton, StrokeCard, QuestProgressBar)
- Files: 3 NEW files in lib/_shared/widgets/primitives/
- Risk: LOW (purely additive, no existing file change)

Slice 3 [SEQUENTIAL after 2] — Supporting Primitives (PillChip, PastelAvatar, BubblySwitch, BubblyDialog)
- Files: 4 NEW files in lib/_shared/widgets/primitives/
- Risk: LOW (additive)

Slice 4 [SEQUENTIAL after 2] — Shared Widget Reskin (13 existing shared widgets refactored to use new primitives)
- Files: 13 existing files in lib/_shared/widgets/
- Risk: MEDIUM (replacing existing widgets that are used everywhere)

Slice 5 [SEQUENTIAL after 4] — Screen Reskin: Auth + Dashboard + Profile
- Files: LoginPage, AccessPendingPage, DashboardPage, ProfilePage, ActivityHistoryPage
- Risk: MEDIUM (visible changes, but self-contained)

Slice 6 [PARALLEL with 5] — Screen Reskin: Audit + Programs
- Files: AuditFormPage, HistoryPage, SurveyResultsPage, ProgramListPage, ProgramDashboardPage, ProgramExecutionPage, AreaCampaignListPage
- Risk: MEDIUM

Slice 7 [PARALLEL with 5] — Screen Reskin: Admin + Analytics + Stores
- Files: AdminDashboardPage, AuditApprovalPage, ScheduleAuditPage, StoreManagementPage, UserManagementPage, RoleListPage, RoleDetailPage, GlobalRiskManagementPage, SystemLogsPage, StoreDashboardPage, AnalyticsPage
- Risk: MEDIUM

Slice 8 [PARALLEL with 5] — Screen Reskin: Templates + ActionPlans + Notifications + UserGroups
- Files: All remaining pages (TemplateListPage, ActionPlansPage, InboxPage, UserGroupListPage, etc.)
- Risk: LOW

### Three-Perspective Review

**DB Architect (9/10):** No database tables, no migrations, no entities, no sync steps. Pure Flutter layer. This is the lowest possible DB risk. Only risk: if a screen's stat data display changes in a way that triggers a new query — but the research explicitly forbids new features. Score: 9/10.

**Security Auditor (9/10):** No new endpoints, no new auth paths, no permission changes. `ActionGuard` and `PermissionGuard` widgets are explicitly marked as "logic-only, no visual change." The only risk is if a reskin accidentally hides an ActionGuard widget. Mitigated by: search for ActionGuard usage in all refactored files before completing each slice. Score: 9/10.

**Junior Dev Maintenance (7/10):** The main risk for a junior dev is the explosion of custom primitives (BubblyButton, StrokeCard, QuestProgressBar, PillChip, PastelAvatar, BubblySwitch, BubblyDialog). If they are poorly named or not documented, the next developer will be confused about when to use which. Mitigation: add clear dartdoc on every primitive, create a single `lib/_shared/widgets/primitives/primitives.dart` barrel export. Score: 7/10 (borderline — must ensure clear naming).

### Architecture constraints
- Files must stay under 400 lines (GEMINI.md rule)
- BubblyButton = custom Stack widget (not ElevatedButton subclass) — estimated 60-80 lines
- StrokeCard = thin wrapper around Container + BoxDecoration — estimated 30-40 lines
- Each primitive file is well under 400 lines. ✅
</latent_space_scratchpad>

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\product\research_20260521_194300_d8f7e6c5_duolingo_design.md`

---

## Executive Summary

This Epic replaces the entire visual identity of the Checkly Flutter app from the current "Apothecary" (muted greens, editorial, Material 3 default) aesthetic to a **"Duolingo-Inspired Gamified"** design language — tactile 3D buttons, vibrant color palette, bold rounded typography, and pill-shaped UI elements. 

**Scope contract (immutable):**
- ✅ All 37 existing screens are visually refactored
- ✅ All 13 shared widgets are restyled
- ✅ 20 Material primitives are replaced with custom alternatives
- ❌ Zero new features added
- ❌ Zero database changes
- ❌ Zero business logic changes
- ❌ Zero new screens added

```
[AppColors (new palette)] ──> [AppTheme (new ThemeData)]
                                       │
                     ┌─────────────────┼─────────────────┐
                     ▼                 ▼                 ▼
             [Custom Primitives]  [Shared Widgets]  [Feature Screens]
            BubblyButton          checkly_fab        DashboardPage
            StrokeCard            role_badge         ProfilePage
            QuestProgressBar      score_avatar       AuditFormPage
            PillChip              section_header     ... (34 more)
            PastelAvatar          stat_block
            BubblySwitch          warm_chip
            BubblyDialog          ...
```

---

## Decision Matrix

### Requirements (R)

| ID | Requirement |
|:---|:---|
| R1 | All screens must use the Duolingo palette (Feather Green, Macaw Blue, Cardinal Red, etc.) |
| R2 | Typography must switch from Manrope → Nunito (w600/w700/w800/w900) |
| R3 | Primary action buttons must have a solid 3D bottom border (not blurred shadow) |
| R4 | Cards must be flat white with a 2px Swan border (no elevation/shadow) |
| R5 | Text inputs must have a 2px Swan border, turning Macaw Blue on focus |
| R6 | All shape corners must be rounded (no sharp edges) |
| R7 | Gray must never be used as a base fill color — pastels only |
| R8 | Bottom navigation must show icon-only (no text labels) with vibrant active state |
| R9 | `ActionGuard` and `PermissionGuard` widgets must remain fully functional (invisible) |
| R10 | Each file must stay under 400 lines |
| R11 | No new packages added beyond `google_fonts` (already installed ^8.0.2) |

### Shapes (Options)

**Shape A — Theme Override First (Top-Down)**
1. Rewrite `AppColors` with the Duolingo palette
2. Rewrite `AppTheme._buildTheme()` (CardTheme, AppBarTheme, TextTheme, NavigationBarTheme, etc.)
3. Build custom primitives (`BubblyButton`, `StrokeCard`, etc.) as additive new files
4. Update screens to swap in new primitives where ThemeData can't reach

**Shape B — Primitives First (Bottom-Up)**
1. Build all custom primitives independently first
2. Then wire `AppColors` + `AppTheme`
3. Then update screens

### Fit Check

| Requirement | Shape A (Top-Down) | Shape B (Bottom-Up) |
|:---|:---:|:---:|
| R1 Color palette globally applied | ✅ | ✅ |
| R2 Typography globally applied | ✅ | ✅ |
| R3 3D buttons (not via ThemeData) | ✅ (additive step 3) | ✅ |
| R4 Flat cards via CardTheme override | ✅ | ✅ |
| R5 Input borders via InputDecorationTheme | ✅ | ✅ |
| R6 Rounded corners via ThemeData | ✅ | ✅ |
| R7 No grey fills | ✅ | ✅ |
| R8 Bottom nav icon-only | ✅ | ✅ |
| R9 Guards untouched | ✅ | ✅ |
| R10 Files under 400 lines | ✅ | ✅ |
| R11 No new packages | ✅ (google_fonts already installed) | ✅ |
| **Visible progress after first slice** | ✅ **Immediate global win** | ❌ Nothing visible until screens updated |

### Verdict: **Shape A wins** — immediate, global color + font cascade from ThemeData changes alone, providing tangible visible progress before any screen is manually touched.

---

## Risk Assessment

| Risk | Severity | Mitigation |
|:---|:---|:---|
| ThemeData override breaks an existing screen with hardcoded colors | Medium | Search for hardcoded Color() literals in screen files before each slice; replace with AppColors tokens |
| BubblyButton becomes a "God Widget" (too many props) | Low | Cap at 5 constructor params: `label`, `onPressed`, `color`, `icon?`, `isLoading?` |
| ActionGuard hidden by visual refactor | Low | Grep for `ActionGuard` in every refactored file. Never remove it. |
| File exceeds 400 lines | Low | Each primitive is ~60-80 lines. Split if any file approaches 350 lines. |
| google_fonts version mismatch | None | Already `^8.0.2` in pubspec.yaml. `GoogleFonts.nunito()` is available in v8. |
| Scope creep (dev adds XP/Streak features during reskin) | Medium | All slices must be reviewed against the scope contract before closing. |

---

## Visual & Functional Context

### Screen Mapping (Role-based)

| Role | Core Screens | Visual Priority |
|:---|:---|:---|
| **Admin** | AdminDashboardPage, UserManagementPage, RoleListPage, StoreManagementPage | HIGH — Command hub |
| **Area Manager** | AnalyticsPage, AreaCampaignListPage, ProgramDashboardPage | HIGH — Leaderboard style |
| **Store Manager** | DashboardPage, ProgramListPage, StoreDashboardPage | HIGH — Quest board |
| **Auditor** | AuditFormPage, HistoryPage, SurveyResultsPage | HIGH — Quiz card style |
| **All Roles** | ProfilePage, InboxPage, LoginPage | HIGH — First impression |

### Overflow / Truncation Rules (No Change)
> These rules carry over from the current app. The reskin must NOT change truncation behavior.

| Widget | Current Overflow Rule | Maintained? |
|:---|:---|:---|
| `ListTile` titles | Single line, `overflow: ellipsis` | ✅ Must preserve |
| `StrokeCard` content | Wraps naturally | ✅ |
| `stat_block.dart` number | Fixed font size, no truncation | ✅ |

---

## System Context

| Concern | Impact on this Epic |
|:---|:---|
| **Offline-first** | None — this is purely visual. No network calls added. |
| **RBAC / PBAC** | None — `ActionGuard` is explicitly out of scope for visual change. |
| **Sync** | None — zero entity or DTO changes. |
| **API Contracts** | None — zero backend changes. |
| **Dark Mode** | Out of scope for now. `AppTheme.dark` will remain as-is (not broken, but not reskinned). |

---

## Lifecycle Context

| Edge State | Current Behavior | New Behavior |
|:---|:---|:---|
| **Empty List** | `ChecklyEmptyState` — generic icon | Reskinned with pastel background and playful copy |
| **Error State** | Cardinal Red text | Already matches new Cardinal `#FF4B4B` |
| **Loading State** | `CircularProgressIndicator` | Overridden via ThemeData `progressIndicatorTheme` to Macaw Blue |
| **Rollback** | Revert `app_colors.dart` + `app_theme.dart` | Full rollback possible from just 2 files in Slice 1 |

---

## Data Context

**Zero database migrations required.**
**Zero entity changes required.**
**Zero new pubspec.yaml dependencies** (`google_fonts` already installed).

---

## Architecture Flow

```
[pubspec.yaml: google_fonts ^8.0.2]  ← already present
         │
         ▼
[lib/_shared/theme/app_colors.dart]   ← SLICE 1: Replace Apothecary with Duolingo palette
         │
         ▼
[lib/_shared/theme/app_theme.dart]    ← SLICE 1: Switch Manrope→Nunito, override all ThemeData
         │
         ▼ (global cascade — all screens inherit colors + font automatically)
         │
         ▼
[lib/_shared/widgets/primitives/]     ← SLICE 2+3: New custom widget files (BubblyButton, etc.)
         │
         ▼
[lib/_shared/widgets/*.dart]          ← SLICE 4: Reskin 13 shared widgets to use new primitives
         │
         ▼
[lib/features/**/pages/*.dart]        ← SLICES 5-8: Swap Material widgets for custom primitives
```

---

## Risk Review & Security

**DB Architect score: 9/10** — No schema changes. Zero risk.

**Security Auditor score: 9/10** — No new routes, endpoints, or auth paths. `ActionGuard` and `PermissionGuard` are out-of-scope for visual changes. Each slice review must grep for these widgets and confirm they are preserved.

**Junior Dev Maintenance score: 7/10** — Risk: primitive explosion. Mitigation:
- All new primitives stored in `lib/_shared/widgets/primitives/`
- A single `primitives.dart` barrel file exports all of them
- Every primitive has a dartdoc comment explaining when to use it

---

## Logs & Audits

No audit log changes. No system log entries introduced.

---

## Testing Expectations

This is a **UI-only reskin** — no behavioral tests are needed. However:

| Test Type | What to Verify |
|:---|:---|
| `flutter analyze` | Must pass with 0 errors after each slice |
| `flutter build apk --debug` | Must build successfully after each slice |
| Manual Visual Test | User manually hot-reloads and inspects each screen |
| `ActionGuard` presence check | `grep_search` for `ActionGuard` in every touched file to confirm it was not removed |

> No new unit tests required. The reskin changes no logic. However, if `BubblyButton` contains any stateful press animation, a widget test for the animation state is recommended.

<command_logs>
- `list_dir lib/features` → Found 12 feature modules
- `list_dir lib/_shared/widgets` → Found 13 shared widget files
- `list_dir lib/_shared/theme` → Found 4 theme files
- `grep_search "google_fonts" pubspec.yaml` → `google_fonts: ^8.0.2` already installed
- `grep_search "class.*Page extends.*Widget"` → Found 37 page classes across all features
- `view_file app_theme.dart` → Confirmed Manrope font, Material 3, Apothecary palette in use
- `view_file app_colors.dart` → Confirmed Apothecary palette (oatmeal, softPeach, sageGray, warmCream, charcoal, deepForest)
</command_logs>

---

## Handoff Block

**Final Decision:** Shape A (Theme Override First). Proceed with the Duolingo Reskin Epic.

**Epic Plan File:** `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`

---

### Slice Breakdown

**Slice 1 [BLOCKING] — Foundation: Colors + Typography + ThemeData**
- **Plain English**: Replace the "Apothecary" color palette and Manrope font with the Duolingo palette and Nunito font in the two central theme files. This makes the whole app look immediately different before touching a single screen.
- **Why this step now?**: Every other slice depends on these new color tokens being available.
- **Scenario Focus**: Basic Scenario
- **Value Delivered**: Run the app and see Feather Green, Macaw Blue, and Nunito Bold everywhere — instantly.
- **Entry State Required**: Current Apothecary theme active
- **Exit State Guaranteed**: `AppColors` contains the Duolingo palette. `AppTheme._buildTheme()` uses Nunito, flat AppBar, flat StrokeCard, flat inputs.
- **Architectural Scope**: `app_colors.dart`, `app_theme.dart`, `app_fonts.dart` only
- **Acceptance Criteria**:
  - `AppColors.featherGreen == Color(0xFF58CC02)` ✅
  - `AppColors.macawBlue == Color(0xFF1CB0F6)` ✅
  - `AppColors.swan == Color(0xFFE5E5E5)` ✅
  - `AppTheme.light` uses `GoogleFonts.nunitoTextTheme()` ✅
  - `CardTheme.elevation == 0` and border is `BorderSide(color: AppColors.swan, width: 2)` ✅
  - `flutter analyze` passes 0 errors ✅

---

**Slice 2 [SEQUENTIAL after 1] — Core Primitives: BubblyButton, StrokeCard, QuestProgressBar**
- **Plain English**: Build the 3 most important new UI building blocks: the 3D bubbly button, the flat stroke card, and the progress bar. These 3 are used on nearly every screen.
- **Why this step now?**: Screens can't be refactored until these primitives exist to replace their Material equivalents.
- **Scenario Focus**: Basic Scenario
- **Value Delivered**: Developers can use `BubblyButton(label: 'Start')` and `StrokeCard(child: ...)` in any screen.
- **Entry State Required**: Slice 1 complete (AppColors must exist)
- **Exit State Guaranteed**: 3 new files in `lib/_shared/widgets/primitives/`. Barrel export updated.
- **Architectural Scope**: `lib/_shared/widgets/primitives/bubbly_button.dart`, `stroke_card.dart`, `quest_progress_bar.dart`, `primitives.dart` (barrel)
- **Acceptance Criteria**:
  - `BubblyButton` animates (shrinks by 4px on press) ✅
  - `BubblyButton` renders solid bottom border in a darker shade of the fill color ✅
  - `StrokeCard` renders with `elevation: 0`, 2px Swan border, R: 16px ✅
  - `QuestProgressBar` fills Macaw Blue proportionally from `value: 0.0` to `value: 1.0` ✅
  - `flutter analyze` passes 0 errors ✅

---

**Slice 3 [SEQUENTIAL after 2] — Supporting Primitives: PillChip, PastelAvatar, BubblySwitch, BubblyDialog**
- **Plain English**: Build the 4 remaining primitive widgets for chips, avatars, toggles, and pop-up dialogs.
- **Why this step now?**: These are needed before refactoring the shared widgets in Slice 4.
- **Scenario Focus**: Basic Scenario
- **Value Delivered**: Developers have the full primitive library available.
- **Entry State Required**: Slice 2 complete
- **Exit State Guaranteed**: 4 new files in `lib/_shared/widgets/primitives/`. Barrel export updated.
- **Architectural Scope**: `pill_chip.dart`, `pastel_avatar.dart`, `bubbly_switch.dart`, `bubbly_dialog.dart`
- **Acceptance Criteria**:
  - `PillChip` renders with a pastel background (from a defined palette enum), no gray fill ✅
  - `PastelAvatar` renders initials on a pastel background determined by role ✅
  - `BubblySwitch` turns Feather Green when `value: true` ✅
  - `BubblyDialog` renders with R: 24px corners, Swan border ✅
  - `flutter analyze` passes 0 errors ✅

---

**Slice 4 [SEQUENTIAL after 3] — Shared Widget Reskin (13 files)**
- **Plain English**: Update the 13 existing shared widgets to use the new primitives and new color tokens. For example, `checkly_fab.dart` becomes a `BubblyFAB`, `role_badge.dart` becomes a `PillChip` per role.
- **Why this step now?**: These widgets appear on EVERY screen. Fixing them once here means every screen immediately benefits.
- **Scenario Focus**: Basic Scenario
- **Value Delivered**: Every screen that uses `RoleBadge`, `StatBlock`, `ChecklyEmptyState`, etc. automatically looks better.
- **Entry State Required**: Slice 3 complete (all primitives available)
- **Exit State Guaranteed**: All 13 shared widgets use new primitives. `ActionGuard` and `PermissionGuard` are unchanged.
- **Architectural Scope**: `lib/_shared/widgets/*.dart` (all 13 files)
- **Acceptance Criteria**:
  - `RoleBadge` for each of the 4 roles renders in the correct color (Beetle/Macaw/Bee/Feather) ✅
  - `ChecklyEmptyState` renders with a pastel background ✅
  - `ChecklyFAB` renders as a `BubblyFAB` (pill shape) ✅
  - `ActionGuard` and `PermissionGuard` files are NOT modified ✅
  - `flutter analyze` passes 0 errors ✅

---

**Slice 5 [SEQUENTIAL after 4] — Screen Reskin: Auth + Dashboard + Profile**
- **Plain English**: Visually update the first screens a user sees when they open the app: Login, Dashboard, and Profile.
- **Why this step now?**: These are the highest-visibility screens. A quick win here shows the new identity immediately.
- **Architectural Scope**: `LoginPage`, `AccessPendingPage`, `DashboardPage`, `ProfilePage`, `ActivityHistoryPage` (5 files)
- **Acceptance Criteria**: Each screen shows Duolingo palette + Nunito font + BubblyButtons where applicable. `flutter analyze` passes ✅

---

**Slice 6 [PARALLEL with 5] — Screen Reskin: Audit + Programs**
- **Plain English**: Visually update the core audit execution and program/campaign screens.
- **Architectural Scope**: `AuditFormPage`, `HistoryPage`, `SurveyResultsPage`, `ProgramListPage`, `ProgramDashboardPage`, `ProgramExecutionPage`, `AreaCampaignListPage`, `ProgramAssignmentListPage`, `ProgramCreateWizardPage`, `ProgramStoreSelectorPage` (10 files)
- **Acceptance Criteria**: Audit questions use card-per-question style. Campaign list uses QuestProgressBar. `flutter analyze` passes ✅

---

**Slice 7 [PARALLEL with 5] — Screen Reskin: Admin + Analytics + Stores**
- **Plain English**: Visually update the admin command center, leaderboards, and store management screens.
- **Architectural Scope**: `AdminDashboardPage`, `AuditApprovalPage`, `ScheduleAuditPage`, `StoreManagementPage`, `UserManagementPage`, `RoleListPage`, `RoleDetailPage`, `GlobalRiskManagementPage`, `SystemLogsPage`, `SystemLogDetailPage`, `SystemPivotLogsPage`, `StoreDashboardPage`, `StoreSelectorPage`, `AnalyticsPage` (14 files)
- **Acceptance Criteria**: Analytics uses leaderboard layout. Admin hub uses BubblyButton grid. `flutter analyze` passes ✅

---

**Slice 8 [PARALLEL with 5] — Screen Reskin: Templates + Action Plans + Notifications + User Groups**
- **Plain English**: Visually update the remaining screens — templates, action plans, inbox, and user groups.
- **Architectural Scope**: `TemplateListPage`, `TemplateDetailPage`, `TemplateBuilderPage`, `TemplateWizardPage`, `ActionPlansPage`, `ActionPlanDetailPage`, `InboxPage`, `NotificationDrawerPage`, `UserGroupListPage` (9 files)
- **Acceptance Criteria**: Template grid uses StrokeCards with PillChip category badges. `flutter analyze` passes ✅

---

### Handoff Roadmap

Execute these ONE AT A TIME. Do NOT start the next slice until the current one is verified:

| Slice | Order | Handoff Route |
|:---|:---|:---|
| **Slice 1** — Foundation (Colors + Font + Theme) | `[BLOCKING]` Run FIRST | Plan → Build |
| **Slice 2** — Core Primitives (Button, Card, ProgressBar) | `[SEQUENTIAL]` After Slice 1 | Plan → Build |
| **Slice 3** — Supporting Primitives (Chip, Avatar, Switch, Dialog) | `[SEQUENTIAL]` After Slice 2 | Plan → Build |
| **Slice 4** — Shared Widget Reskin (13 files) | `[SEQUENTIAL]` After Slice 3 | Plan → Build |
| **Slice 5** — Auth + Dashboard + Profile screens | `[SEQUENTIAL]` After Slice 4 | Plan → Build |
| **Slice 6** — Audit + Programs screens | `[PARALLEL]` With Slice 5 | Plan → Build |
| **Slice 7** — Admin + Analytics + Stores screens | `[PARALLEL]` With Slice 5 | Plan → Build |
| **Slice 8** — Templates + ActionPlans + Notifications screens | `[PARALLEL]` With Slice 5 | Plan → Build |

**Epic Plan**: `C:\Users\HP\Documents\GitHub\Checkly\docs\architecture\duolingo_reskin\analysis_epic_20260521_202100_ds01_duolingo_reskin.md`
