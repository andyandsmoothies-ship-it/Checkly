# Research: PWA-to-Flutter Parity Fine-Tuning Guide

> **Role**: Senior Architect
> **Date**: 2026-03-11
> **Scope**: Screen-by-screen comparison of original PWA vs new Flutter app
> **Goal**: Ensure the Flutter app matches the original PWA as exactly as possible

## Context & References

| Source | What |
|--------|------|
| Original PWA | `C:\Users\HP\Documents\GitHub\checkly-smart\src\` |
| Live PWA | https://checkly-smart.lovable.app/ |
| Flutter App | `C:\Users\HP\Documents\GitHub\Checkly\lib\` |
| Builder's gap analysis | [analysis_original_pwa.md](file:///C:/Users/HP/.gemini/antigravity/brain/2653279f-659a-487a-9f3c-bfe41a3b674d/analysis_original_pwa.md) |

---

## Live PWA Screenshots

````carousel
![Dashboard — "Mission Control" with Monthly Plan Progress gauge, per-template Activity/Weak Stores cards, and notification bell](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/dashboard_home_1773217723554.png)
<!-- slide -->
![Audit Form — Sticky score HUD (322/322 100.0%), section progress (27/27), FAULTS/REPEAT steppers, CCP/RISK toggles, NOTE/PHOTO bar](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/audit_form_detail_1773217821365.png)
<!-- slide -->
![Audits List — Grouped by location, with expandable store rows and audit cards](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/audits_page_1773217755436.png)
<!-- slide -->
![Action Plans — Status filter chips (All/Open/Verify/Done), grouped by store with count badges](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/actions_page_1773217765785.png)
<!-- slide -->
![Templates — Template cards grouped by category with icons](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/templates_page_1773217789415.png)
````

![Recorded walkthrough of the live PWA showing navigation between all 5 tabs](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/pwa_dashboard_capture_1773217684762.webp)

---

## 1. Navigation Structure

### PWA (Source of Truth)

**5 bottom tabs**: HOME | AUDITS | ACTIONS | TEMPLATES | PROFILE

- Active tab: blue icon + dot indicator above label
- Notification bell in top-right header (red badge with count "9+")
- FAB (Floating Action Button) "+" on dashboard for quick audit start

### Flutter (Current State)

**8 routes** via GoRouter, but **no bottom navigation bar yet**. Routes: `/login`, `/home`, `/templates`, `/templates/:id`, `/stores/select`, `/audit`, `/history`

### Gap & Fix

| Gap | Priority | Fix |
|-----|----------|-----|
| No bottom nav bar | 🔴 P0 | Add `BottomNavigationBar` with 5 tabs matching PWA exactly |
| No notification bell in app bar | 🟡 P1 | Add notification icon with unread badge count |
| No FAB on dashboard | 🟡 P1 | Add FloatingActionButton for "Start Audit" |
| Missing `/actions` route | 🔴 P0 | Add action plans list page with route |
| Missing `/profile` route | 🔴 P0 | Add profile page with route |

---

## 2. Dashboard (HOME tab)

### PWA Pattern (from [Index.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/pages/Index.tsx))

| Element | Detail |
|---------|--------|
| **Header** | "Mission Control" title + user role subtitle + notification bell |
| **Hero Card** | Blue gradient card with "MONTHLY PLAN PROGRESS", circular gauge (0-100%), COMPLETED / TOTAL counts |
| **Per-Template Sections** | For each template category (Quality Control, Training Assessment): section header with colored left bar + "VIEW ALL >" link, two stat cards: ACTIVITY (pending count) + WEAK STORES (scoring < 80%) |
| **FAB** | Blue circular "+" button in bottom-right |

### Flutter Current State

`DashboardManager.loadStats()` reads from Drift cache (audit count, avg score, pending APs, unread notifications). **No hero card, no per-template breakdown, no circular gauge.**

### Spec for Builder

```
Dashboard Page must have:
1. AppBar: "Mission Control" centered, notification bell icon (right) with unread badge
2. Hero Card (blue gradient):
   - Title: "MONTHLY PLAN PROGRESS" (white, uppercase, tracking-wide)
   - Circular progress indicator (percentage inside)
   - Bottom row: COMPLETED count | TOTAL count
