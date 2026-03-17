# Checkly Mobile — Comprehensive UAT Test Suite
> **Version**: 2.0 (Post Scoring Engine Extensibility) | **Date**: 2026-03-17 | **Platform**: Android (APK)
> **Pre-requisite**: Server running on local LAN IP, device connected via USB/Wi-Fi.

Master User Acceptance Testing (UAT) document for the Checkly Mobile application. Covers 14 core modules and 120+ test cases.

---

## Module 1: Authentication & Role Authorization
**Focus**: Login, JWT storage, and Role-Based Access Control (RBAC).

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
| 2.4 | Admin Route Guard | Login as Auditor → Navigate to `/admin/dashboard` | Redirected to `/home`. Admin pages are not accessible. | [ ] |
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
| 4.1 | Template List | Tap "Start Audit" on Dashboard | Shows all `IsActive=true` templates. | [ ] |
| 4.2 | Inactive Templates | Admin deactivates a template on server → Pull to refresh | Template disappears from New Audit list. | [ ] |
| 4.3 | Penalty Audit Init | Select a **Penalty** template → Select Store | Audit form loads with **100%** initial score. | [ ] |
| 4.4 | Accumulation Audit Init | Select an **Accumulation** template → Select Store | Audit form loads with **0%** initial score. | [ ] |
| 4.5 | Checklist Audit Init | Select a **Checklist** template → Select Store | Audit form loads with **100%** initial score. | [ ] |
| 4.6 | New Template Route | Navigate to `/templates/new` | Opens Template Builder with empty template (no crash). | [ ] |

## Module 5: Template Builder (Admin)
**Focus**: Creating and editing templates with the Generic Builder. **NEW in v2.0.**

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 5.1 | Create Template | Fill in name, type, description → Add 2 sections → Save | Template saved. Appears in template list. | [ ] |
| 5.2 | Scoring Mode Dropdown | Open Scoring Rules → Change dropdown | Options: Penalty, Accumulation, Checklist. Selection saved. | [ ] |
| 5.3 | Weighted Density Toggle | Set mode to Penalty → Toggle Weighted Density | Section weight fields appear. Sum must = 100%. | [ ] |
| 5.4 | Weighted Density Hidden | Set mode to Checklist | Weighted Density toggle is hidden. | [ ] |
| 5.5 | Layout Locking — Flat | Add a criterion to an empty section | "Add Sub-Section" button disappears. Section locked to flat. | [ ] |
| 5.6 | Layout Locking — Nested | Add a sub-section to an empty section | "Add Criteria" button at section level disappears. Locked to nested. | [ ] |
| 5.7 | Input Type — Numeric | Add criterion → Input Type defaults to "Numeric" | Points Weight field is editable. | [ ] |
| 5.8 | Input Type — Pass/Fail | Add criterion → Change to "Pass / Fail" | Points Weight field is editable. | [ ] |
| 5.9 | Input Type — Scale | Add criterion → Change to "Scale (Matrix)" | Scale Options editor appears. Points Weight auto-calculated. | [ ] |
| 5.10 | Scale Options Editor | Add 4 options (Poor=0, Fair=2, Good=5, Excellent=10) | Options saved. Points Weight auto-set to 10. | [ ] |
| 5.11 | Scale Validation | Set input type to Scale → Try to save with 0 or 1 options | Save blocked with SnackBar error: min 2 options. | [ ] |
| 5.12 | CCP/RISK Badges | Enable CCP on a criterion → Collapse | CCP badge visible on collapsed row. | [ ] |
| 5.13 | Edit Existing Template | Open saved template → Modify name → Save | Changes persisted. Score rules and criteria intact. | [ ] |

## Module 6: Audit Form Execution
**Focus**: Collapsible sections, answering criteria, and form validation.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 6.1 | Section Collapse/Expand | Tap a section header | Toggles visibility of criteria inside. | [ ] |
| 6.2 | Pass/Fail Input | Tap a criterion → Select "Non-Conform" | Bottom sheet shows Pass/Fail toggle. Score adjusts live. | [ ] |
| 6.3 | Numeric Fault Input | Tap a numeric criterion → Enter "3" faults | Faults + Repeats row shown. Deduction calculated. | [ ] |
| 6.4 | Scale Input | Tap a scale criterion | Radio chips appear (e.g., Poor/Fair/Good/Excellent). | [ ] |
| 6.5 | Scale Selection | Tap "Good (5)" on a scale criterion | Score updates. Value = "Good", numericValue = 5 stored. | [ ] |
| 6.6 | Confirm Correct | Template has Confirm Correct enabled → No faults on item | "Confirm Correct" button shown. Must tap to verify. | [ ] |
| 6.7 | Confirm Correct Toggle | Tap "Confirm Correct" → Tap again | Toggles between "Standard Verified" ↔ "Confirm Correct". | [ ] |
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
| 11.1 | Auto-generation | Submit audit with 2 faults | 2 Open Action Plans automatically created for the store. | [ ] |
| 11.2 | SM Root Cause Input | SM opens AP → Enters Root Cause & Correction → Submits | AP status shifts to `pending_verify`. | [ ] |
| 11.3 | AM Verification | AM reviews `pending_verify` AP → Approves | AP status shifts to `closed`. | [ ] |
| 11.4 | AM Rejection | AM reviews → Rejects with comment | AP status shifts back to `in_progress`. | [ ] |
| 11.5 | SM Transfer | Admin moves SM to new store | New SM sees APs for new store. Old SM loses access. | [ ] |
| 11.6 | Automatic Overdue | Change server clock past the AP 7-day deadline | AP status automatically transitions to `overdue`. | [ ] |

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

## Module 14: Dashboard & Analytics
**Focus**: KPI logic, charting, and role-based filtering.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 14.1 | Global KPIs | Admin views dashboard | Shows total audits, average score, global open APs. | [ ] |
| 14.2 | Area Filter | AM views dashboard | Dashboard automatically locked to AM's specific Area. | [ ] |
| 14.3 | Exclude Rejected | Auditor has an audit rejected by Admin | That audit's score completely removed from KPI average. | [ ] |
| 14.4 | Trend Charts | Render line chart for past 30 days | UI draws smoothly. No overlapping axis labels. | [ ] |

---

## Final Sign-Off

> **Note to Tester**: Any "Fail" must immediately generate an Issue ticket containing the Test ID, Steps to Reproduce, and Log attachments.

| Area | Status | Date |
|------|--------|------|
| RBAC & Core (Mod 1-4) | [ ] Pass / [ ] Fail | |
| Template Builder (Mod 5) | [ ] Pass / [ ] Fail | |
| Audit Engine (Mod 6-8) | [ ] Pass / [ ] Fail | |
| Photo & Offline (Mod 9-10) | [ ] Pass / [ ] Fail | |
| Workflows (Mod 11-13) | [ ] Pass / [ ] Fail | |
| Analytics (Mod 14) | [ ] Pass / [ ] Fail | |
| **Release Decision** | [ ] **APPROVED FOR PROD** | |
