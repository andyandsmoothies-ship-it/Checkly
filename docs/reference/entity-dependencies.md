# Entity Dependencies Map

> **Purpose**: Cross-feature traceability. When modifying an entity, check this map to identify all downstream consumers.
> **Rule**: Any new feature that references a core entity MUST update this file.

---

## Store

| Consumer | File | Relationship |
|----------|------|-------------|
| CreateSubmission | `Features/Submissions/CreateSubmission.cs` | Loads store, checks `IsActive`, snapshots `StoreName` |
| FinalizeSubmission | `Features/Submissions/FinalizeSubmission.cs` | Loads store for ActionPlan creation |
| ListSubmissions | `Features/Submissions/ListSubmissions.cs` | Filters by `StoreId` (SM/AM scoping) |
| GetSubmission | `Features/Submissions/GetSubmission.cs` | IDOR check via `StoreId` |
| UpdateUser | `Features/Admin/UpdateUser.cs` | Assigns user to store, checks `IsActive` |
| TransferStoreManager | `Features/Admin/TransferStoreManager.cs` | Transfers SM, checks `IsActive` |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Filters by `StoreId` |
| StoreAnalyticsSnapshot | `Features/Submissions/FinalizeSubmission.cs` | Upserts 30-day snapshot on finalize |
| ActionPlans | `Features/ActionPlans/` | Ownership via `StoreId` |
| Photos | `Features/Photos/` | IDOR via submission → store chain |
| GetStoreDashboard | `Features/Stores/GetStoreDashboard.cs` | Aggregates store metrics |
| ListStores | `Features/Stores/ListStores.cs` | Lists with optional `IsActive` filter |

### Deactivation Impact
- **Blocked**: CreateSubmission, UpdateUser (assign), TransferStoreManager, CreateStore (in deactivated area)
- **Unaffected**: Historical submissions, action plans, analytics, photos, profiles

---

## Area

| Consumer | File | Relationship |
|----------|------|-------------|
| Store | `Common/Persistence/Entities/Store.cs` | FK `AreaId` (SetNull on delete) |
| Profile | `Common/Persistence/Entities/Profile.cs` | FK `AreaId` (SetNull on delete) — area managers |
| CreateStore | `Features/Stores/CreateStore.cs` | Looks up area name, validates `IsActive` |
| CreateSubmission | `Features/Submissions/CreateSubmission.cs` | Checks `area.IsActive` via store's AreaId |
| GetSubmission | `Features/Submissions/GetSubmission.cs` | IDOR check via `IsUserArea` |
| ListSubmissions | `Features/Submissions/ListSubmissions.cs` | AM scoping via area → stores |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Filters by `areaId` → store list |
| UpdateUser | `Features/Admin/UpdateUser.cs` | Assigns AM to area |

### Deactivation Impact
- **Blocked**: CreateStore (in this area), CreateSubmission (for stores in this area)
- **Unaffected**: Existing stores (remain active), profiles, historical data

---

## Template

| Consumer | File | Relationship |
|----------|------|-------------|
| CreateSubmission | `Features/Submissions/CreateSubmission.cs` | Loads template, checks `IsActive`, snapshots |
| FinalizeSubmission | `Features/Submissions/FinalizeSubmission.cs` | Reads snapshot or falls back to live template |
| SaveTemplateTree | `Features/Templates/SaveTemplateTree.cs` | Atomic upsert of full tree (groups + criteria), soft-delete reconciliation, optimistic concurrency via `Version` |
| Groups & Criteria | `Features/Templates/` | Cascade delete on template deletion |
| TemplateAssignments | `Features/Templates/` | Links to UserGroups |
| Sync endpoint | `Features/Templates/SyncTemplates.cs` | Delta sync for offline clients |
| Analytics | `Features/Analytics/GetAnalytics.cs` | Filters by template type |

### Deactivation Impact
- **Blocked**: CreateSubmission (returns "Template is archived")
- **Unaffected**: Existing submissions (use snapshot), sync, analytics

---

## Profile (User)

