# Checkly Database Schema Reference

> **Database**: PostgreSQL 18.3 | **ORM**: Entity Framework Core 10 | **Schema**: `public`

> [!WARNING]
> **Offline Database Architecture Shift (Drift v3)**
> The Flutter client is actively migrating from Drift v2 to Drift v3. **Phase 1 Complete**: The legacy `sqlite3_flutter_libs` package has been completely removed because it conflicts with modern Android builds. We now use Native `sqlite3` build hooks. Do not revert to old Drift initialization patterns.

---

## Table Overview

The Checkly database contains **31 tables** organized into 3 categories:

> **Performance Note**: All core domain tables involved in offline Delta Sync (`stores`, `templates`, `groups`, `criteria`, `submissions`, `answers`, `action_plans`, `global_risks`, `submission_risks`, `program_assignments`, `program_evidence`) enforce mandatory **B-Tree indexes on `updated_at`** to prevent full-table scans during mobile sync rounds.

| Category | Tables | Purpose |
|----------|--------|---------|
| **Business Domain** | 23 tables | Core audit & programs workflow data |
| **ASP.NET Identity** | 7 tables | Authentication & identity infrastructure |
| **EF Core Internal** | 1 table | Migration tracking |

---

## Business Domain Tables (23)

### `profiles`
**Rows**: 7 | **Soft Delete**: No (ban via `AspNetUsers.LockoutEnd`)

User metadata linked 1:1 with `AspNetUsers`. Stores display name, email, and organizational assignment.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Same as `AspNetUsers.Id` — shared identity |
| `full_name` | text | User's display name |
| `email` | text | User's email (mirrors Identity) |
| `avatar_url` | text? | Profile picture URL |
| `store_id` | UUID? (FK → stores) | Assigned store (for Store Managers) |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last modification |

> **Key Relationships**: A Store Manager has `store_id` set. An Area Manager is mapped to multiple stores via the `profile_store_assignments` junction table. Admins and Auditors have null `store_id` (global access).

---

### `user_roles`
**Rows**: 7 | **One role per user**

Maps each user to exactly one application role. Separate from Identity's built-in roles table for business clarity.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique role assignment ID |
| `user_id` | UUID (FK → AspNetUsers) | The user |
| `role` | text | One of: `admin`, `auditor`, `store_manager`, `area_manager` |
| `created_at` | timestamptz | When role was assigned |

---

### `role_capabilities`
**Rows**: 0 | **Populated dynamically**

Maps roles to fine-grained capability strings as part of the PBAC (Permission-Based Access Control) system. Capability format is `{domain}:{action}` (e.g. `templates:create`). Changes here emit a `pg_notify` to invalidate backend cache.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique capability ID |
| `role` | text | Which role this applies to (e.g., `admin`, `auditor`) |
| `capability` | text | The capability mapping (e.g. `templates:create`) |
| `created_at` | timestamptz | Record creation |

---

### `stores`
**Rows**: 6 | **Soft Delete**: `is_active = false`

Physical store locations where audits are conducted.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique store ID |
| `name` | text | Store name (e.g., "Cửa hàng Quận 1") |
| `address` | text? | Legacy street address |
| `address_province` | text? | Structured address: Province |
| `address_district` | text? | Structured address: District |
| `address_ward` | text? | Structured address: Ward |
| `address_street` | text? | Structured address: Street |
| `gps_lat` | decimal? | Latitude for GPS verification |
| `gps_lng` | decimal? | Longitude for GPS verification |
| `is_active` | boolean | Soft delete flag (false = deactivated) |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

---

### `profile_store_assignments`
**Rows**: dynamic | **Junction table**

Explicit junction table tracking which stores an Area Manager is assigned to. Replaces the legacy `area_id` model.

| Column | Type | Purpose |
|--------|------|---------|
| `profile_id` | UUID (PK, FK → profiles) | The area manager |
| `store_id` | UUID (PK, FK → stores) | The assigned store |
| `created_at` | timestamptz | Record creation |

### `templates`
**Rows**: 3 | **Soft Delete**: `is_active = false`