3. Per-template sections (from cached templates):
   - Section header: colored bar (left) + template category name (uppercase bold) + "VIEW ALL >"
   - Two cards side-by-side: ACTIVITY (pending) + WEAK STORES (score < 80%)
4. FAB: blue circle with "+" icon → navigates to audit start flow
```

---

## 3. Audit Form (Core Screen)

### PWA Pattern (from [AuditForm.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/pages/AuditForm.tsx) + [CriteriaCard.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/components/audit/CriteriaCard.tsx))

#### Top Bar (Sticky)
| Element | Detail |
|---------|--------|
| Section name | Current section title (e.g., "H – HOSPITALITY"), uppercase, bold |
| Progress bar | Blue linear bar + "27/27" text (answered/total) |
| Score badge | Pill shape, top-right: "POINTS 322/322 100.0%" |
| Close button | X icon to exit audit |

#### Criteria Card (per criterion)
| Element | Detail |
|---------|--------|
| **Label** | Bold, e.g., "H1" with sub-label below in Vietnamese |
| **Description** | Grey text, 2-line clamp (tap to expand) |
| **FAULTS stepper** | `[–] 0 [+]` with ⚠️ icon, turns red when > 0 |
| **REPEAT stepper** | `[–] 0 [+]` with 🔄 icon, turns amber when > 0 |
| **CCP toggle** | Pill button: grey default → red active (with pulse animation) |
| **RISK toggle** | Pill button: grey default → amber active (with pulse animation) |
| **Confirm Pass** | Full-width green button: "✓ Standard Verified" when confirmed |
| **NOTE action** | Bottom bar: 💬 NOTE label, toggles textarea |
| **PHOTO action** | Bottom bar: 📷 PHOTO label, max 3 photos, shows "Photo (2/3)" |
| **Photo grid** | 80×80 thumbnails with delete overlay on hover |
| **Required Info** | Red pulsing "REQUIRED INFO" text when faults > 0 but no note |
| **Card border** | Dashed when unanswered, green border when pass, red border when faulty |

#### Section Navigation
| Element | Detail |
|---------|--------|
| Section prev/next | `[<] [>]` buttons at bottom to navigate between sections |
| Section selector | Quick-jump overlay (grid FAB button in bottom-right) |

### Flutter Current State

`AuditManager` has answer tracking and live scoring. `audit_form_page.dart` has basic section cards and inputs. **But lacks the precise CriteriaCard UI pattern.**

### Spec for Builder

```
CriteriaCard widget must replicate EXACTLY:
1. Layout: Card with conditional border (dashed=unanswered, green=pass, red=faulty)
2. Header row: criterion code (bold) + CCP/RISK badges (tiny, destructive/warning)
3. Description: grey text, line-clamp-2 with tap-to-expand
4. FAULTS stepper: grid row 1, col 1 — [-] value [+] with warning icon
5. REPEAT stepper: grid row 1, col 2 — [-] value [+] with rotate icon
6. Confirm Pass button: full-width, green when active, grey when default
   - Text: "Standard Verified" (active) / "Confirm Correct" (default)
   - Disabled when faults > 0 or CCP or RISK active
7. CCP/RISK toggles: two half-width pill buttons, side-by-side
   - CCP: red background + pulse when active
   - RISK: amber background + pulse when active
8. Bottom bar: NOTE (💬) + PHOTO (📷) toggle buttons
   - Photo shows count: "Photo (2/3)", max 3
   - "REQUIRED INFO" red pulse when faulty but no note
