# Core Project Context: Workflows & States

> This document defines the canonical state machines for Audits and Action Plans, including UI mappings and role contexts.

> [!NOTE]
> **Platform**: Flutter mobile (`lib/features/audit/`) is the primary client. PWA (`checkly-smart/`) references below are legacy. Server API is ASP.NET Core 10 (`server/`).

---

## 1. Audit Lifecycle (Primary)

The audit lifecycle tracks the progress of a submission from scheduling to final completion.

```text
[Created] --------> [SCHEDULED]
[SCHEDULED] ------> (Start on-time) ----> [DRAFT]
[SCHEDULED] ------> (Start overdue) ----> [BLOCKED]
[SCHEDULED] ------> (Date passes) ------> [OVERDUE]
[DRAFT] ----------> (Auto-save) --------> [DRAFT]
[DRAFT] ----------> (Submit) -----------> [COMPLETED]
```

### State Definitions

| Key | UI Label | UI Color | Dashboard | Allowed Roles | Context |
|:---|:---|:---|:---|:---|:---|
| `scheduled` | **SCHEDULED** | Gray | Todo | Auditor | Assigned but not yet started. |
| `scheduled` (overdue) | **OVERDUE** | Red | Todo (sorted to top) | Auditor | `scheduled_at::date < today`. Cannot be started. |
| `draft` | **DRAFT** | Blue | Doing | Auditor | In-progress. Can be resumed. |
| `completed` | **COMPLETED** | Green | Done | Read Only | Scored. Triggers action plans. |

> [!WARNING]
> **Overdue audits are blocked.** Navigating to `/audit/{id}` for an overdue scheduled audit shows a full-screen "This Audit Has Expired" block screen. The audit stays in `scheduled` status permanently.

---

## 2. Audit Review Disposition

Independent from the primary lifecycle, the review disposition runs in parallel after an audit is completed.

```text
[Audit Completed] --> [No Action]
[No Action] --------> [FLAGGED]
[No Action] --------> [APPROVED]
[No Action] --------> [REJECTED]
[FLAGGED] ----------> [APPROVED]
[FLAGGED] ----------> [REJECTED]
```

### Review State Definitions

| Key | UI Label | UI Color | Transition From | Allowed Roles | Context |
|:---|:---|:---|:---|:---|:---|
| `null` | **—** | Default | — | — | No review action taken. |
| `flagged` | **FLAGGED** | Amber | `null` | System Auto | Flagged for Admin review (e.g., GPS violation). |
| `approved` | **APPROVED** | Emerald | `null`, `flagged` | Admin | Final confirmation. Score counted. |
| `rejected` | **REJECTED** | Red | `null`, `flagged` | Admin | Final. Score **EXCLUDED** from metrics. |

> [!WARNING]
> **REJECTED** status excludes the audit score from all dashboard metrics and reporting.

---

## 3. Action Plan Workflow

Corrective tasks generated from non-conformities (failed answers) in a completed audit.

```text
[Answer Failed] --> [OPEN]
[OPEN] -----------> [PENDING VERIFY]
[PENDING VERIFY] -> [CLOSED]
[PENDING VERIFY] -> (Reject Evidence) --> [OPEN]
```

### Action Plan States

| Key | UI Label | UI Color | Dashboard | Allowed Roles | Context |
|:---|:---|:---|:---|:---|:---|
| `open` | **OPEN** | Red | Open | Store Manager | SM must fix and submit evidence. |
| `pending_verify` | **PENDING VERIFY** | Amber | Verify | AM, Admin | Evidence review required to close. |
| `closed` | **CLOSED** | Green | Done | Read Only | Issue resolved. Immutable. |

### Automated Notifications (DB Triggers)

Notifications are generated server-side by `handle_action_plan_status_change()` trigger:

| Transition | Type | Recipients | Message |
|:---|:---|:---|:---|
| `open` → `pending_verify` | `action_plan_evidence_submitted` 📸 | Auditor + AM | Evidence submitted for [criteria] at [store] |
| `pending_verify` → `closed` | `action_plan_closed` ✅ | Current SM | Action plan verified and closed |
| `pending_verify` → `open` | `action_plan_rejected` 🔄 | Current SM | Evidence rejected, please resubmit |

> [!NOTE]
> All recipient lookups are **live** (current SM/AM), not historical snapshots.

### Deadline Reminder (Scheduled Job)