Audit templates define the structure of an audit (what to check).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique template ID |
| `title` | text | Template name (e.g., "QC Monthly Audit") |
| `description` | text? | Template description |
| `type` | text? | Category: `qc`, `training`, `general`, `task force` |
| `is_active` | boolean | Soft delete flag |
| `version` | integer | Template version counter — incremented on every template/group/criterion update. Used for snapshot versioning |
| `category_tag` | text | Audit category tag (e.g. `routine`, `compliance`) |
| `scoring_logic_config` | jsonb? | Scoring rules: `scoreDirection` (`down`/`up`/`none`), `isWeighted`, density flags, repeat config, `actionPlanDeadlineDays`, and `confirm_required` |
| `display_noun` | text? | Custom terminology override (e.g., "Inspection" instead of default derived from scoring mode) |
| `created_by` | UUID? (FK → AspNetUsers) | Admin who created the template |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `groups`
**Rows**: 4 | **Soft Delete**: `is_active = false`

Sections within a template.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique group ID |
| `template_id` | UUID (FK → templates) | Parent template |
| `title` | text | Section title |
| `description` | text? | Section description |
| `weight` | decimal? | Section weight for weighted scoring (optional) |
| `max_deduction_points` | decimal? | Cap on deductions within this section |
| `minus_per_fault` | decimal? | Default deduction per fault for numeric criteria |
| `order_index` | integer | Display order within parent |
| `metadata` | jsonb? | Extra config (e.g., section-level scoring overrides) |
| `is_active` | boolean | Soft delete flag |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `criteria`
**Rows**: 18 | **Soft Delete**: `is_active = false`

Individual checklist items within a group that auditors evaluate.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique criteria ID |
| `group_id` | UUID (FK → groups) | Parent group/section |
| `label` | text | Question text (e.g., "Floor cleanliness maintained?") |
| `description` | text? | Optional description/instructions for the criterion |
| `input_type` | text | `pass_fail`, `numeric`, `scale`, `single_choice`, `multi_choice`, or `text` |
| `is_ccp` | boolean | Critical Control Point — fail = section score → 0% |
| `is_risk` | boolean | RISK item — fail = entire audit score → 0% |
| `points_weight` | decimal? | Deduction weight for standard scoring. `null` for non-scored types (`text`, `single_choice`, `multi_choice`) |
| `max_deduction_points` | decimal? | Cap on deductions for this specific criterion (Visual Folders Architecture) |
| `minus_per_fault` | decimal? | Deduction per fault for numeric input |
| `minus_impact` | decimal? | C4 override: uses this instead of `points_weight`. **Offline Sync**: Persisted locally in Drift `CachedCriteria` table to prevent score mismatch on checklist audits. |
| `order_index` | integer | Display order within group |
| `metadata` | jsonb? | Extra UI config: `scaleOptions` for Scale, `{"options":[...]}` for Single/Multi Choice |
| `is_active` | boolean | Soft delete flag |

---

### `submissions`
**Rows**: 1 | **Never deleted** — core business record

A completed (or in-progress) audit execution.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique submission ID |
| `template_id` | UUID (FK → templates) | Which template was used |
| `store_id` | UUID? (FK → stores) | Which store was audited |
| `auditor_id` | UUID (FK → AspNetUsers) | Who performed the audit |
| `total_score` | decimal? | Final calculated score (0-100). Null when score_direction is none |
| `score_direction` | text | Direction of scoring: `down`, `up`, or `none` |
| `is_weighted` | boolean | True if points are weighted as percentages |
| `category_tag` | text | Denormalized category tag for fast filtering |
| `section_scores` | jsonb? | Per-section score breakdown: `{"Section": {"score": 82, "maxScore": 100}}` |
| `status` | text | `draft`, `completed`, `approved`, `rejected` |
| `review_status` | text? | Admin/AM review disposition |
| `void_reason` | text? | Reason for voiding the submission |
| `voided_at` | timestamptz? | When the submission was voided |
| `notes` | text? | General notes on the submission |
| `gps_lat` | decimal? | Auditor's GPS latitude at submission |
| `gps_lng` | decimal? | Auditor's GPS longitude at submission |
| `auditor_name` | text? | **Snapshot**: auditor's name at submission time |
| `auditor_email` | text? | **Snapshot**: auditor's email at submission time |
| `store_name` | text? | **Snapshot**: store's name at submission time |
| `template_title` | text? | **Snapshot**: template's title at submission time |
| `display_noun` | text? | **Snapshot**: template's display noun at submission time |
| `approver_name` | text? | **Snapshot**: approver's name at review time |
| `template_snapshot` | jsonb? | **Snapshot**: frozen template tree (groups, criteria, scoring config) at audit creation. Used by scoring engine during finalization |
| `template_version` | integer? | **Snapshot**: template version number when snapshot was taken |
| `scheduled_at` | timestamptz? | Scheduled audit date (null = immediate) |
| `completed_at` | timestamptz? | When the audit was completed |
| `created_at` | timestamptz | Draft creation time |
| `updated_at` | timestamptz | Last update |
| `row_version` | uint (xmin) | **Optimistic Concurrency Token**: Built-in xmin system column to prevent TOCTOU race conditions during finalization |

