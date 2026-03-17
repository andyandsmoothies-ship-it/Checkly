# Checkly Database Schema Reference

> **Database**: PostgreSQL 18.3 | **ORM**: Entity Framework Core 10 | **Schema**: `public`

---

## Table Overview

The Checkly database contains **19 tables** organized into 3 categories:

| Category | Tables | Purpose |
|----------|--------|---------|
| **Business Domain** | 11 tables | Core audit workflow data |
| **ASP.NET Identity** | 7 tables | Authentication & identity infrastructure |
| **EF Core Internal** | 1 table | Migration tracking |

---

## Business Domain Tables (11)

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
| `area_id` | UUID? (FK → areas) | Assigned area (for Area Managers) |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last modification |

> **Key Relationships**: A Store Manager has `store_id` set. An Area Manager has `area_id` set. Admins and Auditors have both null (global access).

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

### `stores`
**Rows**: 6 | **Soft Delete**: `is_active = false`

Physical store locations where audits are conducted.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique store ID |
| `name` | text | Store name (e.g., "Cửa hàng Quận 1") |
| `address` | text? | Street address |
| `area_id` | UUID? (FK → areas) | Geographic region |
| `gps_lat` | decimal? | Latitude for GPS verification |
| `gps_lng` | decimal? | Longitude for GPS verification |
| `is_active` | boolean | Soft delete flag (false = deactivated) |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `areas`
**Rows**: 0 | **Soft Delete**: `is_active = false`

Geographic regions for grouping stores and assigning Area Managers.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique area ID |
| `name` | text | Display name (e.g., "Miền Bắc") |
| `description` | text? | Optional description of the area |
| `is_active` | boolean | Soft delete flag |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `templates`
**Rows**: 3 | **Soft Delete**: `is_active = false`

Audit templates define the structure of an audit (what to check).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique template ID |
| `title` | text | Template name (e.g., "QC Monthly Audit") |
| `type` | text? | Category: `qc`, `training`, `general` |
| `is_active` | boolean | Soft delete flag |
| `version` | integer | Concurrency control (optimistic locking) |
| `scoring_logic_config` | jsonb? | Scoring rules: mode (`penalty`/`accumulation`/`checklist`/`survey`), density flags, and repeat config |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

---

### `groups`
**Rows**: 4 | **Soft Delete**: `is_active = false`

Sections within a template. Supports nesting (subsections via `parent_id`).

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique group ID |
| `template_id` | UUID (FK → templates) | Parent template |
| `parent_id` | UUID? (FK → groups, self-ref) | Parent group for subsections (null = top-level) |
| `title` | text | Section title |
| `weight` | decimal? | Section weight for weighted scoring (optional) |
| `order_index` | integer | Display order within parent |
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
| `input_type` | text | `pass_fail`, `numeric`, `scale`, `single_choice`, or `multi_choice` |
| `is_ccp` | boolean | Critical Control Point — fail = section score → 0% |
| `is_risk` | boolean | RISK item — fail = entire audit score → 0% |
| `points_weight` | decimal? | Deduction weight for standard scoring |
| `minus_per_fault` | decimal? | Deduction per fault for numeric input |
| `minus_impact` | decimal? | C4 override: uses this instead of `points_weight` |
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
| `total_score` | decimal? | Final calculated score (0-100) |
| `status` | text | `draft`, `completed`, `approved`, `rejected` |
| `review_status` | text? | Admin/AM review disposition |
| `gps_lat` | decimal? | Auditor's GPS latitude at submission |
| `gps_lng` | decimal? | Auditor's GPS longitude at submission |
| `auditor_name` | text? | **Snapshot**: auditor's name at submission time |
| `store_name` | text? | **Snapshot**: store's name at submission time |
| `template_title` | text? | **Snapshot**: template's title at submission time |
| `submitted_at` | timestamptz? | When the audit was submitted |
| `created_at` | timestamptz | Draft creation time |
| `updated_at` | timestamptz | Last update |

> **Snapshot Fields**: Denormalized copies of names at submission time. Ensures historical accuracy even if stores rename or users change.

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
| `photo_url` | text? | Path to evidence photo |
| `note` | text? | Auditor's comment |
| `created_at` | timestamptz | Record creation |

---

### `action_plans`
**Rows**: 1 | **Never deleted** — workflow record

Corrective actions auto-generated from failed criteria.

| Column | Type | Purpose |
|--------|------|---------|
| `id` | UUID (PK) | Unique action plan ID |
| `submission_id` | UUID (FK → submissions) | Source audit |
| `answer_id` | UUID? (FK → answers) | Which specific failed answer triggered this |
| `store_id` | UUID? (FK → stores) | Which store needs correction |
| `status` | text | `open` → `in_progress` → `pending_verify` → `closed` / `overdue` |
| `deadline` | timestamptz? | Due date (default: 7 days from creation) |
| `root_cause` | text? | SM's explanation of root cause |
| `correction_plan` | text? | SM's planned corrective action |
| `evidence_photo_url` | text? | SM's evidence of correction |
| `criteria_label` | text? | **Snapshot**: criteria text |
| `group_title` | text? | **Snapshot**: section title |
| `store_name` | text? | **Snapshot**: store name |
| `store_manager_name` | text? | **Snapshot**: SM name |
| `created_at` | timestamptz | Record creation |
| `updated_at` | timestamptz | Last update |

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

## ASP.NET Identity Tables (7)

These are managed automatically by the ASP.NET Identity framework. You typically don't interact with them directly.

| Table | Rows | Purpose |
|-------|------|---------|
| `AspNetUsers` | 7 | Core user accounts (email, password hash, lockout) |
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
| `__EFMigrationsHistory` | Tracks which EF Core migrations have been applied. Contains 4 migration entries. |
