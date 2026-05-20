# Checkly Audit Strategy Guide

This guide organizes the Checkly codebase into logical **Domains** and provides a roadmap for running the `/audit-code` and `/audit-infra` workflows effectively. 

Instead of auditing random folders, combine related features into domains so the AI can track dependencies and architectural boundaries across both the Flutter frontend and the .NET backend.

---

## The Three Workflows

| Workflow | Target | Purpose |
| :--- | :--- | :--- |
| **`/audit-code`** | Primarily `lib/` (Frontend) | Hunts for dead code, file bloat (>400 lines), SRP violations, architecture drift (UI talking to DB), and stale TODOs. |
| **`/audit-infra`** | `server/` + `lib/` | Hunts for dangerous EF Core cascades, missing DB indexes, missing PBAC Auth guards, N+1 query loops, and checks if the Frontend API is actually wired to the Backend. |
| **`/audit-arch`** | Cross-boundary (Sync, State, Workers) | **Hostile Red-Team Audit.** Hunts for distributed systems failure: 2 AM landmines, cache locks, split-brain state, and fake-smart cognitive debt. |

---

## Domain 1: Identity & Access Management (IAM)
**Folders to combine:** 
*   `lib/features/auth` & `server/Features/Auth`
*   `lib/features/user_groups` & `server/Features/UserGroups`
*   `lib/features/profile` & `server/Features/Users`
*   `lib/features/admin` & `server/Features/Admin`

**Recommended Workflow:** `/audit-infra`
**Why:** Auth and User Groups are high-risk security vectors. You want Sentinel to verify that PBAC (Policy-Based Access Control) role guards exist on every mutation endpoint, and that no admin data is leaking to standard users.

**Command to copy:**
> *"Run `/audit-infra` on the Identity Domain (Auth, UserGroups, Users, and Admin folders in both lib and server)."*

---

## Domain 2: Core Execution (The Heart of Checkly)
**Folders to combine:** 
*   `lib/features/audit` & `server/Features/Submissions` *(Note: `audit` UI maps to `Submissions` DB)*
*   `lib/features/templates` & `server/Features/Templates`
*   `lib/features/action_plans` & `server/Features/ActionPlans`
*   `server/Features/Photos`

**Recommended Workflow:** `/audit-infra` (First) -> `/audit-code` (Second)
**Why:** This domain handles the most data. `/audit-infra` is critical here to check for **Unbounded OOM risks** (fetching thousands of submissions without pagination) and missing EF Core DB indexes on high-frequency tables. Afterwards, run `/audit-code` on the UI to ensure the complex audit screens aren't bloated past 400 lines per file.

**Command to copy:**
> *"Run `/audit-infra` on the Core Execution Domain (Templates, Submissions/audit, ActionPlans, Photos)."*

---

## Domain 3: Organizational Hierarchy
**Folders to combine:** 
*   `lib/features/stores` & `server/Features/Stores`
*   `lib/features/programs` & `server/Features/Programs`

**Recommended Workflow:** `/audit-code`
**Why:** These are usually heavy UI configuration screens. Running `/audit-code` will ensure the forms aren't duplicating validation logic, that state management is clean, and that there are no exposed secrets or dead code branches.

**Command to copy:**
> *"Run `/audit-code` on the Organization Domain (Stores and Programs in lib and server)."*

---

## Domain 4: Observability & Engagement
**Folders to combine:** 
*   `lib/features/dashboard`
*   `lib/features/analytics` & `server/Features/Analytics`
*   `lib/features/notifications` & `server/Features/Notifications`

**Recommended Workflow:** `/audit-infra`
**Why:** Dashboards and Analytics run heavy read-queries. You need `/audit-infra` to hunt for **N+1 Loops** (e.g., executing a query inside a `foreach` loop) and missing indexes on `GROUP BY` aggregations.

**Command to copy:**
> *"Run `/audit-infra` on the Observability Domain (Dashboard, Analytics, and Notifications)."*

---

## Domain 5: System Core (The Engine)
**Folders to combine:** 
*   `lib/_shared/` (Frontend core widgets, router, local DB)
*   `server/Common/` (Backend exceptions, telemetry, global rules)
*   `server/Features/System`
*   `server/Features/GlobalRisks`

**Recommended Workflow:** `/audit-code`
**Why:** This is the foundation of the app. You want `/audit-code` to ensure that standard architecture rules are strictly followed, file sizing is small, and there are zero architectural drifts (like a core widget accidentally importing a specific feature).

**Command to copy:**
> *"Run `/audit-code` on the System Core Domain (lib/_shared and server/Common)."*

---

## Domain 6: Distributed Architecture & Sync
**Folders to combine:** 
*   `lib/_shared/database` (Offline Sync / Local DB)
*   `server/Common/` (Resilience pipelines, Caching, Queues)
*   Any feature introducing background workers or complex cross-client state.

**Recommended Workflow:** `/audit-arch`
**Why:** This workflow is a brutal interrogation by the Chief Architect. It ignores standard code formatting and actively hunts for catastrophic edge cases—like what happens if a network request drops halfway through (Split-Brain), if a bad message blocks a queue forever (Poison Pill), or if 50 nodes wake up at once (Thundering Herd). Run this *before* you ship complex offline-sync or caching logic.

**Command to copy:**
> *"Run `/audit-arch` on the Offline Sync and Distributed State logic (lib/_shared/database and server/Common)."*
