# Implementation Plan - Duolingo UI Reskin Slice 5 (Auth, Dashboard, Profile Screens)

Reskin the primary system user-interface pages (Login, Access Pending, Dashboard, Profile, and Activity History) to embody the high-contrast, playful Duolingo gamified style.

## 1. Proposed Changes

### A. Authentication Module (`lib/features/auth/`)
1. **`LoginPage` (`login_page.dart`)**:
   - Apply vibrant styling to text form fields (2px `AppColors.swan` border, turning `AppColors.macaw` blue on focus; rounded corners `BorderRadius.circular(12)`).
   - Swap the default login `ElevatedButton` with `BubblyButton(label: 'Sign In', color: AppColors.macaw, onPressed: _onLogin)`.
   - Brand header styling: Use `AppColors.macaw` for the brand color and Nunito Display for titles.
   - Restyle Forgot Password dialog to use `BubblyDialog` style.
2. **`AccessPendingPage` (`access_pending_page.dart`)**:
   - Restyle the hourglass container with high-contrast, flat borders.
   - Swap the sign-out button with `BubblyButton(label: 'Sign Out', color: AppColors.swan, onPressed: ...)` or custom flat outline.

### B. Dashboard Module (`lib/features/dashboard/`)
1. **`DashboardPage` (`dashboard_page.dart`)**:
   - Restyle `Greeting` header text using Nunito Display bold style.
2. **`HeroCard` (`widgets/hero_card.dart`)**:
   - Wrap in `StrokeCard` to enforce zero elevation and a flat 2px Swan border.
   - Set background color to flat pastel (e.g. light macaw blue or pastel red for urgent plans).
3. **`SubmissionRow` (`widgets/submission_row.dart`)**:
   - Swap the complex `Container`/`Material`/`InkWell` block with `StrokeCard(onTap: ..., child: ...)` to guarantee consistency across the feed.
   - Style text fields and popups cleanly.
4. **`CompactStatusPanel` (`_shared/widgets/compact_status_panel.dart`)**:
   - Swap `Card` with `StrokeCard(padding: EdgeInsets.zero, child: ...)` so all KPIs align with the flat border-stroke style.

### C. Profile Module (`lib/features/profile/`)
1. **`ProfilePage` (`profile_page.dart`)**:
   - The settings zone contains standard `Card` widgets which must be swapped/wrapped in `StrokeCard` to satisfy test expectations and keep visual styling consistent.
2. **`ProfileIdentityCard` (`widgets/profile_header.dart`)**:
   - Align background gradient/styling with the Duolingo theme.
   - In `_buildAvatar`, style the `CircleAvatar` to match the exact role-to-color mapping used in `PastelAvatar` (e.g., green for Auditor, canary yellow for Store Manager) and apply a 2px high-contrast border wrapper. This retains the `CircleAvatar` type for the widget tests while updating the visuals perfectly.
3. **`ActivityHistoryPage` (`pages/activity_history_page.dart`)**:
   - Apply clean background list styling and reskin the lists with StrokeCard elements.

---

## 2. Risk & Impact Analysis
- **Blast Radius**: Low. The edits are restricted purely to UI build functions and styles. No network requests, database hooks, or capability validation guards (`ActionGuard`, `PermissionGuard`) are altered.
- **Widget Test Compatibility**: The `ProfilePage` widget tests check for the presence of `CircleAvatar` and at least two `Card` widgets. Our implementation retains both constraints perfectly (wrapping the `CircleAvatar` with custom borders, and using `StrokeCard` which inherits from `Card`).

---

## 3. Verification Plan
- **Automated Verification**:
  - Run the existing test suite: `rtk flutter test test/features/profile/pages/profile_page_test.dart` to confirm that all visual assertions and layout checks continue to pass without regression.
  - Run the global test suite: `rtk flutter test` to ensure zero regression across the application.
- **Manual Verification**:
  - Confirm the tactile animation on buttons and the high-contrast flat stroke borders on inputs and cards render correctly on the screen.
