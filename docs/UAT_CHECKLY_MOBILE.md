# Checkly Mobile — Comprehensive UAT Test Suite
> **Version**: 1.1 (Phase UAT) | **Date**: 2026-03-13 | **Platform**: Android (APK)
> **Pre-requisite**: Server running on local LAN IP, device connected via USB/Wi-Fi.

This is the master User Acceptance Testing (UAT) document for the entire Checkly Mobile application, covering the 13 core modules and 100+ test cases necessary for production sign-off.

---

## Module 1: Authentication & Role Authorization
**Focus**: Login, JWT storage, and Role-Based Access Control (RBAC).

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 1.1 | Valid Auditor Login | Enter valid Auditor credentials -> Tap Login | Navigates to Dashboard. Profile shows Auditor role. | [ ] |
| 1.2 | Invalid Login | Enter wrong password -> Tap Login | Shows "Invalid credentials" error. | [ ] |
| 1.3 | Admin Role Limits | Login as Admin | Cannot execute audits. Sees all stores & templates. | [ ] |
| 1.4 | Store Manager (SM) Access | Login as SM | Dashboard shows only their assigned store's data. | [ ] |
| 1.5 | Area Manager (AM) Access | Login as AM | Dashboard shows only stores in their assigned Area. | [ ] |
| 1.6 | Offline Login Fallback | Turn on Airplane mode -> Force close -> Open app | App bypasses login shell, restores last cached session. | [ ] |
| 1.7 | JWT Expiry Handling | Wait for JWT expiry (or simulate) -> Perform action | App seamlessly refreshes token via server. | [ ] |

## Module 2: App Navigation & Shell
**Focus**: Bottom navigation, routing, and UI responsiveness.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 2.1 | Bottom Nav Switching | Tap through Home, Audits, Action Plans, Profile | Instant switching. Active state highlighted. | [ ] |
| 2.2 | Keyboard Padding | Focus a text input on a deeply scrolled page | UI scrolls up so input is not hidden by keyboard. | [ ] |
| 2.3 | Global Scroll Restoration | Scroll down a list -> Navigate away -> Go back | List restores exact scroll position. | [ ] |
| 2.4 | Admin Route Guard | Login as Auditor -> Navigate to `/admin/dashboard` | Redirected to `/home`. Admin pages are not accessible. | [ ] |
| 2.5 | Access Pending Redirect | Login as user with no role assigned | Redirected to Access Pending page, not Dashboard. | [ ] |
| 2.6 | Admin Nav Items | Login as Admin -> Open Admin Dashboard | All 5 menu items (Users, Stores, Approvals, Logs, Areas) navigate correctly. | [ ] |

## Module 3: Store & Area Selector
**Focus**: Selecting the audit context (Updated for Areas Entity).

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 3.1 | Area Name Display | Open Store Selector | Stores display assigned **Area Name** (not area_code). | [ ] |
| 3.2 | Store Search | Type "Hà Nội" in search bar | Real-time filtering shows matching stores. | [ ] |
| 3.3 | Null Area Handling | View a store with no assigned Area | Shows only Address. Does not crash or show "null". | [ ] |

## Module 4: Template Selection & Initialization
**Focus**: Template loading, caching, and versioning.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 4.1 | Template List | Tap "Start Audit" on Dashboard | Shows all `IsActive=true` templates. | [ ] |
| 4.2 | Inactive Templates | Admin deactivates a template on server -> Pull to refresh | Template disappears from New Audit list. | [ ] |
| 4.3 | Audit Initialization | Select Template -> Select Store | Audit form loads instantly with 0% initial score. | [ ] |
| 4.4 | New Template Route | Navigate to `/templates/new` | Opens Template Builder with empty template (no crash). | [ ] |

## Module 5: Audit Form Execution
**Focus**: Collapsible sections, answering criteria, and form validation.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 5.1 | Section Collapse/Expand | Tap a section header | Toggles visibility of criteria inside. | [ ] |
| 5.2 | Pass/Fail Input | Answer a Criteria as "Pass" | Next criteria highlights. Score adjusts. | [ ] |
| 5.3 | Fault Count Input | Enter "3" into a numeric criteria | Triggers deduction logic. | [ ] |
| 5.4 | N/A Handling | Mark criteria as "N/A" | Criteria is excluded from max possible score. | [ ] |
| 5.5 | Mandatory Fields | Try to submit with unanswered criteria | Shows validation error. Highlights missed items. | [ ] |
| 5.6 | Draft Auto-save | Answer 2 questions -> Force close app -> Re-open | Audit remains in "Drafts". Answers are preserved. | [ ] |

