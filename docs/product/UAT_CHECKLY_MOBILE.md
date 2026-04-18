# Checkly Mobile — Comprehensive UAT Test Suite
> **Version**: 4.1 (Post Dashboard UI Polish) | **Date**: 2026-03-25 | **Platform**: Android (APK)
> **Pre-requisite**: Server running on local LAN IP, device connected via USB/Wi-Fi.

Master User Acceptance Testing (UAT) document for the Checkly Mobile application. Covers 15 core modules and 155+ test cases.

---

## Module 1: Authentication & Role Authorization
**Focus**: Login, JWT storage, and Permission-Based Access Control (PBAC).

> **PBAC Note**: As of Slice 6, UI checks and GoRouter redirects are driven by `PolicyManager.can(capability)` rather than hard-coded `role == 'admin'` checks. Ensure testing validates capability-driven behavior.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 1.1 | Valid Auditor Login | Enter valid Auditor credentials → Tap Login | Navigates to Dashboard. Profile shows Auditor role. | [ ] |
| 1.2 | Invalid Login | Enter wrong password → Tap Login | Shows "Invalid credentials" error. | [ ] |
| 1.3 | Admin Role Limits | Login as Admin | Cannot execute audits. Sees all stores & templates. | [ ] |
| 1.4 | Store Manager (SM) Access | Login as SM | Dashboard shows only their assigned store's data. | [ ] |
| 1.5 | Area Manager (AM) Access | Login as AM | Dashboard shows only stores in their assigned Area. | [ ] |
| 1.6 | Offline Login Fallback | Turn on Airplane mode → Force close → Open app | App bypasses login shell, restores last cached session. | [ ] |
| 1.7 | JWT Expiry Handling | Wait for JWT expiry (or simulate) → Perform action | App seamlessly refreshes token via server. | [ ] |

## Module 2: App Navigation & Shell
**Focus**: Bottom navigation, routing, and UI responsiveness.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 2.1 | Bottom Nav Switching | Tap through Home, Audits, Action Plans, Profile | Instant switching. Active state highlighted. | [ ] |
| 2.2 | Keyboard Padding | Focus a text input on a deeply scrolled page | UI scrolls up so input is not hidden by keyboard. | [ ] |
| 2.3 | Global Scroll Restoration | Scroll down a list → Navigate away → Go back | List restores exact scroll position. | [ ] |
| 2.4 | Capability Route Guard | Login as Auditor → Navigate to `/admin/dashboard` | Redirected to `/home`. Admin pages are not accessible (missing `admin:access` capability). | [ ] |
| 2.5 | Access Pending Redirect | Login as user with no role assigned | Redirected to Access Pending page, not Dashboard. | [ ] |
| 2.6 | Admin Nav Items | Login as Admin → Open Admin Dashboard | All 5 menu items (Users, Stores, Approvals, Logs, Areas) navigate correctly. | [ ] |

## Module 3: Store & Area Selector
**Focus**: Selecting the audit context (Areas Entity).

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 3.1 | Area Name Display | Open Store Selector | Stores display assigned **Area Name** (not area_code). | [ ] |
| 3.2 | Store Search | Type "Hà Nội" in search bar | Real-time filtering shows matching stores. | [ ] |
| 3.3 | Null Area Handling | View a store with no assigned Area | Shows only Address. Does not crash or show "null". | [ ] |

## Module 4: Template Selection & Initialization
**Focus**: Template loading, caching, and scoring mode awareness.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 4.1 | Template List (Admin) | Login as Admin → Tap "Start Audit" | Shows **all** `IsActive=true` templates regardless of assignments. | [ ] |
| 4.2 | Template List (Auditor, Unassigned) | Login as Auditor (no group) → Tap "Start Audit" | Shows only unassigned (global) templates. Assigned templates hidden. | [ ] |
| 4.3 | Template List (Auditor, In Group) | Login as Auditor in "QC Team" group → Tap "Start Audit" | Shows unassigned templates + templates assigned to "QC Team". | [ ] |
| 4.4 | Inactive Templates | Admin deactivates a template on server → Pull to refresh | Template disappears from New Audit list. | [ ] |
| 4.5 | Penalty Audit Init | Select a **Penalty** template → Select Store | Audit form loads with **100%** initial score. | [ ] |
| 4.6 | Accumulation Audit Init | Select an **Accumulation** template → Select Store | Audit form loads with **0%** initial score. | [ ] |
| 4.7 | Checklist Audit Init | Select a **Checklist** template → Select Store | Audit form loads with **100%** initial score. | [ ] |
| 4.8 | Survey Audit Init | Select a **Survey** template → Select Store | Audit form loads with no score display (survey mode). | [ ] |
| 4.9 | New Template Route | Navigate to `/templates/new` | Opens Template Builder with empty template (no crash). | [ ] |

