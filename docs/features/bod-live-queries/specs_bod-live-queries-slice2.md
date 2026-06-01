# Specifications: BOD Live Queries Slice 2 (Database Schema Optimization)

## Input Lineage
- **Source Input**: `C:\Users\HP\Documents\GitHub\Checkly\docs\features\bod-live-queries\implementation_plan_bod-live-queries-slice2_20260601_152500.md`

---

## 1. Overview
This specification details the optimizations required for database tables that support the live Board of Directors dashboard query pathways. The database schema needs specific composite indexing configurations to handle aggregations, sorting, and filtering over heavy transaction tables (`submissions`, `submission_section_scores`, and `action_plans`).

---

## 2. Table Index Specifications

### 2.1 submissions
The `submissions` table stores audits performed by auditors. Aggregations on this table retrieve completed audits, calculate scores, and group them by store and date.

| Index Name | Column Pattern | Ordering | Uniqueness | Purpose |
|------------|----------------|----------|------------|---------|
| Composite A | `(status, completed_at DESC)` | status ASC, completed_at DESC | Non-unique | High-performance sorting of completed submissions. |
| Composite B | `(status, store_id, completed_at)` | status ASC, store_id ASC, completed_at ASC | Non-unique | Tenancy filter + time segment metrics queries. |

### 2.2 submission_section_scores
The `submission_section_scores` table stores section-level scoring metrics. It requires optimized access paths for daily/monthly aggregation.

| Index Name | Column Pattern | Ordering | Uniqueness | Purpose |
|------------|----------------|----------|------------|---------|
| Composite C | `(created_at, store_id)` | created_at ASC, store_id ASC | Non-unique | Segment scoring aggregates grouped by date and location. |

### 2.3 action_plans
The `action_plans` table tracks pending issues and corrective tasks. It is frequently filtered by status and deadline dates.

| Index Name | Column Pattern | Ordering | Uniqueness | Purpose |
|------------|----------------|----------|------------|---------|
| Composite D | `(status, deadline)` | status ASC, deadline ASC | Non-unique | Fast count of open, pending, or overdue tasks. |