## Module 6: Photo Capture & Storage
**Focus**: Camera integration, local blob storage, and viewing.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 6.1 | Attach Photo | Tap Camera icon on a criteria -> Take photo | Photo preview thumbnail appears inline. | [ ] |
| 6.2 | Delete Attached Photo | Tap 'X' on a thumbnail | Photo is removed from the answer payload. | [ ] |
| 6.3 | Offline Photo Cache | Take photo while offline -> Check IndexedDB/Device File | Photo binary is securely written to local storage. | [ ] |
| 6.4 | Multi-photo Limit | Attach more than 5 photos to one criteria | Blocks attachment, shows "Max photos reached". | [ ] |

## Module 7: Scoring Engine & Logic Rules
**Focus**: Real-time unified deduction logic and triggers.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 7.1 | Standard Deduction | Fail an item worth 5% weight | Section score drops exactly by formula deduction. | [ ] |
| 7.2 | CCP Trigger | Fail a Critical Control Point (CCP) | Entire Section Score drops abruptly to 0%. | [ ] |
| 7.3 | RISK Trigger | Fail a RISK item | Entire Audit Score drops abruptly to 0%. | [ ] |
| 7.4 | Progressive Repeat (C3) | Add 3 repeated faults | Deduction escalates quadratically (`3² × minus`). | [ ] |
| 7.5 | Minus Impact Override (C4)| Trigger a fault with `minus_impact=10` | Deducts exactly 10 points regardless of weight. | [ ] |
| 7.6 | Server Verification | Submit audit to server | Server matches client calculation exactly (no 400). | [ ] |

## Module 8: Submission & GPS Verification
**Focus**: Finalizing the audit, capturing location, and generating the payload.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 8.1 | GPS Capture | Tap Submit (Location disabled) | Prompts for location permission/activation. | [ ] |
| 8.2 | GPS Validation | Tap Submit (Location far from store) | Warns user or blocks submission (if enforce mode). | [ ] |
| 8.3 | Successful Submit | Tap Submit with all criteria met | Success toast. Navigates to summary. Status = completed. | [ ] |
| 8.4 | Snapshot Integrity | Store name changes on server immediately after | Submission history still shows *old* store name. | [ ] |

## Module 9: Offline Sync & Outbox (Drift DB)
**Focus**: Liar-fi protection, background engine, schema stability.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 9.1 | Offline Submission | Airplane Mode -> Submit Audit | UI shows "Saved Offline". Audit is in Outbox Queue. | [ ] |
| 9.2 | Auto-Sync Recovery | Disable Airplane Mode | Sync Engine detects network, drains queue automatically. | [ ] |
| 9.3 | Large Payload Sync | Sync an audit with 20 high-res photos | Uploads chunked. Memory usage stable. Does not timeout. | [ ] |
| 9.4 | Dead Letter Queue | Simulate API 400 error during background sync | Payload moved to DLQ (Review Required), queue continues. | [ ] |
| 9.5 | Drift App Upgrade | Install v1 APK -> create draft -> Install v2 APK | SQLite scheme updates cleanly. Draft is preserved. | [ ] |

## Module 10: Action Plans (Corrective Actions)
**Focus**: AP lifecycle, auto-generation, and workflow gates.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 10.1| Auto-generation (S1) | Submit audit with 2 faults | 2 Open Action Plans automatically created for the store. | [ ] |
| 10.2| SM Root Cause Input | SM opens AP -> Enters Root Cause & Correction -> Submits | AP status shifts to `pending_verify`. | [ ] |
| 10.3| AM Verification | AM reviews `pending_verify` AP -> Approves | AP status shifts to `closed`. | [ ] |
| 10.4| AM Rejection | AM reviews -> Rejects with comment | AP status shifts back to `in_progress`. | [ ] |
| 10.5| S8 SM Transfer | Admin moves SM to new store | New SM sees APs for new store. Old SM loses access. | [ ] |
| 10.6| Automatic Overdue (C1) | Change server clock past the AP 7-day deadline | AP status automatically transitions to `overdue`. | [ ] |