9. Note textarea: appears below when NOTE tapped, rounded, blue tint
10. Photo grid: 80x80 thumbnails with delete button overlay
```

---

## 4. Audits List (AUDITS tab)

### PWA Pattern (from [Audits.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/pages/Audits.tsx))

| Element | Detail |
|---------|--------|
| Header | "Inspections" title + notification bell |
| Search bar | "Search stores or audits..." |
| Status filters | Chip row: Todo, Doing, Submitted, Overdue (each with count) |
| Grouping | Grouped by store (collapsible), store name uppercase bold + audit count |
| Audit card | Store name, template name, date, score circle (color-coded), status badge |

### Flutter Current State

`HistoryManager` + `history_page.dart` with pull-to-refresh. **No search, no status filters, no grouping by store.**

### Spec for Builder

```
History/Audits page:
1. Search bar at top
2. Filter chips: All | Todo | Doing | Submitted | Overdue (with counts)
3. List grouped by store (collapsible ExpansionTile)
4. AuditCard:
   - Store name + template name
   - Date (formatted)
   - Score circle (green ≥80%, amber ≥60%, red <60%)
   - Status badge (chip)
```

---

## 5. Action Plans (ACTIONS tab)

### PWA Pattern (from [Actions.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/pages/Actions.tsx))

| Element | Detail |
|---------|--------|
| Header | "Action Plans" + subtitle "Address and track non-conformities" |
| Search | "Search by issue or store..." |
| Filters | Chip row: All (55), Open (55), Verify (0), Done (0) |
| Grouping | By store name (uppercase bold) + count |
| Detail view | Action plan card with: criteria label, section, status timeline (Open → Pending Verify → Closed), root cause field, correction plan field, evidence photos, deadline |

### Flutter Current State

`ActionPlanManager` exists with state machine (submitEvidence, closePlan, rejectEvidence). **No list page, no detail page, no UI at all.**

### Spec for Builder

```
Action Plans pages:
1. List page:
   - Search bar
   - Filter chips: All | Open | Verify | Done (with counts)
   - Grouped by store (collapsible)
   - ActionPlanCard: criteria label, status badge, deadline, overdue indicator
2. Detail page:
   - Status timeline (vertical, 3 steps: Open → Pending Verify → Closed)
   - Info section: criteria label, section title, store name
   - Root cause field (text input if editable)
   - Correction plan field
   - Evidence photo upload (max 3)
   - Evidence note textarea
   - Action buttons: role-aware (SM: "Submit Evidence", Auditor: "Verify"/"Reject")
```

---

## 6. Profile (PROFILE tab)

### PWA Pattern (from [Profile.tsx](file:///C:/Users/HP/Documents/GitHub/checkly-smart/src/pages/Profile.tsx))

| Element | Detail |
|---------|--------|
| **Header** | "Profile" + "Your account settings" |
| **Profile card** | Avatar circle (initials), full name (bold), email, role badge (color-coded: admin=red, auditor=blue, SM=green, AM=amber) |
| **Stats row** | 3 columns: My Audits count, Avg Score %, This Month count (labels are role-aware) |
| **Menu items** | Role-conditional list: Admin Dashboard (admin only), My Region (AM), My Store (SM), My Activity (all), Notifications, Help |
| **Theme selector** | Light/Dark toggle with Sun/Moon icons |
| **Sign out** | Full-width red outline button at bottom |
| **Version** | "UDAT Platform v1.0.0" centered at bottom |

### Flutter Current State

**No profile page exists.** `ThemeManager` handles dark mode persistence.

### Spec for Builder

```
Profile page:
1. Profile card:
   - Circle avatar with initials (2 chars)
   - Full name (24px bold), email (12px muted), role badge (colored chip)
2. Stats row (3 columns): Audits | Avg Score | This Month
   - Labels change per role (auditor: "My Audits", SM: "Store Audits", etc.)
3. Menu items: cards with icon + label + description + chevron
   - Conditional on role (admin gets Admin Dashboard, AM gets My Region, etc.)