## Module 5: Template Builder (Admin)
**Focus**: Creating and editing templates with the Generic Builder. **NEW in v2.0.**

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 5.1 | Create Template | Fill in name, type, description → Add 2 sections → Save | Template saved. Appears in template list. | [ ] |
| 5.2 | Scoring Mode Dropdown | Open Scoring Rules → Change dropdown | Options: Penalty, Accumulation, Checklist, Survey. Selection saved. | [ ] |
| 5.3 | Weighted Density Toggle | Set mode to Penalty → Toggle Weighted Density | Section weight fields appear. Sum must = 100%. | [ ] |
| 5.4 | Weighted Density Hidden | Set mode to Checklist | Weighted Density toggle is hidden. | [ ] |
| 5.5 | Layout Locking — Flat | Add a criterion to an empty section | "Add Sub-Section" button disappears. Section locked to flat. | [ ] |
| 5.6 | Layout Locking — Nested | Add a sub-section to an empty section | "Add Criteria" button at section level disappears. Locked to nested. | [ ] |
| 5.7 | Input Type — Fault Count | Add criterion → Input Type defaults to "Fault Count" | Points Weight field is editable. | [ ] |
| 5.8 | Input Type — Pass/Fail | Add criterion → Change to "Pass / Fail" | Points Weight field is editable. | [ ] |
| 5.9 | Input Type — Scored Choices | Add criterion → Change to "Scored Choices" | Scale Options editor appears. Points Weight auto-calculated. | [ ] |
| 5.10 | Scale Options Editor | Add 4 options (Poor=0, Fair=2, Good=5, Excellent=10) | Options saved. Points Weight auto-set to 10. | [ ] |
| 5.11 | Scored Choices Validation | Set input type to Scored Choices → Try to save with 0 or 1 options | Save blocked with SnackBar error: min 2 options. | [ ] |
| 5.12 | CCP/RISK Badges | Enable CCP on a criterion → Collapse | CCP badge visible on collapsed row. | [ ] |
| 5.13 | Edit Existing Template | Open saved template → Modify name → Save | Changes persisted. Score rules and criteria intact. | [ ] |
| 5.14 | Dirty State — Text Edit | Edit template title → Tap Back | "Discard changes?" dialog appears. | [ ] |
| 5.15 | Dirty State — Structural | Add a section or criterion → Tap Back | "Discard changes?" dialog appears. | [ ] |
| 5.16 | Dirty State — Clean Exit | Open existing template (no edits) → Tap Back | Navigates back immediately. No dialog. | [ ] |
| 5.17 | Dirty State — Save Clears | Edit title → Save → Tap Back | Navigates back immediately (dirty cleared on save). | [ ] |
| 5.18 | Guide Rails — Sub-sections (Slice 2) | Set mode to Survey or Checklist | "Add Sub-Section" button is entirely hidden from all sections. | [ ] |
| 5.19 | Guide Rails — Input Filter (Slice 3) | Add criterion → Set type to Text, Single Choice, or Multi Choice | "Points Weight" field disappears from the row. | [ ] |
| 5.20 | Guide Rails — CCP/Risk Block (Slice 4) | Set mode to Survey or Checklist → Expand a criterion | CCP and Risk toggles are stripped/hidden entirely. | [ ] |
| 5.21 | Guide Rails — CCP/Risk Allow (Slice 4) | Mode=Penalty → Disable Global CCP in rules → Add new criterion | The CCP toggle does not appear on the new criterion. | [ ] |
| 5.22 | Guide Rails — Data Preserve (Slice 4) | Mode=Penalty → Criterion has CCP=true → Disable Global CCP | The CCP toggle **remains visible** on that specific criterion. | [ ] |