> **Snapshot Fields**: Denormalized copies of names at submission time. Ensures historical accuracy even if stores rename or users change.
>
> **Template Snapshot**: The `template_snapshot` column stores the full template structure (groups, criteria, scoring config) as JSON at audit creation time. This ensures audits are scored against the template version that existed when the audit started, even if an admin edits the template afterwards. The scoring engine reads from this snapshot during finalization, with a fallback to live DB for pre-migration drafts.

---

### `answers`
**Rows**: 0 | **Never deleted**

Individual responses to each criteria within a submission.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique answer ID |
| `submission_id` | UUID (FK → submissions) | Parent submission |
| `criteria_id` | UUID (FK → criteria) | Which criteria this answers |
| `value` | text? | `pass`, `fail`, `na`, option label (single choice), or comma-separated labels (multi choice) |
| `numeric_value` | decimal? | Fault count (for numeric criteria) |
| `is_failure` | boolean | True if this answer constitutes a failure |
| `criteria_label` | text? | Snapshot of the criteria text at answer time |
| `photo_url` | text? | Path to evidence photo |
| `note` | text? | Auditor's comment |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `action_plans`
**Rows**: 1 | **Never deleted** — workflow record

Corrective actions auto-generated from criteria that trigger action plans.
Trigger rules are configurable via `Criterion.Metadata.actionPlanTrigger`.
Legacy: `pass_fail` criteria with `non_conform` answer. Max 10 per submission.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique action plan ID |
| `submission_id` | UUID (FK → submissions) | Source audit |
| `answer_id` | UUID? (FK → answers) | Which specific failed answer triggered this |
| `store_id` | UUID? (FK → stores) | Which store needs correction |
| `status` | text | `open` → `in_progress` → `pending_verify` → `closed` / `overdue` |
| `deadline` | timestamptz? | Due date (driven by template config `actionPlanDeadlineDays`, defaults to 7 days) |
| `root_cause` | text? | SM's explanation of root cause |
| `correction_plan` | text? | SM's planned corrective action |
| `evidence_photo_url` | text? | SM's evidence of correction |
| `criteria_label` | text? | **Snapshot**: criteria text |
| `group_title` | text? | **Snapshot**: section title |
| `store_name` | text? | **Snapshot**: store name |
| `store_manager_name` | text? | **Snapshot**: SM name |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

> **Constraints**: Unique index on `(submission_id, answer_id)` to prevent duplicate action plans from double-clicks or offline sync race conditions.

---

### `program_assignments`
**Rows**: dynamic | **Never deleted**

HQ-issued, self-reported program assignments directed at specific stores. Uses the same Templates as Submissions but a separate execution lifecycle.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique assignment ID |
| `program_id` | UUID | Logical grouping ID for identical assignments across multiple stores |
| `store_id` | UUID (FK → stores) | Assigned store |
| `template_id` | UUID (FK → templates) | The checklist template to follow |
| `assigned_by_id` | UUID (FK → AspNetUsers) | HQ admin/owner who created the assignment |
| `title` | text | Program title |
| `category` | text | Program category (e.g. 'Safety', 'Marketing') |
| `deadline` | timestamptz | When the program is due |
| `status` | text | `pending`, `submitted`, `needs_revision`, `verified` |
| `rejection_comment` | text? | HQ feedback if `status == needs_revision` |
| `verified_at` | timestamptz? | When the program was marked `verified` |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |
| `row_version` | uint (xmin) | Optimistic concurrency token for status mutations |

---

### `program_evidence`
**Rows**: dynamic | **Never deleted**

Individual evidence items (photos/text) submitted by the Store Manager for a specific criteria in a program assignment.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique evidence ID |
| `program_assignment_id` | UUID (FK → program_assignments) | Parent assignment |
| `criteria_id` | UUID (FK → criteria) | The criteria being answered |
| `value` | text | Text response or label |
| `photo_url` | text? | Evidence photo URL |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `global_risks`
**Rows**: dynamic | **Soft Delete**: `is_active = false`