4. Theme toggle: Light/Dark icon buttons
5. Sign Out button: full width, red outline, uppercase
6. Version text at bottom
```

---

## 7. Templates (TEMPLATES tab)

### PWA Pattern

Grouped by category (Quality Control, Training, Operations etc.) with template cards showing name, description, and criteria count.

### Flutter Current State

`TemplateListPage` + `TemplateDetailPage` exist. **Basic list, no category grouping.**

### Spec for Builder

```
Templates page:
1. Group templates by category
2. CategorySection header: icon + category name (uppercase)
3. TemplateCard: name, description preview, criteria count badge
```

---

## 8. Prioritized Gap Summary

### 🔴 P0 — Structural (Must fix for app to be usable)

| # | Gap | Effort |
|---|-----|--------|
| 1 | **Bottom Navigation Bar** (5 tabs) | Small — add `Scaffold.bottomNavigationBar` |
| 2 | **Profile page** (role-aware menu, stats, theme, logout) | Medium |
| 3 | **Action Plans list + detail pages** (UI only, manager exists) | Medium |
| 4 | **CriteriaCard redesign** (FAULTS/REPEAT steppers, CCP/RISK toggles, NOTE/PHOTO, confirm pass) | Large — most critical visual gap |

### 🟡 P1 — UX Parity (Matches PWA experience)

| # | Gap | Effort |
|---|-----|--------|
| 5 | **Dashboard hero card** (monthly progress gauge, per-template breakdown) | Medium |
| 6 | **Audits list** (search, status filters, grouped by store) | Medium |
| 7 | **Notification bell** in app bar with unread badge | Small |
| 8 | **Section quick-jump** overlay in audit form | Small |
| 9 | **Section prev/next navigation** in audit form | Small |

### 🟢 P2 — Polish (Nice to have)

| # | Gap | Effort |
|---|-----|--------|
| 10 | **FAB** on dashboard | Small |
| 11 | **Card border states** (dashed/green/red on criteria) | Small |
| 12 | **Pulse animations** on CCP/RISK active state | Small |
| 13 | **Photo thumbnail grid** with delete overlay | Small |
| 14 | **"Required Info"** pulsing text on faulty-no-note criteria | Small |

### 🟠 P1.5 — Full Feature Parity (all PWA features must be ported)

| # | Gap | Effort |
|---|-----|--------|
| 15 | Admin Dashboard (user management, audit approvals) | Large |
| 16 | Analytics page (charts, averages by region) | Medium |
| 17 | Template Builder | Large |
| 18 | Store Dashboard (detailed store page) | Medium |
| 19 | Activity History page | Small |
| 20 | Audit Approval workflow (admin approve/reject) | Medium |

---

## 9. Implementation Plan (Priority-Ordered Batches)

> [!IMPORTANT]
> Do NOT hand all batches at once. Hand one batch per builder session. Priority order is mandatory — each batch depends on the previous one being stable.

### Batch 1: 🔴 Fix Broken Core (Backend + Flutter)

**Why first**: Without S1, action plans never get created. Without the CriteriaCard, auditors can't do their job. The app is **non-functional** without this batch.

| Item | Layer | What |
|------|-------|------|
| **S1** | Backend | Auto-create action plans in `CreateSubmission.cs` for each `value='fail'` answer |
| **S2** | Backend | Generate notifications on AP status change in `UpdateActionPlan.cs` |
| **S3** | Backend | Generate notification to SM on audit submission in `CreateSubmission.cs` |
| **Slice B** | Flutter | CriteriaCard redesign (FAULTS/REPEAT steppers, CCP/RISK, NOTE/PHOTO, confirm pass) |
| **C1** | Flutter | Overdue audit blocking (full-screen block if `scheduled_at < today`) |

**Tell the builder**: *"Do Batch 1 from the research doc. Backend rules S1-S3 first, then CriteriaCard + overdue blocking."*

---

### Batch 2: 🔴 App Shell + Navigation

**Why second**: Users can't navigate the app without bottom nav. Profile page is the logout path.

| Item | Layer | What |
|------|-------|------|
| **Slice A** | Flutter | Bottom navigation bar (5 tabs: Home, Audits, Actions, Templates, Profile) |
| **Profile** | Flutter | Profile page (role-aware menu, stats row, theme toggle, sign out) |
| **Routes** | Flutter | Add `/actions`, `/profile` routes to GoRouter |

**Tell the builder**: *"Do Batch 2. Add bottom nav bar with 5 tabs matching PWA, profile page, and missing routes."*

---

### Batch 3: 🟡 Action Plans + Audits List

**Why third**: With S1 now creating APs and S2 sending notifications, users need the UI to see and manage them.

| Item | Layer | What |
|------|-------|------|
| **Slice C** | Flutter | Action plans list page (search, filter chips, grouped by store) + detail page (timeline, evidence, role-aware buttons) |
| **Slice D** | Flutter | Audits list redesign (search, status filters, grouped by store, score circle) |
| **C6** | Flutter | Dashboard metrics formulas (per-role KPIs: openAPs, weakStores, nearestDeadline) |

**Tell the builder**: *"Do Batch 3. Action plans list+detail pages, audits list redesign with filters, and dashboard metrics."*

---

### Batch 4: 🟡 Dashboard + Notifications + Enforcement

**Why fourth**: Dashboard is the landing page — needs hero card. Notifications complete the feedback loop.

| Item | Layer | What |
|------|-------|------|
| **Dashboard** | Flutter | Hero card (monthly progress gauge), per-template sections (Activity + Weak Stores) |
| **Slice E** | Flutter | Notification bell in app bar with unread badge |
| **S4** | Backend | Review disposition endpoints (admin approve/reject audits) |
| **S9+S10** | Backend | 1-SM-per-store + 1-AM-per-area enforcement in user registration |
| **C7** | Backend | Role-based data filtering on all list endpoints |

**Tell the builder**: *"Do Batch 4. Dashboard hero card, notification bell, review endpoints, and assignment enforcement."*

---

### Batch 5: 🟢 Admin Features

**Why fifth**: Admin-tier features that only the admin user needs.

| Item | Layer | What |
|------|-------|------|
| **S11** | Backend | Admin user CRUD endpoints (create/update/ban with role) |
| **S8** | Backend | SM transfer protocol (atomic swap + AP reassignment) |
| **S12** | Backend | System logging (audit trail for admin actions) |
| **Slice F** | Flutter | Admin dashboard page + audit approval UI |
| **Activity** | Flutter | Activity history page |

**Tell the builder**: *"Do Batch 5. Admin CRUD endpoints, SM transfer, audit trail, admin dashboard + activity history pages."*

---

### Batch 6: 🟢 Analytics + Polish + Edge Cases

**Why last**: These are polish items and advanced features that can ship after core is stable.

| Item | Layer | What |
|------|-------|------|
| **Slice G** | Flutter | Analytics page (charts, avg scores by region) |
| **Template Builder** | Flutter | Template builder page |
| **Store Dashboard** | Flutter | Detailed store page |
| **S5** | Backend | Score verification kill switch (config-driven observe/enforce) |
| **S6+S7** | Backend | Deadline + schedule reminders (background hosted service) |
| **C2** | Flutter | App lifecycle manager (4-tier session recovery) |
| **C3+C4** | Flutter | Progressive repeat penalty + criteria `minus_impact` override |
| **C8** | Flutter | Rejected audit exclusion from metrics |
| **Polish** | Flutter | FAB, card border states, pulse animations, photo grid, "Required Info" text |

**Tell the builder**: *"Do Batch 6. Analytics, template builder, store dashboard, reminders, lifecycle manager, and all polish items."*

---

## 10. Business Rules Parity Audit

> [!CAUTION]
> These are **server-side and client-side business rules** from the original Supabase triggers/functions/RPC that have NOT been replicated in the new ASP.NET + Flutter stack. The app may look right but **behave wrong** without these.

### Source Documents
- [CORE_WORKFLOWS.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/reference/CORE_WORKFLOWS.md) — Lifecycles, notifications, sync
- [SCORING_LOGIC.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/reference/SCORING_LOGIC.md) — Scoring, CCP/RISK, assignments
- [standards.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/reference/standards.md) — Architecture, security

### 🔴 MISSING Server-Side Rules (ASP.NET Backend)

| # | Rule | Original (Supabase) | Impact |
|---|------|---------------------|--------|
| **S1** | **Auto-create APs on submission** | `handle_submission_completion` trigger: 1 AP per `value='fail'`, deadline = NOW + N days | APs never created |
| **S2** | **Notification on AP status change** | `handle_action_plan_status_change` trigger → notifies SM/AM/Auditor | Status changes invisible |
| **S3** | **Notification on audit submit** | `handle_submission_completion` → notifies SM | SM unaware of audits |
| **S4** | **Review disposition endpoints** | `review_status`: admin flag/approve/reject | Can't approve/reject |
| **S5** | **Score verification kill switch** | Vault `score_verification_mode` (observe/enforce) | Can't disable temporarily |
| **S6** | **Deadline reminders** | `send_deadline_reminders()` pg_cron daily 1:00 AM | SM never reminded |
| **S7** | **Schedule reminders** | `send_schedule_reminders()` pg_cron daily 1:05 AM | Auditor never reminded |
| **S8** | **SM transfer protocol** | `transfer_store_manager()` RPC: atomic swap + AP reassignment | Can't transfer SMs |
| **S9** | **1 SM per store** | Edge function checks for existing SM on store | Duplicate SMs |
| **S10** | **1 AM per area** | Edge function checks for existing AM on area | Duplicate AMs |
| **S11** | **Admin user CRUD** | `admin-api` Edge Function: create/ban/update with role | No admin panel |
| **S12** | **System logging** | `system_logs` table for admin audit trail | No audit trail |

### 🟡 MISSING Client-Side Rules (Flutter App)

| # | Rule | Original (PWA) | Impact |
|---|------|----------------|--------|
| **C1** | **Overdue audit blocking** | `isAuditOverdue()` → full-screen block | Overdue audits startable |
| **C2** | **App lifecycle manager** | 4-tier recovery (0=skip → 3=re-login) | No session recovery |
| **C3** | **Progressive repeat penalty** | `n² × minusPerFault` when enabled | May score wrong |
| **C4** | **Criteria `minus_impact` override** | Per-criteria override of subsection rate | May deduct wrong |
| **C5** | **Draft auto-save** | Saves answers to persistent storage on change | May lose drafts |
| **C6** | **Dashboard metrics** | Per-role KPIs: openAPs, overdueAPs, weakStores | Wrong dashboard |
| **C7** | **Role-based filtering** | RLS: SM=own store, AM=own area | Data leak risk |
| **C8** | **Rejected audit exclusion** | `review_status='rejected'` excluded from metrics | Bad averages |

### ✅ Already Implemented

Score verification, idempotency, Dart scoring engine (CCP/RISK/MaxDeductionPoints), JWT auth, GPS capture, offline outbox + SyncEngine, photo upload, snapshot fields, `flutter_secure_storage`.

### Priority Matrix

| Priority | Rules | Why |
|----------|-------|-----|
| 🔴 **P0** | S1, S2, C1, C6 | Core workflows fail silently |
| 🟡 **P1** | S3, S4, S9, S10, C2, C7 | Features misbehave |
| 🟢 **P2** | S5-S8, S11, S12, C3, C4, C8 | Admin-tier + edge cases |

---

## 11. Admin & Advanced Page Specs (Batch 5-6 Reference)

> Screenshots captured from live PWA at https://checkly-smart.lovable.app/ on 2026-03-11.

### 11.1 Admin Dashboard

![Admin Dashboard — 4 stat cards + 5 navigation menu items](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/admin_dashboard_page_1773227536559.png)

```
Admin Dashboard page:
1. Header: "Admin Dashboard" + subtitle "System management" + notification bell
2. Stats grid (2x2): USERS count | STORES count | TEMPLATES count | PENDING count
   - Each card: icon + count + label (uppercase)
   - First card (USERS) has blue filled background