| Consumer | File | Relationship |
|----------|------|-------------|
| Submissions | `Features/Submissions/` | `AuditorId` ownership |
| ActionPlans | `Features/ActionPlans/` | `StoreManagerId` assignment |
| UserGroups | `Features/UserGroups/` | Membership via `UserGroupMembers` |
| TemplateAssignments | `Features/Templates/` | Access scoping via user group membership |
| Notifications | `Features/Notifications/` | Per-user delivery |
| Admin CRUD | `Features/Admin/` | Full lifecycle management |

### Ban Impact (via Identity LockoutEnd)
- **Blocked**: Login (returns 423 Locked)
- **Unaffected**: Historical submissions, action plans, profile data

---

## Submission

| Consumer | File | Relationship |
|----------|------|-------------|
| ListSubmissions | `Features/Submissions/ListSubmissions.cs` | Paginated list with role-scoped filtering (admin→all, auditor→owns, SM→store, AM→area) |
| GetSubmission | `Features/Submissions/GetSubmission.cs` | IDOR-guarded detail view |
| FinalizeSubmission | `Features/Submissions/FinalizeSubmission.cs` | Draft→completed transition, score verification, answer + action plan creation |
| GetSurveyResults | `Features/Submissions/GetSurveyResults.cs` | Aggregates survey answers by criteria |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Score trends, 6-month aggregation, top failures |
| GetTopFailures | `Features/Analytics/GetTopFailures.cs` | Groups answers by criteria across submissions |
| GetStoreDashboard | `Features/Stores/GetStoreDashboard.cs` | Recent audits, avg score, open APs for a store |
| StoreAnalyticsSnapshot | `Features/Submissions/FinalizeSubmission.cs` | Upserts 30-day snapshot on finalize |
| Photos | `Features/Photos/` | Photo upload/download scoped to submission |
| ActionPlans | `Features/ActionPlans/` | Created from triggered answers on finalize |
| Sync | `Features/Submissions/SyncTemplates.cs` | Template sync for offline submission creation |

### Deletion Policy
- **Never deleted** — submissions are immutable audit records
- Status transitions: `draft` → `completed` (irreversible)
- `ReviewStatus`: `pending` → `approved`/`rejected` (admin only)

---

## ActionPlan

| Consumer | File | Relationship |
|----------|------|-------------|
| ActionPlanService | `Features/ActionPlans/ActionPlanService.cs` | Auto-created from triggered answers on finalize |
| ListActionPlans | `Features/ActionPlans/ListActionPlans.cs` | Filtered by store, status, overdue |
| UpdateActionPlan | `Features/ActionPlans/UpdateActionPlan.cs` | SM adds root cause, correction plan, evidence |
| VerifyActionPlan | `Features/ActionPlans/VerifyActionPlan.cs` | Admin/AM closes action plan |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Open/overdue counts per store |
| GetStoreDashboard | `Features/Stores/GetStoreDashboard.cs` | Open AP count |
| StoreAnalyticsSnapshot | Background refresh | Overdue AP count per store |
| ReminderService | `Common/Services/ReminderService.cs` | Sends overdue AP notifications |

### Deletion Policy
- **Never deleted** — compliance records for audit trails
- Status transitions: `open` → `closed` (with evidence)

---

## Shared Guards & Services

| Name | Location | Purpose | Used By |
|------|----------|---------|---------|
| `SubmissionAccessGuard` | `Common/SubmissionAccessGuard.cs` | IDOR check (role → ownership) | GetSubmission, UploadPhoto, GetPhoto |
| `RoleAssignmentGuard` | `Common/Auth/RoleAssignmentGuard.cs` | 1 SM per store, 1 AM per area | UpdateUser |
| `AuditLogger` | `Common/Services/AuditLogger.cs` | Entity-level audit log | Template CRUD, SaveTemplateTree, FinalizeSubmission, Admin actions |
| `TokenService` | `Common/Auth/TokenService.cs` | JWT generation | Login, Register |
| `ScoringVerifier` | `Common/Scoring/ScoringVerifier.cs` | Score validation | CreateSubmission, FinalizeSubmission |
| `ActionPlanService` | `Features/ActionPlans/ActionPlanService.cs` | Auto-create action plans | CreateSubmission, FinalizeSubmission |
| `ReminderService` | `Common/Services/ReminderService.cs` | Background cleanup + reminders | Hosted service (scheduled) |