Company-wide risk flags that auditors can trigger independently of any specific audit template.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique risk ID |
| `label` | text | Name/Title of the global risk (e.g., "Food poisoning incident") |
| `description` | text? | Optional description/instructions |
| `is_active` | boolean | Soft delete flag |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `submission_risks`
**Rows**: dynamic | **Never deleted**

Records which global risks were triggered during a specific submission. Triggers a 0% final score and auto-generates Action Plans on the backend.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique record ID |
| `submission_id` | UUID (FK → submissions) | Parent submission |
| `global_risk_id` | UUID (FK → global_risks) | The triggered risk |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `submission_section_scores`
**Rows**: dynamic | **Cascade delete** with submission

Relational section scores exploded from `submissions.section_scores` JSONB on finalization. Enables efficient SQL GROUP BY for analytics section breakdown instead of parsing JSON blobs in C#.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique row ID |
| `submission_id` | UUID (FK → submissions) | Parent submission |
| `store_id` | UUID? | Denormalized store ID for filtering |
| `template_id` | UUID? | Denormalized template ID for filtering |
| `section_title` | text | Section name (e.g., "Food Safety") |
| `score` | decimal | Achieved score in this section |
| `max_score` | decimal | Maximum possible score |
| `ratio` | decimal? | Pre-computed `score / max_score` |
| `is_ccp_failed` | boolean | Whether a CCP criterion failed in this section |
| `weight` | decimal? | Section weight from template config |
| `created_at` | timestamptz | Row creation |

**Indexes**: `(store_id, section_title)` composite, `submission_id`

---

### `store_analytics_snapshot`
**Rows**: 1 per store | **Upserted** on submission finalization

Pre-computed KPIs per store, refreshed with 30-day rolling metrics whenever a submission is finalized. Avoids expensive real-time aggregation queries.

| Column | Type | Purpose |
|--------|------|---------|
| `store_id` | UUID (PK, FK → stores) | Store identity (1:1 relationship) |
| `avg_score_30d` | decimal | Rolling 30-day average score |
| `total_audits_30d` | integer | Count of audits in last 30 days |
| `open_action_plans` | integer | Currently open action plans |
| `overdue_action_plans` | integer | Overdue action plans |
| `last_audit_score` | decimal? | Score of the most recent audit |
| `last_audit_at` | timestamptz? | Timestamp of the most recent audit |
| `updated_at` | timestamptz | Last snapshot refresh |

**Cascade**: Deletes when parent store is deleted.

---

### `province_benchmark_snapshots`
**Rows**: 1 per province | **Upserted** via scheduled background worker

Pre-computed province-level benchmark snapshot (averages, standard deviations, radar categories). Avoids expensive real-time aggregations across thousands of audits when generating insights.

| Column | Type | Purpose |
|--------|------|---------|
| `province` | text (PK) | Province identity (e.g. "Hồ Chí Minh") |
| `category_averages` | jsonb | Breakdown of category scores (for Radar chart) |
| `overall_avg_score` | decimal | Province-wide average score |
| `std_deviation` | decimal | Standard deviation (for dynamic variance bands) |
| `total_audit_count` | integer | Total audits included in calculation |
| `last_calculated_at` | timestamptz | When the metrics were last aggregated |
| `created_at` | timestamptz | Row creation |

---

### `bod_report_snapshots`
**Rows**: 1 per day | **Upserted** via scheduled background worker

Pre-computed Boardroom Executive Dashboard metrics. A nightly background worker pre-computes data into JSONB documents to prevent real-time database load for complex OLAP queries.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique identifier |
| `date` | date | The reporting date (1 row per day) |
| `computed_at` | timestamptz | When the snapshot was computed |
| `status` | text | Status of calculation (e.g. Complete) |
| `payload` | jsonb | Full pre-computed metrics JSON tree (Leaderboards, Weakness, Aging, Productivity) |

---

### `notifications`
**Rows**: 0 | **Hard delete OK** (90-day retention)