## Module 6: Audit Form Execution
**Focus**: Collapsible sections, answering criteria, and form validation.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 6.1 | Section Collapse/Expand | Tap a section header | Toggles visibility of criteria inside. | [ ] |
| 6.2 | Pass/Fail Input | Tap a criterion → Select "Non-Conform" | Bottom sheet shows Pass/Fail toggle. Score adjusts live. | [ ] |
| 6.3 | Fault Count Input | Tap a fault count criterion → Enter "3" faults | Faults + Repeats row shown. Deduction calculated. | [ ] |
| 6.4 | Scored Choices Input | Tap a scored choices criterion | Radio chips appear (e.g., Poor/Fair/Good/Excellent). | [ ] |
| 6.5 | Scale Selection | Tap "Good (5)" on a scale criterion | Score updates. Value = "Good", numericValue = 5 stored. | [ ] |
| 6.6 | Is Required Verification | Criterion is marked `isRequired` | Red asterisk shown. User must provide an answer/verify before submitting. | [ ] |
| 6.7 | Is Required Gate | Attempt to submit audit with empty `isRequired` items | System blocks submission and highlights incomplete items. | [ ] |
| 6.8 | Mandatory Fields | Try to submit with unanswered criteria | Shows validation error. Highlights missed items. | [ ] |

## Module 7: Scoring Engine & Logic Rules
**Focus**: Multi-mode scoring, critical failures, and real-time calculation. **Expanded in v2.0.**

### 7A: Penalty Mode (Top-Down)

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 7A.1 | Standard Deduction | Fail a Numeric item worth 5 points | Section score drops by formula deduction. | [ ] |
| 7A.2 | CCP Trigger | Fail a CCP-tagged item | Entire **Section** score drops to 0%. | [ ] |
| 7A.3 | RISK Trigger | Fail a RISK-tagged item | Entire **Audit** score drops to 0%. | [ ] |
| 7A.4 | Progressive Repeat | Set 3 repeated faults on an item | Deduction escalates quadratically (`3² × minus`). | [ ] |
| 7A.5 | Minus Impact Override | Trigger a fault with `minus_impact=10` | Deducts exactly 10 points regardless of weight. | [ ] |
| 7A.6 | Weighted Density | 2 sections (60%/40%) → Fail items in section 1 | Total score reflects weighted average, not raw average. | [ ] |

### 7B: Accumulation Mode (Zero-to-Top)

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 7B.1 | Basic Accumulation | 3 Pass/Fail criteria (1pt each) → Pass 2 | Score = 66.67% (2/3 × 100). | [ ] |
| 7B.2 | Accumulation + CCP | Pass all items but fail CCP item | Section earned = 0, even though other items correct. | [ ] |
| 7B.3 | Accumulation + RISK | Fail a RISK item in any section | Entire audit = 0%. | [ ] |
| 7B.4 | Scale Partial Credit | Scale criterion (max 10) → Select "Good (5)" | Earned = 5 out of 10. Score reflects partial credit. | [ ] |

### 7C: Checklist Mode (Flat Deduction)

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 7C.1 | Basic Checklist | 5 items weighted 1pt each → Fail 1 | Score = 99% (100 − 1). | [ ] |
| 7C.2 | Weighted Checklist | 5 items: 3 at 1pt, 2 at 5pt → Fail one 5pt item | Score = 95% (100 − 5). | [ ] |
| 7C.3 | Checklist + RISK | Fail a RISK item | Entire audit = 0%. | [ ] |

### 7D: Cross-Mode Verification

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 7D.1 | Server Score Match | Submit audit → Compare client vs server score | Server matches client calculation exactly (no 400 error). | [ ] |
| 7D.2 | Backward Compat | Start audit on old template (no `scoringMode` in config) | Defaults to Penalty. No crash, correct score. | [ ] |
| 7D.3 | Mode Persistence | Change template from Penalty to Accumulation → Submit new audit | New audit uses Accumulation. Old audit scores unchanged. | [ ] |

## Module 8: Submission & GPS Verification
**Focus**: Finalizing the audit, capturing location, and generating the payload.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 8.1 | GPS Capture | Tap Submit (Location disabled) | Prompts for location permission/activation. | [ ] |
| 8.2 | GPS Validation | Tap Submit (Location far from store) | Warns user or blocks submission (if enforce mode). | [ ] |
| 8.3 | Successful Submit | Tap Submit with all criteria met | Success toast. Navigates to summary. Status = completed. | [ ] |
| 8.4 | Snapshot Integrity | Store name changes on server immediately after | Submission history still shows *old* store name. | [ ] |