## Module 11: Real-Time Notifications
**Focus**: SignalR pushes, inbox, and background reminders.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 11.1| S3 Audit Submitted | Auditor submits -> SM is logged in | SM receives push notification instantly via SignalR. | [ ] |
| 11.2| S2 AP Status Change | SM submits AP -> AM is logged in | AM receives instant UI toast and Inbox item. | [ ] |
| 11.3| Unread Badge | Receive new notification while app backgrounded | Inbox icon shows red dot/counter. | [ ] |
| 11.4| Mark as Read | Tap notification | Badge counter decrements. Item grayed out. | [ ] |
| 11.5| Local 48h Reminder (S6)| AP deadline < 48 hours | Background service triggers a local warning notification. | [ ] |

## Module 12: Admin Reference Data & System Logs
**Focus**: User management, store management, system logs, soft deletes, and audit trails.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 12.1| Area Manager Assignment| Assign 2 AMs to the same Area (S10 Rule) | System throws 409 Conflict. Rejected. | [ ] |
| 12.2| Store Manager Conflict | Assign SM to a store that already has one (S9)| Old SM is unassigned. New SM takes over. | [ ] |
| 12.3| Soft Delete Guarantee | Admin deactivates a Store | Historical audits for that store still render perfectly. | [ ] |
| 12.4| Action Trace Logging | Perform Admin action (e.g., Delete user) | S12: Action written to System Logs with Trace ID. | [ ] |
| **12.5**| **User List** | Admin -> User Management | Shows paginated user list with name, email, role badge, status. | [ ] |
| 12.6| User Search | Type a name/email in search field | List filters in real-time. | [ ] |
| 12.7| Edit User Role | Tap user -> Change role dropdown -> Save | Role updates. Badge changes immediately. | [ ] |
| 12.8| Area/Store Assignment | Edit user -> Select Area from dropdown -> Save | Area dropdown loads dynamically from `GET /api/areas` (not hardcoded). | [ ] |
| 12.9| Ban/Unban User | Tap Ban toggle on a user | User status changes. Banned user cannot login. | [ ] |
| 12.10| Self-Ban Prevention | Admin views own user entry | Ban button is disabled/hidden for current user. | [ ] |
| **12.11**| **Store List** | Admin -> Store Management | Shows store list with name, area, active status. | [ ] |
| 12.12| Create Store | Tap FAB -> Fill name, address, select area from dropdown -> Save | Store created. Appears in list. Area from `GET /api/areas`. | [ ] |
| 12.13| Edit Store | Tap store -> Modify name/address/area -> Save | Store updated. Changes reflected immediately. | [ ] |
| 12.14| Deactivate Store | Toggle IsActive off for a store | Store shows as inactive. Historical audits preserved (12.3). | [ ] |
| 12.15| Transfer Store Manager | Tap Transfer SM -> Select new user -> Confirm | New SM assigned. Old SM unassigned. | [ ] |
| **12.16**| **System Logs List** | Admin -> System Logs | Shows log entries with timestamp, level badge, category, message. | [ ] |
| 12.17| Log Level Filter | Filter by ERROR level | Only error-level logs shown. | [ ] |
| 12.18| Log Detail View | Tap a log entry | Bottom sheet shows full log detail (trace ID, metadata). | [ ] |

## Module 13: Dashboard & Analytics
**Focus**: KPI logic, charting, and role-based filtering.

| ID | Test Case | Steps to Verify | Expected Result | Pass/Fail |
|----|-----------|-----------------|-----------------|:---------:|
| 13.1| Global KPIs | Admin views dashboard | Shows total audits, average score, global open APs. | [ ] |
| 13.2| Area Filter | AM views dashboard | Dashboard automatically locked to AM's specific Area. | [ ] |
| 13.3| Exclude Rejected (C8) | Auditor has an audit rejected by Admin | That audit's score completely removed from KPI average. | [ ] |
| 13.4| Trend Charts | Render line chart for past 30 days | UI draws smoothly. No overlapping axis labels. | [ ] |

---

## Final Sign-Off

> **Note to Tester**: Any "Fail" must immediately generate an Issue ticket containing the Test ID, Steps to Reproduce, and Log attachments from `checkly-offline -> system_logs`.

| Area | Status | Date |
|------|--------|------|
| RBAC & Core (Mod 1-4) | [ ] Pass / [ ] Fail | |
| Audit Engine (Mod 5-8) | [ ] Pass / [ ] Fail | |
| Offline & DB (Mod 9) | [ ] Pass / [ ] Fail | |
| Workflows (Mod 10-12) | [ ] Pass / [ ] Fail | |
| **Release Decision** | [ ] **APPROVED FOR PROD** | |