In-app notification inbox for real-time alerts via SignalR.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique notification ID |
| `user_id` | UUID (FK → AspNetUsers) | Recipient |
| `type` | text | `audit_submitted`, `ap_status_change`, `deadline_warning`, etc. |
| `title` | text | Notification title |
| `message` | text? | Notification body |
| `reference_id` | UUID? | Link to related entity (submission, action plan, etc.) |
| `reference_type` | text? | Type of referenced entity |
| `read_at` | timestamptz? | When user read it (null = unread) |
| `created_at` | timestamptz | When it was sent |

---

### `system_logs`
**Rows**: 0 | **Hard delete OK** (90-day retention)

Administrative audit trail for tracking admin actions.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique log ID |
| `user_id` | UUID? | Who performed the action |
| `action` | text | Action type (e.g., `user_banned`, `store_created`) |
| `category` | text | Log category |
| `level` | text | Severity: `info`, `warning`, `error` |
| `message` | text | Human-readable description |
| `path` | text? | API endpoint that triggered the action |
| `created_at` | timestamptz | Timestamp |

---

### `user_groups`
**Rows**: 0

Named groups of users for template-level access control.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique group ID |
| `name` | text | Group name (e.g., "QC Auditors") |
| `description` | text? | Optional description |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `user_group_members`
**Rows**: 0 | **Junction table**

Links profiles to user groups. Unique constraint on `(user_group_id, profile_id)`.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique membership ID |
| `user_group_id` | UUID (FK → user_groups) | Parent group |
| `profile_id` | UUID (FK → profiles) | Member |
| `created_at` | timestamptz | When member was added |

---

### `template_assignments`
**Rows**: 0 | **Junction table**

Links templates to user groups for access control. Unassigned templates are visible to all.
Unique constraint on `(template_id, user_group_id)`.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique assignment ID |
| `template_id` | UUID (FK → templates) | Template being restricted |
| `user_group_id` | UUID (FK → user_groups) | Group that can see this template |
| `created_at` | timestamptz | When assignment was created |

> **Access Control Logic**: If a template has NO assignments → visible to all auditors. If it has assignments → only members of assigned groups (and admins) can see it.

---

### `system_logs`
**Soft Delete**: No (auto-purged by `ReminderService` based on `created_at`)

Admin observability and audit trail. Records sensitive actions (template CRUD, user management, submission finalization) with entity-level tracking.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique log entry ID |
| `user_id` | UUID | ID of the user who performed the action |
| `action` | text | Action identifier (e.g., `template_created`, `ban_user`) |
| `category` | text | Log category: `admin`, `audit`, `system` |
| `message` | text? | Human-readable description |
| `path` | text? | API endpoint path |
| `level` | text | Severity: `info`, `warning`, `error` |
| `entity_type` | text? | Entity being acted on: `template`, `submission`, `user`, `store` |
| `entity_id` | UUID? | ID of the entity being acted on |
| `created_at` | timestamptz | When the action occurred |

**Indexes**: `ix_system_logs_created_at` (descending), `ix_system_logs_entity_type_entity_id` (composite)

> **Convention**: Use `AuditLogger.Log()` for new audit entries — sets `Category = "audit"` and handles `ClaimsPrincipal` parsing. Existing admin handlers use inline `SystemLogs.Add` with `Category = "admin"`.

---

## ASP.NET Identity Tables (7)

These are managed automatically by the ASP.NET Identity framework. You typically don't interact with them directly.

| Table | Rows | Purpose |
|-------|------|---------|
| `AspNetUsers` | 7 | Core user accounts (email, password hash, lockout, InvalidateTokensBefore timestamp) |
| `AspNetRoles` | 0 | Identity role definitions (unused — app uses `user_roles` instead) |
| `AspNetUserRoles` | 0 | Identity user-role mapping (unused — app uses `user_roles` instead) |
| `AspNetUserClaims` | 0 | Per-user claims storage |
| `AspNetRoleClaims` | 0 | Per-role claims storage |
| `AspNetUserLogins` | 0 | External login providers (Google, Facebook, etc.) |
| `AspNetUserTokens` | 0 | Password reset / 2FA tokens |

> **Note**: The app uses a custom `user_roles` table instead of Identity's built-in `AspNetRoles`/`AspNetUserRoles` for simpler business logic. `AspNetUsers` is the only Identity table actively used.

---

## EF Core Internal (1)

| Table | Purpose |
|-------|---------|
| `__EFMigrationsHistory` | Tracks which EF Core migrations have been applied. Contains 11 migration entries. |