## Module 9: Photo Capture & Storage
**Focus**: Camera integration, local device storage, and viewing.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 9.1 | Attach Photo | Tap Camera icon on a criteria → Take photo | Photo preview thumbnail appears inline. | [ ] |
| 9.2 | Delete Attached Photo | Tap 'X' on a thumbnail | Photo is removed from the answer payload. | [ ] |
| 9.3 | Offline Photo Cache | Take photo while offline → Check device storage | Photo binary is securely written to local Drift/file storage. | [ ] |
| 9.4 | Multi-photo Limit | Attach more than 5 photos to one criteria | Blocks attachment, shows "Max photos reached". | [ ] |

## Module 10: Offline Sync & Outbox (Drift DB)
**Focus**: Liar-fi protection, background engine, schema stability.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 10.1 | Offline Submission | Airplane Mode → Submit Audit | UI shows "Saved Offline". Audit is in Outbox Queue. | [ ] |
| 10.2 | Auto-Sync Recovery | Disable Airplane Mode | Sync Engine detects network, drains queue automatically. | [ ] |
| 10.3 | Large Payload Sync | Sync an audit with 20 high-res photos | Uploads chunked. Memory usage stable. Does not timeout. | [ ] |
| 10.4 | Dead Letter Queue | Simulate API 400 error during background sync | Payload moved to DLQ (Review Required), queue continues. | [ ] |
| 10.5 | Drift App Upgrade | Install v1 APK → create draft → Install v2 APK | SQLite schema updates cleanly. Draft is preserved. | [ ] |

## Module 11: Action Plans (Corrective Actions)
**Focus**: AP lifecycle, auto-generation, and workflow gates.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 11.1 | Auto-generation (Legacy) | Submit audit with 2 `pass_fail` Non-Conform faults | 2 Open Action Plans automatically created for the store. | [ ] |
| 11.2 | Auto-generation (Custom Trigger) | Configure criterion with `actionPlanTrigger: {type: "value_equals", value: "fail"}` → Trigger it | Action Plan created for the triggered criterion. | [ ] |
| 11.3 | AP Cap (Max 10) | Submit audit triggering 12 AP-eligible faults | Only 10 Action Plans created. No overflow. | [ ] |
| 11.4 | SM Submit Evidence | SM opens `open` AP → Taps "Submit Evidence" → Enters Correction Plan & Evidence Note → Submits | AP status shifts to `pending_verify`. SM no longer sees action button. | [ ] |
| 11.5 | Auditor/Admin Verification | Auditor or Admin opens `pending_verify` AP → Taps "Verify & Close" → Confirms | AP status shifts to `closed`. Verifier name recorded. | [ ] |
| 11.6 | Auditor/Admin Rejection | Auditor or Admin opens `pending_verify` AP → Taps "Reject" → Confirms | AP status shifts back to `open`. Evidence cleared. SM can resubmit. | [ ] |
| 11.7 | Role Guard — SM Cannot Verify | SM opens a `pending_verify` AP | No "Verify & Close" or "Reject" buttons visible. | [ ] |
| 11.8 | Role Guard — Auditor Cannot Submit | Auditor opens an `open` AP | No "Submit Evidence" button visible. | [ ] |
| 11.9 | SM Transfer | Admin moves SM to new store | New SM sees APs for new store. Old SM loses access. | [ ] |
| 11.10 | Overdue Visual Flag | AP deadline passes while status is `open` | AP shows red OVERDUE indicator. Status remains `open` (visual flag only). | [ ] |
| 11.11 | Dirty State — Evidence Sheet | SM opens evidence sheet → Types in field → Swipes down | "Discard changes?" dialog appears (sheet is `isDismissible: false`). | [ ] |
| 11.12 | Dirty State — Clean Close | SM opens evidence sheet (no edits) → Taps ✕ | Sheet closes immediately. No dialog. | [ ] |

## Module 12: Real-Time Notifications
**Focus**: SignalR pushes, inbox, and background reminders.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 12.1 | Audit Submitted Push | Auditor submits → SM is logged in | SM receives push notification instantly via SignalR. | [ ] |
| 12.2 | AP Status Change | SM submits AP → AM is logged in | AM receives instant UI toast and Inbox item. | [ ] |
| 12.3 | Unread Badge | Receive new notification while app backgrounded | Inbox icon shows red dot/counter. | [ ] |
| 12.4 | Mark as Read | Tap notification | Badge counter decrements. Item grayed out. | [ ] |
| 12.5 | Local 48h Reminder | AP deadline < 48 hours | Background service triggers a local warning notification. | [ ] |

