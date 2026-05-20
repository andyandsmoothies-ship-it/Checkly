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
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Role tenancy enforcement (IDOR protection) via `StoreId` |
| StoreAnalyticsSnapshot | `Features/Submissions/FinalizeSubmission.cs` | Upserts 30-day snapshot on finalize |
| ActionPlans | `Features/ActionPlans/` | Ownership via `StoreId` |
| Photos | `Features/Photos/` | IDOR via submission → store chain |
| GetStoreDashboard | `Features/Stores/GetStoreDashboard.cs` | Aggregates store metrics |
| ListStores | `Features/Stores/ListStores.cs` | Lists with optional `IsActive` filter |

### Deactivation Impact
- **Blocked**: CreateSubmission, UpdateUser (assign), TransferStoreManager
- **Unaffected**: Historical submissions, action plans, analytics, photos, profiles

---

## ProfileStoreAssignment

| Consumer | File | Relationship |
|----------|------|-------------|
| Profile | `Common/Persistence/Entities/Profile.cs` | Navigation property |
| Store | `Common/Persistence/Entities/Store.cs` | Navigation property |
| ResourceAccessGuard | `Common/Auth/ResourceAccessGuard.cs` | PBAC base scope enforcement |
| ListSubmissions | `Features/Submissions/ListSubmissions.cs` | AM scoping via assigned stores |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Role tenancy enforcement (IDOR protection) via assigned stores |
| UpdateUser | `Features/Admin/UpdateUser.cs` | Assigns AM to multiple stores |

### Deactivation Impact
- **Blocked**: Re-assigning to inactive stores.
- **Unaffected**: Existing profiles, historical data

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

### Ban & Role Change Impact (via InvalidateTokensBefore & LockoutEnd)
- **Blocked**: Login (returns 423 Locked)
- **Revoked**: Active JWT tokens issued before the change/ban are instantly rejected by `OnTokenValidated` middleware.
- **Unaffected**: Historical submissions, action plans, profile data

---

## Submission

| Consumer | File | Relationship |
|----------|------|-------------|
| ListSubmissions | `Features/Submissions/ListSubmissions.cs` | Paginated list with role-scoped filtering (admin→all, auditor→owns, SM→store, AM→assigned stores) |
| GetSubmission | `Features/Submissions/GetSubmission.cs` | IDOR-guarded detail view |
| FinalizeSubmission | `Features/Submissions/FinalizeSubmission.cs` | Draft→completed transition, score verification, answer + action plan creation. Evaluates `RowVersion` (`xmin`) for optimistic concurrency control. |
| GetSurveyResults | `Features/Submissions/GetSurveyResults.cs` | Aggregates survey answers by criteria |
| GetAnalytics | `Features/Analytics/GetAnalytics.cs` | Score trends, 6-month aggregation, section breakdown (90-day scope) |
| GetTopFailures | `Features/Analytics/GetTopFailures.cs` | Groups answers by criteria across submissions |
| GetStoreDashboard | `Features/Stores/GetStoreDashboard.cs` | Recent audits, avg score, open APs for a store |
| StoreAnalyticsSnapshot | `Features/Submissions/FinalizeSubmission.cs` | Upserts 30-day snapshot on finalize |
| Photos | `Features/Photos/` | Photo upload restricted to 15MB, valid MIME rules, and IDOR validation scoped to submission ownership |
| ActionPlans | `Features/ActionPlans/` | Created from triggered answers on finalize |
| Sync | `Features/Submissions/SyncTemplates.cs` | Template sync for offline submission creation |

### Deletion Policy
- **Never deleted** — submissions are immutable audit records
- Status transitions: `draft` → `completed` (irreversible)
- `ReviewStatus`: `pending` → `approved`/`rejected` / `void` (Admin only. Voiding effectively soft-deletes the audit across Analytics and UI views).

---

## ProgramAssignment

| Consumer | File | Relationship |
|----------|------|-------------|
| CreateProgram | `Features/Programs/CreateProgram.cs` | Bulk creates assignments for selected stores |
| SubmitProgramEvidence | `Features/Programs/SubmitProgramEvidence.cs` | SM transition `pending` → `submitted`, adds `ProgramEvidence` records |
| RejectProgramAssignment | `Features/Programs/RejectProgramAssignment.cs` | HQ transition `submitted` → `needs_revision`, adds `RejectionComment` |
| VerifyProgramAssignment | `Features/Programs/VerifyProgramAssignment.cs` | HQ transition `submitted` → `verified`, sets `VerifiedAt` |
| GetMyAssignments | `Features/Programs/GetMyAssignments.cs` | Filtered by `StoreId` for Store Managers |
| GetProgramAssignments | `Features/Programs/GetProgramAssignments.cs` | Grouped view for HQ Dashboard |
| GetProgramSummary | `Features/Programs/GetProgramSummary.cs` | Aggregates assignments by status for a `ProgramId` |

### Deletion Policy
- **Never deleted** — program assignments are compliance records
- Status transitions: `pending` → `submitted` → `needs_revision` ↔ `submitted` → `verified`
- Optimistic Concurrency Control via `xmin` (RowVersion) prevents race conditions during status transitions.

---

## GlobalRisk

| Consumer | File | Relationship |
|----------|------|-------------|
| FinalizeSubmission | `Features/Submissions/FinalizeSubmission.cs` | Queries `SubmissionRisks`, forces 0 score |
| ActionPlanService | `Common/Services/ActionPlanService.cs` | Generates Action Plans for triggered global risks |
| SyncRisks | `Features/Submissions/SyncRisks.cs` | Delta sync for offline clients |
| ListSubmissionRisks | `Features/Submissions/SubmissionRisks/ListSubmissionRisks.cs` | Loads risks for a specific submission |

### Deletion Policy
- **GlobalRisk**: Soft deleted (`is_active = false`). Prevents future audits from seeing it.
- **SubmissionRisk**: Never deleted. Immutable audit record linked to the submission.

---

## ActionPlan

| Consumer | File | Relationship |
|----------|------|-------------|
| ActionPlanService | `Features/ActionPlans/ActionPlanService.cs` | Auto-created from triggered answers (participates in caller's transaction) |
| ListActionPlans | `Features/ActionPlans/ListActionPlans.cs` | Filtered by store, status, overdue |
| UpdateActionPlan | `Features/ActionPlans/UpdateActionPlan.cs` | SM submits evidence, Admin/AM closes via status transition |
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
| `RoleAssignmentGuard` | `Common/Auth/RoleAssignmentGuard.cs` | 1 SM per store | UpdateUser |
| `AuditLogger` | `Common/Services/AuditLogger.cs` | Entity-level audit log | Template CRUD, SaveTemplateTree, FinalizeSubmission, Admin actions |
| `TokenService` | `Common/Auth/TokenService.cs` | JWT generation | Login, Register |
| `ScoringVerifier` | `Common/Scoring/ScoringVerifier.cs` | Score validation | CreateSubmission, FinalizeSubmission |
| `ActionPlanService` | `Features/ActionPlans/ActionPlanService.cs` | Auto-create action plans (runs in caller's Unit of Work) | CreateSubmission, FinalizeSubmission |
| `ReminderService` | `Common/Services/ReminderService.cs` | Background cleanup + reminders | Hosted service (scheduled) |
| `FcmDispatchService` | `Common/Services/FcmDispatchService.cs` | Push notifications to mobile devices via Firebase (Polly Resilience) | FinalizeSubmission |