3. Menu items (vertical list, 5 items):
   - User Management — "Manage auditors & managers" (people icon)
   - Store Management — "Manage store locations" (building icon)
   - Audit Approvals — "Review submitted audits" (clipboard icon)
   - System Logs — "Monitor application errors" (alert icon)
   - Analytics — "View performance data" (chart icon)
```

### 11.2 Audit Approvals

![Audit Approvals — Tab-based view with Pending/Approved/Rejected](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/audit_approvals_page_1773227546903.png)

```
Audit Approvals page:
1. Header: "Audit Approvals" + back button
2. Tab bar: Pending | Approved | Rejected (with counts)
3. Search bar: "Search audits..."
4. Audit cards: store name, template name, date, score badge, status
5. Actions per card: Approve (green) | Reject (red) buttons
```

### 11.3 User Management

![User Management — Role filters + user cards with status](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/user_management_page_1773227561973.png)

```
User Management page:
1. Header: "User Management" + "Add User" button (top-right)
2. Role filter chips: All | Admin | Auditor | SM | AM
3. User cards: avatar (initials circle), full name, email, role badge
   - Disabled users shown with "disabled" badge
4. Card tap → edit dialog (role, store/area assignment, enable/disable)
```

### 11.4 Store Management

![Store Management — Store cards with SM/AM assignments](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/store_management_page_1773227578612.png)

```
Store Management page:
1. Header: "Store Management" + "Add Store" button
2. Search bar: "Search stores..."
3. Store cards: store name (bold), address, area/region badge
   - Shows assigned SM name + AM name
   - Date added