## Module 13: Admin Reference Data & System Logs
**Focus**: User management, store management, system logs, soft deletes, and audit trails.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 13.1 | Area Manager Assignment | Assign 2 AMs to the same Area | System throws 409 Conflict. Rejected. | [ ] |
| 13.2 | Store Manager Conflict | Assign SM to a store that already has one | Old SM is unassigned. New SM takes over. | [ ] |
| 13.3 | Soft Delete Guarantee | Admin deactivates a Store | Historical audits for that store still render perfectly. | [ ] |
| 13.4 | Action Trace Logging | Perform Admin action (e.g., Delete user) | Action written to System Logs with Trace ID. | [ ] |
| 13.5 | User List | Admin → User Management | Shows paginated user list with name, email, role badge, status. | [ ] |
| 13.6 | User Search | Type a name/email in search field | List filters in real-time. | [ ] |
| 13.7 | Edit User Role | Tap user → Change role dropdown → Save | Role updates. Badge changes immediately. | [ ] |
| 13.8 | Area/Store Assignment | Edit user → Select Area from dropdown → Save | Area dropdown loads dynamically from `GET /api/areas`. | [ ] |
| 13.9 | Ban/Unban User | Tap Ban toggle on a user | User status changes. Banned user cannot login. | [ ] |
| 13.10 | Self-Ban Prevention | Admin views own user entry | Ban button is disabled/hidden for current user. | [ ] |
| 13.11 | Store List | Admin → Store Management | Shows store list with name, area, active status. | [ ] |
| 13.12 | Create Store | Tap FAB → Fill name, address, select area → Save | Store created. Appears in list. | [ ] |
| 13.13 | Edit Store | Tap store → Modify name/address/area → Save | Store updated. Changes reflected immediately. | [ ] |
| 13.14 | Deactivate Store | Toggle IsActive off for a store | Store shows as inactive. Historical audits preserved. | [ ] |
| 13.15 | Transfer Store Manager | Tap Transfer SM → Select new user → Confirm | New SM assigned. Old SM unassigned. | [ ] |
| 13.16 | System Logs List | Admin → System Logs | Shows log entries with timestamp, level badge, category. | [ ] |
| 13.17 | Log Level Filter | Filter by ERROR level | Only error-level logs shown. | [ ] |
| 13.18 | Log Detail View | Tap a log entry | Bottom sheet shows full log detail (trace ID, metadata). | [ ] |
| 13.19 | Dirty State — Store Sheet | Open store edit → Type in Name → Tap ✕ | "Discard changes?" dialog appears. | [ ] |
| 13.20 | Dirty State — Store Clean | Open store edit (no changes) → Tap ✕ | Sheet closes immediately. No dialog. | [ ] |
| 13.21 | Dirty State — Area Sheet | Open area edit → Type in Name → Tap ✕ | "Discard changes?" dialog appears. | [ ] |
| 13.22 | Dirty State — User Edit Sheet | Open user edit → Change role → Tap ✕ | "Discard changes?" dialog appears. | [ ] |
| 13.23 | Dirty State — User Create Sheet | Open create user → Type name/email → Tap ✕ | "Discard changes?" dialog appears. | [ ] |
| 13.24 | isDismissible — Admin Sheets | Open any admin sheet → Tap outside the sheet | Sheet does NOT close (isDismissible: false). Must use ✕ button. | [ ] |

## Module 14: Dashboard & Analytics
**Focus**: KPI logic, Bento Box layout, drilldown navigation, advanced filtering. **Redesigned in v4.0.**

### 14A: Dashboard Layout ("The Checkly Stream")

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 14A.1 | Bento Box Grid | Admin views dashboard | Shows 2×2 grid of stat blocks: Audits, Avg Score, Open APs, Compliance. | [ ] |
| 14A.2 | Recent Submissions Feed | Scroll below stat blocks | Shows live feed of recent submissions with store, score, and time. | [ ] |
| 14A.3 | Role-Scoped Data | Login as SM → View dashboard | Stats show only the SM's assigned store data. | [ ] |
| 14A.4 | AM Scoped Data | Login as AM → View dashboard | Stats show only stores within the AM's assigned area. | [ ] |
| 14A.5 | Empty State | New installation with no submissions | Dashboard shows zeros, no crash. Feed shows "No recent audits". | [ ] |