`send_deadline_reminders()` runs daily via `pg_cron` at **1:00 AM UTC** (8:00 AM ICT):
- Groups open APs by submission and checks template's `action_plan_reminder_days` window
- Sends one batched `deadline_reminder` ⏰ notification per audit to the current SM
- **Dedup**: Only one reminder per submission (via `notifications.metadata->>'source_submission_id'`)

### Schedule Reminder (Scheduled Job)

`send_schedule_reminders()` runs daily via `pg_cron` at **1:05 AM UTC** (8:05 AM ICT):
- Finds scheduled audits where `scheduled_at::date = CURRENT_DATE + 1` (tomorrow)
- Sends `schedule_reminder` ⏰ notification to the assigned `auditor_id`
- **Dedup**: Only one reminder per submission (via `notifications.metadata->>'source_submission_id'`)
- **Skip**: Submissions without `auditor_id` are skipped

### Time-Based Flags

| Flag | Trigger | UI Impact |
|:---|:---|:---|
| **OVERDUE** | `status == 'open' AND deadline < NOW()` | Forced Red color & Priority sorting. |

---

## 4. Configuration Standards

| Feature | Source | Default | Range |
|:---|:---|:---|:---|
| Action Plan Deadline | `scoring_logic_config.features.action_plan_deadline_days` | 7 Days | 1-90 Days |
| Deadline Reminder | `scoring_logic_config.features.action_plan_reminder_days` | 2 Days | 1-30 Days |
| Confirm Required | `scoring_logic_config.features.confirm_required` | false | true/false |

> [!NOTE]
> Both are configurable per template within the Template Builder. The reminder fires X days **before** the deadline.

---

## 5. Action Plan Creation Rules

When a submission is completed (via `CreateSubmission` or `FinalizeSubmission`), `ActionPlanService.AutoCreateAsync` evaluates answers via `ActionPlanEvaluator` and creates one AP per triggered answer.

- **Survey Guard**: `scoringMode == "survey"` → **no APs are created** (survey submissions are data-collection only)
- **Trigger Rules**: Evaluated by `ActionPlanEvaluator.GetTriggeredAnswers()` using per-criterion `metadata.actionPlanTrigger` config:
  - `value_equals` (e.g., `"fail"`, `"non_conform"`) — matches exact answer values
  - `numeric_lt` / `numeric_gt` — threshold triggers for `scale` and `numeric` inputs
  - **Legacy default**: `pass_fail` criteria with `value = "non_conform"` (no explicit trigger config needed)
- **Smart Triggers (Criticality & Overrides)**:
  - **Manual Override**: If an auditor explicitly flags an answer during the audit (`answer.IsRisk = true`), it **unconditionally** triggers an action plan.
  - **Global Risk**: If the auditor triggers a template-agnostic Global Risk from the Risks panel, it **unconditionally** triggers an action plan for each risk, mapping the `GlobalRisk.Label` to the action plan's `criteria_label`.
  - **Critical Context**: If a criterion is globally flagged as `IsCcp` or `IsRisk`, AND the auditor attaches a negative signal (Note, Photo, or Repeats > 0), it triggers an action plan **even if the answer itself is marked as "pass/conform"**. This acts as a backstop for auditor error.
- **Idempotency**: Skips if action plans already exist for that submission
- **Deadline**: `NOW + N days` where N = `template.scoring_logic_config.features.action_plan_deadline_days` (default: 7, range: 1–90)
- **Cap**: Max 10 APs per submission
- **Snapshots**: `store_name`, `store_manager_name`, `criteria_label`, `group_title`

---

## 5.5. Score Verification Pipeline

Server-side re-computation of audit scores to detect tampering (spoofed `p_total_score` in `finalize_audit`).

### Phase 1: Observe (Async, Fire-and-Forget)
- **Trigger**: `handle_submission_completion` calls `net.http_post()` (pg_net) to `verify-score` Edge Function
- **Timing**: After submission status update (non-blocking)
- **On mismatch >5%**: Logs `SCORING_MISMATCH` to `system_logs`
- **On match**: No action

### Phase 2: Enforce (Synchronous, Blocking)
- **Location**: Inside `finalize_audit` RPC, between answer upsert and submission UPDATE
- **Method**: `extensions.http_post()` (synchronous HTTP extension)
- **On mismatch >5%**: `RAISE EXCEPTION` → submission rejected, `SCORING_MISMATCH_REJECTED` logged
- **On match**: Proceeds to UPDATE
- **Fail-open**: Network/timeout errors do NOT block submissions

### Kill Switch (Vault)

| Secret | Value | Behavior |
|:---|:---|:---|
| `score_verification_mode` | `observe` | Phase 1 only (log, never block) |
| `score_verification_mode` | `enforce` | Phase 2 (block + reject mismatches) |