4. Card tap → edit dialog (name, address, area, SM assignment with transfer protocol)
```

### 11.5 System Logs

![System Logs — Table view with Level/Category filters](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/system_logs_page_1773227602871.png)

```
System Logs page:
1. Header: "System Logs" + back button
2. Filter row: Level dropdown (All/Info/Error/Warning) + Category dropdown
3. Log table: Timestamp | Level (color-coded badge) | Category | Message | Path | User
4. Pagination at bottom
```

### 11.6 Analytics

![Analytics — KPI cards + 6-month score trend with target line](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/analytics_page_1773227630373.png)

```
Analytics page:
1. Header: "Analytics" + subtitle "Organization health overview"
2. Filter bar: Store dropdown | Area dropdown | Type dropdown | Date range picker | Clear
3. KPI cards (3x2 grid):
   - COMPLIANCE: "X% — N of M stores ≥80%"
   - VELOCITY: "N — Completed MTD" (blue filled background)
   - GAPS: "N — Stores with 0 audits"
   - OVERDUE APs: "N — N open total"
   - OVERDUE AUDITS: "N — Scheduled past due"
4. Chart: "Organization Score Trend (6 Months)"
   - Line chart: blue line = Avg Score, green dashed = Target (85%)
   - X-axis: months, Y-axis: 0-100
   - Tooltip on hover: month name, avg score, target