### 14B: KPI Drilldown (Tap-to-Navigate)

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 14B.1 | Tap Total Audits | Tap "Total Audits" stat block | Navigates to History page (pre-filtered). | [ ] |
| 14B.2 | Tap Avg Score | Tap "Avg Score" stat block | Navigates to Analytics page. | [ ] |
| 14B.3 | Tap Open APs | Tap "Open APs" stat block | Navigates to Action Plans page filtered to `open`. | [ ] |
| 14B.4 | Tap Overdue APs | Tap "Overdue" stat block | Navigates to Action Plans page sorted by deadline ascending. | [ ] |
| 14B.5 | Analytics KPI Drilldown | Tap any KPI card on Analytics page | Navigates to relevant filtered page (e.g., worst store → store detail). | [ ] |
| 14B.6 | Ink Splash Feedback | Tap any stat block | Material InkWell ripple effect visible on tap. | [ ] |

### 14C: Analytics Filtering

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 14C.1 | Filter Sheet Opens | Tap filter icon on Analytics page | Scrollable filter sheet slides up. | [ ] |
| 14C.2 | Area Filter | Select an area → Apply | Analytics data scoped to selected area's stores. | [ ] |
| 14C.3 | Area→Store Cascade | Select Area → Check store dropdown | Store dropdown auto-filters to only stores in that area. | [ ] |
| 14C.4 | Auditor Filter | Select specific auditor → Apply | Only that auditor's submissions shown. | [ ] |
| 14C.5 | Status Filter | Select "Completed" → Apply | Only completed submissions included. | [ ] |
| 14C.6 | Review Status Filter | Select "Approved" → Apply | Only approved submissions included. | [ ] |
| 14C.7 | Custom Date Range | Select "Last 7 Days" → Apply | Data filtered to past 7 days only. | [ ] |
| 14C.8 | Active Filter Badge | Apply 2 filters | Filter icon shows badge with count of active filters. | [ ] |
| 14C.9 | Clear All Filters | Tap "Clear" in filter sheet | All filters reset. Full dataset restored. | [ ] |
| 14C.10 | Exclude Rejected | Auditor has an audit rejected by Admin | That audit's score completely removed from KPI average. | [ ] |

## Module 15: User Groups & Template Access Control
**Focus**: Group-based template visibility, membership management. **NEW in v3.0.**

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 15.1 | Create User Group | Admin → POST `/api/user-groups` with name | Returns 201. Group visible in list. | [ ] |
| 15.2 | List User Groups | Admin → GET `/api/user-groups` | Returns array of all groups with id, name, description. | [ ] |
| 15.3 | Add Members | Admin → PUT `/api/user-groups/{id}/members` with profileIds | Members added. 200 OK. | [ ] |
| 15.4 | Auditor Cannot Create Group | Auditor → POST `/api/user-groups` | Returns 403 Forbidden. | [ ] |
| 15.5 | Assign Template to Group | Admin → PUT `/api/templates/{id}/assignments` with groupIds | Template restricted to group members. 200 OK. | [ ] |
| 15.6 | Clear Assignments | Admin → PUT `/api/templates/{id}/assignments` with empty array | Template reverts to global (visible to all). | [ ] |
| 15.7 | Sync Filtered (Member) | Auditor in group syncs → GET `/api/sync/templates` | Sees unassigned + group-assigned templates. | [ ] |
| 15.8 | Sync Filtered (Non-Member) | Auditor NOT in group syncs | Does NOT see templates assigned to other groups. | [ ] |
| 15.9 | Admin Sees All | Admin syncs | Sees ALL templates regardless of assignments. | [ ] |

---

## Final Sign-Off

> **Note to Tester**: Any "Fail" must immediately generate an Issue ticket containing the Test ID, Steps to Reproduce, and Log attachments.

| Area | Status | Date |
|------|--------|------|
| RBAC & Core (Mod 1-4) | [ ] Pass / [ ] Fail | |
| Template Builder + Dirty State (Mod 5) | [ ] Pass / [ ] Fail | |
| Audit Engine (Mod 6-8) | [ ] Pass / [ ] Fail | |
| Photo & Offline (Mod 9-10) | [ ] Pass / [ ] Fail | |
| Workflows + Dirty State (Mod 11-13) | [ ] Pass / [ ] Fail | |
| Dashboard & Analytics (Mod 14A-C) | [ ] Pass / [ ] Fail | |
| User Groups & Access Control (Mod 15) | [ ] Pass / [ ] Fail | |
| **Release Decision** | [ ] **APPROVED FOR PROD** | |