### Technical References
- **Edge Function**: `supabase/functions/verify-score/index.ts` (inlined scoring engine)
- **Phase 1 trigger**: `handle_submission_completion` (pg_net async)
- **Phase 2 RPC**: `finalize_audit` (http extension sync)
- **Extensions**: `pg_net` (async), `http` (sync)

---

## 6. Impact on Dashboard Statistics

> [!IMPORTANT]
> **Action plans do NOT affect audit scores.** The `submissions.total_score` is permanently set at finalization. Action plans only affect the metrics below.

| Dashboard | Metric | Source |
|:----------|:-------|:-------|
| **Admin** | `totalOpenAPs` | Count of `action_plans` where `status = 'open'` |
| **Admin** | `overdueActionPlans` | Subset of open APs where `deadline < now` |
| **Admin** | `overdueScheduled` | Count of `submissions` where `status = 'scheduled' AND scheduled_at::date < today` |
| **SM** | `openFixes` | Count of non-closed APs for store (`status != 'closed'`) |
| **SM** | `overdueFixes` | Subset where `deadline < now` |
| **SM** | `nearestDeadline` | Earliest upcoming deadline |
| **Actions Page** | Metrics by status | Independent counts from `action_plans` table |

### Technical References
- **Creation trigger**: `handle_submission_completion` (DB function on `submissions`)
- **Status change trigger**: `handle_action_plan_status_change` (DB function on `action_plans`)
- **Service layer**: [actionPlanService.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/entities/action-plan/api/actionPlanService.ts)
- **Dashboard analytics**: [analyticsService.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/entities/analytics/api/analyticsService.ts) — `getAdminKPIs()`, `getStoreManagerKPIs()`

---

## 7. Offline & Sync Architecture

The app is designed for field auditors with unreliable connectivity. Users must **log in while online**, then can work offline for the remainder of their session.

### Storage Layers

| Layer | Technology | What It Stores | Cleared on Logout? |
|:------|:-----------|:---------------|:-------------------|
| **Outbox** | SQLite (Drift) | Queued submissions, action plan evidence, photos | ❌ No — survives logout |
| **Drafts** | SQLite (Drift) | In-progress audit answers, template drafts | ❌ No |
| **Query Cache** | Drift / Memory | Cached API responses (templates, stores, submissions) | ✅ Yes |
| **Auth Session** | SecureStorage | Cached role/status & JWT for instant remount | ✅ Yes |

### What Works Offline

| Feature | How |
|:--------|:----|
| App loads | Native Flutter app initialization |
| Start a new audit | Templates + stores cached via Drift sync |
| Fill in answers | Draft saved locally via `AuditManager` |
| Submit audit | Queued to `PendingSubmissions` Drift outbox |
| Submit evidence | Queued to `PendingActionPlanUpdates` outbox |
| Execute programs | Queued to `PendingProgramSubmissions` outbox |
| Take photos | Saved to local filesystem + DB outbox references |

### What Requires Internet

Login, logout, viewing new notifications, uploading evidence photos, accessing data never previously cached.

### Sync Engine (`syncEngine.ts` / `SyncEngine` in Flutter)

When connectivity returns:
1. **Heartbeat check** — pings server (protects against captive portals / liar-fi)
2. **FIFO processing** — outbox mutations processed in order
3. **Same API** — uses same RPCs as online paths (e.g., `finalize_audit`)
4. **Auth-aware** — pauses if session is expired, resumes after refresh
5. **Conflict Recovery** — if a terminal state conflict occurs (e.g., `409 Conflict` because an Action Plan is already closed), the SyncEngine marks the local outbox entry as `stale_conflict` instead of deleting it. This allows the user to manually recover their rejected offline work via the UI.

> [!IMPORTANT]
> **Offline data is never deleted by the app.** Queued submissions survive logout, token expiry, and even 7+ days offline. Rejected data (due to state conflicts) is preserved as `stale_conflict`.

---

## 8. Cache Strategy

React Query manages server state with an **offline-first** approach (`networkMode: 'offlineFirst'`).

### Cache Lifecycle

| Event | Behavior |
|:------|:---------|
| **Login** | `queryClient.invalidateQueries()` — forces fresh data fetch |
| **Tab switch** | `refetchOnWindowFocus: true` — refetches stale queries on return |
| **Background** | Queries refetch based on per-entity `staleTime` |
| **Logout** | `clearUserCache()` — clears React Query cache + localStorage persisted cache |

### Per-Entity Freshness