5. Filters update all cards + chart dynamically
```

### 11.7 Template Builder

![Template Builder — Metadata, scoring rules, AP rules, sections](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/template_builder_page_1773227680566.png)

```
Template Builder page:
1. Header: "Edit Template" + back button
2. Metadata section:
   - Template Title (text input)
   - Description (textarea)
   - Template Type (dropdown: Quality Control, Training, etc.)
3. Scoring Rules section (toggle switches):
   - CCP Override: "Any criteria marked CCP that fails will zero out its entire section"
   - RISK Override: "Any criteria marked RISK that fails will zero out the entire audit"
   - Weighted Density: "Each section contributes based on assigned weight (must sum to 100%)"
   - Confirm Correct: "Auditor must tap Correct to confirm each passing criteria"
   - Progressive Repeat Penalty: "OFF: deduction = repeats × rate. ON: deduction = repeats² × rate"
4. Action Plan Rules:
   - Deadline: "N days" input
   - Deadline Reminder: "before N days" input
5. Footer bar: "322 PTS" badge + "100.0%" badge + "SAVE TEMPLATE" button
6. Sections list:
   - Each section: drag handle + section name + weight% badge + "XS + YC" count + delete + expand
   - "+ Add Section" button
   - Expand → subsections and criteria within
```

### 11.8 Walkthrough Recording

![Full admin navigation walkthrough](C:/Users/HP/.gemini/antigravity/brain/a5535011-f330-4ba9-91c5-fd83a11be81b/admin_pages_capture_1773227514415.webp)