| Query Key | staleTime | gcTime | Rationale |
|:----------|:----------|:-------|:----------|
| `templates` | 5 min (default) | ∞ | Reference data, rarely changes, critical for offline |
| `stores` | 5 min (default) | ∞ | Reference data, rarely changes, critical for offline |
| `notifications` | 2 min | default | Should feel responsive but not excessive |
| `audit-metrics` | 10 min | default | Mutation-driven invalidation covers own writes |
| `submissions` | 10 min | default | Mutation-driven invalidation covers own writes |
| `action-plans` | 10 min | default | Mutation-driven invalidation covers own writes |
| `programs` | 5 min | default | HQ-issued assignments need relatively fresh views |
| `program-assignments` | 5 min | default | Individual store assignments cache |

### Technical References
- **Query client config**: [queryClient.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/lib/queryClient.ts)
- **Cache cleanup**: `clearUserCache()` in `queryClient.ts`
- **Auth integration**: [useAuth.tsx](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/hooks/useAuth.tsx) — calls `clearUserCache()` on logout, `invalidateQueries()` on login

---

## 9. App Lifecycle Manager

Manages session recovery when the app resumes from background, based on how long the user was away.

### Recovery Tiers

| Tier | Duration | Action | User Impact |
|:-----|:---------|:-------|:------------|
| **0** | < 5 min | No-op | None — instant resume |
| **1** | 5 min – 12 hrs | Silent auth check + selective query invalidation | None — refreshes only stale data |
| **2** | 12 hrs – 7 days | Full recovery — re-validates session, refreshes profile, invalidates all queries | Brief loading possible |
| **3** | > 7 days | Redirect to login page | User must log in again |

### Key Rules
- **Never blocks UI** — user always sees last-known screen during recovery
- **Network-aware** — skips recovery calls when offline
- **Debounced** — 500ms debounce prevents rapid toggles (Android pattern)
- **JWT expiry**: Access token lasts **24 hours** — covers a full work day without token renewal

### Technical References
- **Hook**: [useAppLifecycle.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/hooks/useAppLifecycle.ts)
- **Mounted in**: `AppContent` (single instance)

---

## 10. Entity Activity History

The system tracks key actions (SM transfers, user edits, store changes) via `system_logs` and surfaces them in two places:

### Admin View (Embedded in Edit Dialogs)
- **Component**: [EntityActivityLog.tsx](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/components/admin/EntityActivityLog.tsx)
- **Where**: Edit Store dialog, Edit User dialog (as an accordion)
- **Data**: Queries `system_logs` filtered by `entity_type` + `entity_id`

### Self-History (All Roles)
- **Page**: [ActivityHistory.tsx](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/pages/ActivityHistory.tsx) at `/activity`
- **Data**: Queries `view_system_logs_with_users` (RLS-filtered to current user)
- **Features**: Client-side search, progressive pagination, detail sheet

### Technical References
- **Service**: [systemLogService.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/entities/notification/api/systemLogService.ts) — `getEntityLogs()`, `getMyActivityLogs()`
- **Menu**: Profile page → "My Activity" menu item (all roles)
- **Preloading**: `useRoutePreloader.ts` includes `ActivityHistory` for all 4 roles

---

## 11. Template Wizard Workflow & Constraints

This section maps the UI widgets and logical constraints enforced during template creation based on the user's initial Blueprint choice (Audit, Assessment, Survey, Checklist).

### Visual Literal UI Element Map
*(This mindmap breaks down the exact UI widgets, buttons, and inputs per screen based on your Blueprint Selection)*

![UI Element Mindmap & Guide with Examples](https://www.plantuml.com/plantuml/png/rLRRJjj047ttLynBwoGj9TnU8eJ8nK1KRi9G-X09RUo9lMAzQ-skWRJgJ_G7glvXFw6pYHrY6gfAHQhwailCUCxCcJaZxnlBjCsuZ3EMUxl6JWNkULB529yzW1FsmBCYk-QnJM5pf-rzyNRNow0MN6AM2sOHhladfkEHR5mD8H2OeRJqQ0wluR3WCJQzLWlESikLDB11raqAxHOnjx0ENMFG6FU82sj1Q367ZGuzpoKCvKGvQmly1TWfoz0dJrxOqZL04sa-orztz2a-KNhgmq2hF5RtyX5YiqFVkeXieR4C3p5oEPOHJEbw0zquXZB0XvwLSyUy2pyiaWIDnHZwAS-D_mYpLNOIHXfHFW7wwCCHiXXr3QMlkKLTnwaAACPhoqKu7kdVtOnY5_VZszVlC4025YhX4IWffkz6CdZeLCL3upstKOgo2MjxBY4qpZN5TpMoPWtif12Mvm8NPImwwYbhLGPXYcW9pJ8kAg8MnSCn6wEepsFs6owdEULqH2qNFMUIIigPCJSJIWcDlgAPSoOZR8xauwAuA1CnWT0ur2pcCgaAFrTSMbE2GkF3C1psZeCQEKTCcnGrv2YPi1KvE-tS6fWe3UaquIZnBMpCJ8NaPCsgxlhdFbog977OgxAxFJCBgasaD89Lq7vLubn9cdQar2sjoWaogl70aGVLJ4gS2svk_mHeJjglCASA3ZZPWWU-W0YaTQRGKl2IrBOx54fKm0NUSRol4GbxqFOXq9fuwJ4foqKjImYa8UqO0bO2CcPJf0zESm739cYdPQgk4EeU-gGfpQgUAXtmH38dm2VsGw76bEPvjXSXpn3b2PmGBtHxlENRiqMtPviq4nRw3gTqVFefHhU2c__ozfHTlD3nSUsMGoQ6_91sYeG5CJTiB33sctznemPbaje67oWTqVPCY5Xm8vZBRyACXPXP1YHqFVs71wcarzqQ8aBWJPGg7k58BfRcoRMwaZCXniySewFXO12SDbTTahghljDBljy9TjQSWJEwzoiK-s8gh5UwKeHLo3xIIyNynU8d)

---

### Detailed Step Differences

Steps 2, 3, and 4 change based on Option 1-4. Steps 1 and 5 stay visually identical across all modes.

#### Step 1: Name & Category
**Blueprint Impact:** None. All 4 options render identically.
*   **Input Field:** `Template Name`
*   **Input Field:** `Description (optional)`
*   **Dropdown:** `Category` 

---

#### Step 2: Structure
**Blueprint Impact:** Only changes the text inside the *ActionChips*.
*   **Header text:** "Define your template sections"
*   **List of Input Fields:** `Section Name` (Defaults to 1 blank row)
*   **Button:** `+ Add Section` (Ghost Add Button)
*   **Header:** "Suggested topics:"
*   **List of ActionChips:** (Text changes based on mode: Audit topics vs Survey topics)

---

#### Step 3: Build Criteria
**Blueprint Impact:** Toggles the "Points" UI text, Info Banners, and Sub-section capability.

**3A. The Main Screen (Inline View)**
*   **Top Navigation:** Horizontal list of `ChoiceChips` (Section 1, Section 2, etc.)
*   **Header Text:** E.g., "Section 1 of 2", "[Section Name]", "[X] criteria"
*   **Condition Banner:**
    *   *If Option 1 or 2 (Audit/Assessment):* **Hidden.**
    *   *If Option 3 (Survey):* **Visible.** "Survey Mode — Sub-sections and scoring logic are disabled."
    *   *If Option 4 (Checklist):* **Visible.** "Checklist Mode — Keep it flat with Pass / Fail or choice inputs."
*   **Rows area:** List of `CriterionEditor` rows (if any have been added).
    *   Each row shows: Criterion text, Input Type text.
    *   *If Option 1 or 2:* Shows **[X] pts** text next to the criterion.
    *   *If Option 3 or 4:* Points text is **hidden**.
*   **Button:** `+ Add Criterion` (Ghost Add Button)
*   **Divider:** `— OR —`
*   **Button:** `+ Add Sub-Section` (Ghost Add Button)
    *   *If Option 1 or 2:* **Visible** and clickable.
    *   *If Option 3 or 4:* **Visible but Disabled** (Clicking shows a toast: "Sub-sections require Penalty or Accumulation mode").
    *   💡 **Guidance Note (Structural Layout)**: 
        *   **When to use Sub-sections:** Use them *only* for deep logic in Audits (Option 1). **Example:** Section: "Kitchen" -> Sub-section: "Prep Area" -> Criterion: "Temp Check".
        *   **When NOT to use:** If your tool is a flat Checklist (Option 4) or Survey (Option 3), sub-sections will unnecessarily complicate data analysis. Keep it flat.
*   **Button:** `Add Multiple Criteria` (Outlined Button)
*   **Header:** "Suggested criteria:"
*   **List of ActionChips:** (Suggestions filtered by Section Name and Blueprint mode)

**3B. The Criterion Editor (Bottom Sheet Drawer)**
*(This modal slides up when you tap "+ Add Criterion" or tap an existing row)*

*   **Header:** "Edit Criterion"
*   **Input Field:** `Criterion Label`
*   **Input Field:** `Description (optional)`
*   **Button:** `Input Type` ActionChip (Opens a secondary modal to pick pass/fail, text, scale, etc.)
    *   💡 **Guidance Note (Best Practices):** 
        *   **For Audit (Option 1):** Rely heavily on `pass_fail` to ensure binary compliance data. **Example:** *Is the prep area clean?* (Yes/No)
        *   **For Assessment (Option 2):** Use the `scale` type (Maturity Matrix) to grade performance. **Example:** *Team Hygiene Culture* (1-star, 2-stars, 3-stars)
        *   **For Survey (Option 3):** Exclusively use `single_choice` and `multi_choice` to collect standard feedback. **Example:** *Facility Satisfaction* (Good, Neutral, Poor)
*   **Points Input & Advanced Config Zone:**
    *   *If Option 1 or 2 (Audit/Assessment) AND Input Type = Pass/Fail:* 
        *   **Input Field:** `Points` (Default: 10)
    *   *If Option 1 or 2 AND Input Type = Scale:*
        *   **List of Rows:** `Label` and `Pts` inputs for each scale step.
    *   *If Option 3 or 4 (Survey/Checklist):*
        *   The Points input field is **completely hidden from the screen.**
    *   💡 **Guidance Note (Scoring):** If using Penalty mode, larger point values mean a harsher punishment for failing that item. **Example:** A minor uniform fault loses `10pts`, but a major hygiene fault loses `50pts`.
*   **Feature Flag Toggles:**
    *   *If Option 1 or 2 (Audit/Assessment):*
        *   **Toggle Switch:** `Critical Control Point (CCP)` (Visible if global feature enabled)
        *   **Toggle Switch:** `High Risk Item` (Visible if global feature enabled)
    *   *If Option 3 or 4 (Survey/Checklist):*
        *   Both toggle switches are **completely hidden from the screen.**
    *   💡 **Guidance Note (Combining CCP & RISK):**
        *   **Use CCP for local failure:** Combine a CCP toggle with `pass_fail` hygiene/safety checks. Failing it instantly drops the *Section* score to 0%, but the rest of the audit survives. **Example:** Undercooked Meat (Fails the entirety of the 'Kitchen' section, but 'Dining Room' passes).
        *   **Use RISK for system failure:** Combine a RISK toggle with `pass_fail` life-safety or legal violations. Failing it instantly drops the *entire Audit* score to 0%. **Example:** Blocked Fire Exit (Fails the entire store audit instantly).

---

#### Step 4: Review
**Blueprint Impact:** Changes mathematical validation and toggles "Advanced Config" rows.

*   **Header:** "Final Review"
*   **Validation Banner:**
    *   *If Option 1 or 2:* Enforces "Every scored criterion must have points > 0".
    *   *If Option 3 or 4:* Only enforces "Must have labels". Math checks are skipped.
    *   💡 **Guidance Note (Validation Gates):** If the screen flashes red, you likely left a scoring gap. **Example:** You added a `pass_fail` item but left points at `0`. The system mathematically verifies your template here so a broken tool never reaches your field auditors.
*   **Card:** "Structure Summary" (Lists sections and items)
*   **Card:** "Advanced Settings"
    *   **Toggle Switch:** `Allow Camera Uploads`
    *   **Toggle Switch:** `Require Assessor Signature`
    *   *If Option 1 or 2 (Audit/Assessment):*
        *   **Toggle Switch:** `Enable Global CCP`
        *   **Toggle Switch:** `Enable Global Risk Flags`
    *   *If Option 3 or 4 (Survey/Checklist):*
        *   The two toggles above are **completely hidden from the screen.**

---

#### Step 5: Success
**Blueprint Impact:** None. All 4 options render identically.
*   **Animation:** Green Checkmark
*   **Header Text:** "Template Created Successfully"
*   **Button:** `Go to Template Dashboard`
*   **Button:** `Start Audit Now`

---

## 12. Template Structural Combinations & Gating Rules

The blueprint chosen in Step 1 strictly dictates what mathematical points, structural depth (sub-sections), and input types are allowed. The UI actively gates users to ensure they cannot create broken or logically invalid templates.

### The Combination Rules Matrix

| Blueprint Option | Sub-sections Allowed? | Points/Weights Allowed? | CCP & Risk Allowed? | Recommended Input Types |
| :--- | :--- | :--- | :--- | :--- |
| **1. Audit (Penalty)** | ✅ Yes (Deep) | ✅ Yes | ✅ Yes | `pass_fail`, `number` |
| **2. Assessment (Accum.)** | ✅ Yes (Deep) | ✅ Yes | ✅ Yes | `scale` |
| **3. Survey** | ❌ No (Flat) | ❌ No | ❌ No | `single_choice`, `multi_choice`, `text` |
| **4. Checklist** | ❌ No (Flat) | ❌ No | ❌ No | `pass_fail`, `signature`, `text` |

*(Note: "Flat" means criteria attach directly to the Section, you cannot create a folder inside a folder).*

### Visual Structural Trees

This 4-branch architectural mindmap demonstrates exactly how these templates look when fully built out, showing the difference between deep, math-heavy audits and flat, point-blind surveys and checklists.

![Template Combination Map](https://www.plantuml.com/plantuml/png/VPNFRjf04CRlFCMSgWI1oBzUK2E5cDAWb0HXeXnQ52sxOtk5lUlkhabugpv3dwop1bF0LcyOptupy_jcntVMCUCogKJ6ybORvfZbANC80yCJwP2xmg1jjTfjUCwTr0ek-p0eX7HmDaJCEp15nLAtWGbpoJd5jI6aKxl8H-buWWe-GSWYT1l_dWAAPTVkWWPz27Gg87JQi1ZBW3O4XdARdSZ8I16ZXIzmy-Tty5Fzo9crRn6JQGS-N-JETY08fhVFJukw_7qVlajLbxtgmzSF9rLSI9kWEHQzlDYgpiRXOoMxxufE3gMYap3JEeEp4U4wRvt8NrFLgTR6Wdt7t9tAa_gnACKF1Ba0PsCLQSBbQK8cFr3Kj6_wC97MeW2RoCXPuBfGFeKgiYKQOaBo850KfVRYzFpdFdn3XOQbyAGTMZhfyCDrm9S5FNXHbck3Od7eEdKze9pMPgZsrWyuBxA2-fThRFO_AApJ6Hhwpwmbnvf1tdq_SL8vs-Jz4BjeEVCvjA9A_M_imtLtoGmvTELxxPL0UtMgL7IO8u6Qe3EIsrPz28Q6Qk_E4rF0N6RuByE8MTSRhEDUcEhtcbbJeoE2GKyibJPhiFyLgK1GB4F7ufEPzPpPEpEYX9nYvC1AWOUyII4ip1etsm7hR36XmtIpDwX6-rMR5OrrJaMWgc0VuPpf5EagEcaZnYkaDCifll54aq5qdxNtulP12e7ruI5auomtUetb88m5icg0QkplQSeYIRs-sEfc7pEQebbPA6YKIO86oSbT5JNU4wP8mi28t5molcgu4zKhY0p-AgZ_pMblJJUX4funlmmg-siK3foXL462V4M-kygSChfxdz8Q9Vx82nzPisTaD27J4Jnewhd1dHULQcf0-CLnF39rKmv11ymcyC2Ke0BY1iVyxWKlNOBUoouQB9dBD0KXBJUOiot3QgtyfmQ_xYHT1GXbhBewYXhyUSwnt9exugKviMB--x9etQ4Iku_GNm00)

### Detailed Real-World Scenarios

#### The Deep Audit (Blueprint Option 1)
**Scenario**: Monthly Store Hygiene & Safety Audit.
**Goal**: Start at 100% and mathematically deduct points for every failure. Needs deep hierarchy because a store is physically large.
*   **Template:** "Monthly Hygiene Audit" (Penalty Mode)
    *   **Section 1: Kitchen & Food Safety** (Deep Structure required for spatial breakdown)
        *   **Sub-section A: Cold Storage**
            *   👉 *Criterion 1:* "All fridges are operating below 4°C"
                *   **Input Type**: `pass_fail`
                *   **Points Input**: `50 pts` (Heavy penalty)
                *   **Flags**: `Critical Control Point (CCP) = ON` *(Rationale: If fridges fail, the entire "Kitchen" section is compromised and drops to 0%, but the Dining Room can still pass).*
            *   👉 *Criterion 2:* "Temperature logs are signed by manager"
                *   **Input Type**: `pass_fail`
                *   **Points Input**: `10 pts` (Minor admin penalty)
                *   **Flags**: None
        *   **Sub-section B: Cooking Line**
            *   👉 *Criterion 3:* "Fire extinguishers are unblocked and certified"
                *   **Input Type**: `pass_fail`
                *   **Points Input**: `100 pts` 
                *   **Flags**: `High Risk Item = ON` *(Rationale: Strict legal/safety violation. Failing this drops the entire Audit score to 0% instantly).*
    *   **Section 2: Dining Room** *(Example of mixing deep and flat structures)*
        *   👉 *Criterion 4:* "Floors are swept and mopped"
            *   **Input Type**: `scale` (e.g., 3-stars)
            *   **Points Input**: `[3-stars: 0pt deduction], [2-stars: 5pt deduction], [1-star: 15pt deduction]`

#### The Assessment (Blueprint Option 2)
**Scenario**: Quarterly Team Review.
**Goal**: Start at 0% and accumulate points based on performance.
*   **Template:** "Q3 Team Performance Assessment" (Accumulation Mode)
    *   **Section 1: Customer Service Culture**
        *   **Sub-section A: Handling Complaints**
            *   👉 *Criterion 1:* "De-escalates angry customers"
                *   **Input Type**: `scale` (Maturity matrix styling)
                *   **Points Input**: `[Needs Training: 0pts], [Capable: 10pts], [Expert: 25pts]`
        *   **Sub-section B: Greeting Operations**
            *   👉 *Criterion 2:* "Greets customers within 10 seconds"
                *   **Input Type**: `pass_fail`
                *   **Points Input**: `15 pts` (Awarded if passed)
    *   **Section 2: Speed Metrics** *(Flat Structure)*
        *   👉 *Criterion 3:* "Drive-Thru Time Average"
            *   **Input Type**: `scale` (Options: Fast, Avg, Slow)
            *   **Points Input**: `[Fast: 20pts], [Avg: 10pts], [Slow: 0pts]`

#### The Flat Survey (Blueprint Option 3)
**Scenario**: Employee Satisfaction Feedback 2026.
**Goal**: purely collect qualitative feedback. No math, no compliance, no punishments.
*   **Template:** "Employee Satisfaction 2026" (Survey Mode)
    *   **Section 1: Work Experience** *(UI completely disables Sub-sections to keep data clean)*
        *   👉 *Criterion 1:* "How satisfied are you with your role?"
            *   **Input Type**: `single_choice` (Options: Very Satisfied, Neutral, Not Satisfied)
            *   **UI Restraint**: Points input is completely **hidden**. CCP/Risk toggles are **hidden**.
        *   👉 *Criterion 2:* "What tools do you need to do your job better?"
            *   **Input Type**: `text`
    *   **Section 2: Manager Feedback**
        *   👉 *Criterion 3:* "Manager Leadership Rating"
            *   **Input Type**: `scale` (1-star, 2-star, 3-star)
            *   **UI Restraint**: Points input is completely **hidden**.

#### The Flat Checklist (Blueprint Option 4)
**Scenario**: Daily Opening Procedures.
**Goal**: Fast, binary compliance. The UI forces everything to be "flat" and hides point weights to keep it fast.
*   **Template:** "Daily Opening Duties" (Checklist Mode)
    *   **Section 1: Front of House (FOH)** *(UI completely disables Sub-sections)*
        *   👉 *Criterion 1:* "Unlock main entrance doors"
            *   **Input Type**: `pass_fail`
            *   **UI Restraint**: Points field is **hidden** (User doesn't need to care about math here).
        *   👉 *Criterion 2:* "Turn on digital menu boards"
            *   **Input Type**: `pass_fail`
    *   **Section 2: Cash Handling**
        *   👉 *Criterion 3:* "Morning Till Discrepancy"
            *   **Input Type**: `number`
            *   **UI Restraint**: Points field is **hidden**.
    *   **Section 3: Sign Off**
        *   👉 *Criterion 4:* "Opening Manager Signature"
            *   **Input Type**: `signature`

---

## 13. AI Agent Orchestration & SDLC

The Checkly platform utilizes autonomous AI agents (Antigravity OS) for implementation and testing. The core engineering workflows are strictly paced to prevent context decay and hallucination.

### Key SDLC execution rules:
1. **The Paced Execution Loop**: Agents must stop generation and request human approval after the Planning phase, and again after the Coding phase. Full autonomous end-to-end execution is forbidden.
2. **Structural Diagnosis Mandate**: If an agent fails a task or compilation twice, it must halt and run a structural trace (e.g. verifying architecture routing) rather than blindly tuning code or prompts.
3. **Cheap Verifier Gates**: Before declaring a component complete or moving to intensive ATDD testing, agents must pass rapid, semantic build checks (`flutter analyze` or `dotnet build`).

> **For full AI operational rules**, refer to the `.agents/rules/orchestration-standards.md` file in the root workspace.
