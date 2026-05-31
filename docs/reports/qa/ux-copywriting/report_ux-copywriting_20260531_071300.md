# Master UX Copywriting & Semantic Tone Report | All Chunks (1-7)

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
             [MASTER UX COPYWRITING AUDIT]
                           │
  ┌────────────────────────┼────────────────────────┐
  ▼                        ▼                        ▼
Chunk 7: Analytics       Chunk 6: Admin           Chunk 5: Programs
(ux_copywriting_report)  (report_chunk6)          (report_chunk5)
  │                        │                        │
  ├────────────────────────┼────────────────────────┤
  ▼                        ▼                        ▼
Chunk 4: Action Plans    Chunk 3: Simulator       Chunks 1 & 2: Auth/Dash
(report_chunk4)          (report_chunk3)          (report_chunks1_2)
```

This master report consolidates the complete static copywriting audit across all 7 chunks of the Checkly Flutter UI codebase. It identifies every semantic violation of the Checkly UX Copywriting guidelines and provides drop-in replacement strings to elevate the platform's visual and interactive premium quality.

---

## 📊 Executive Summary

| Audit Domain | Scope (Scanned Files) | Total Violations | Critical Severity |
| :--- | :--- | :--- | :--- |
| **Chunk 7: Analytics & Store Insights** | `lib/features/analytics/`, `lib/features/stores/` | 5 Violations | 🔴 High |
| **Chunk 6: Administration & Security** | `lib/features/admin/`, `lib/features/user_groups/` | 8 Violations | 🟡 Medium |
| **Chunk 5: Program Execution & Management** | `lib/features/programs/` | 6 Violations | 🟡 Medium |
| **Chunk 4: Action Plans & History** | `lib/features/action_plans/`, `lib/features/notifications/` | 7 Violations | 🟡 Medium |
| **Chunk 3: Scoring Simulator & Builder** | `lib/features/templates/` | 6 Violations | 🔴 High |
| **Chunk 2: Dashboard & Audit Execution** | `lib/features/dashboard/`, `lib/features/audit/` | 5 Violations | 🟡 Medium |
| **Chunk 1: Authentication & Connection** | `lib/features/auth/` | 2 Violations | 🟢 Low |
| **TOTALS** | **83 Files Scanned** | **39 Violations** | **Highly Actionable** |

---

## 📋 Comprehensive Violation Catalog

### 🌐 Chunk 7: Analytics & Store Insights

#### `pages/insights_dashboard_page.dart` & related
> [!IMPORTANT]
> Raw database timeout reports and hardcoded server-level details are exposed directly to the user.

*   ❌ **Current**: `Database timeout occurred. Please try again later.`
    *   ✅ **Proposed**: `We are having trouble loading your insights. Please try again in a few moments.`
    *   🔍 **Rule violated**: **Rule 2: Blame-Free Error States**. Never expose raw network or database exceptions; frame the error as a polite invitation to try again.
*   ❌ **Current**: `HTTP 500 error`
    *   ✅ **Proposed**: `Our services are temporarily unavailable. We are looking into this now.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Server status numbers like 500 are meaningless and cold.
*   ❌ **Current**: `No stores found`
    *   ✅ **Proposed**: `No stores are assigned to your profile yet.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Cold "X not found" states sound like system search queries; phrase as helpful, business-friendly status info.

---

### 🛡️ Chunk 6: Administration & Security

#### `pages/security_audit_logs_page.dart` & related
> [!NOTE]
> Employs aggressive, raw security alert terminology and lacks active verbs.

*   ❌ **Current**: `Security state drift`
    *   ✅ **Proposed**: `Out-of-sync security credentials`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. "Security state drift" is advanced backend terminology.
*   ❌ **Current**: `Stale security state`
    *   ✅ **Proposed**: `Security settings need update`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**.
*   ❌ **Current**: `User details`
    *   ✅ **Proposed**: `Manage User Account`
    *   🔍 **Rule violated**: **Rule 3: CTA Verbs**. Navigation actions should always lead with an active, functional verb.

---

### 📋 Chunk 5: Program Execution & Management

#### `pages/program_dashboard_page.dart` & related
> [!NOTE]
> Employs lazy bracket pluralizations and accusatory directive alerts.

*   ❌ **Current**: `${a.evidence.length} evidence item(s)`
    *   ✅ **Proposed**: `a.evidence.length == 1 ? '1 evidence file' : '${a.evidence.length} evidence files'`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Parentheses pluralizations like "item(s)" feel like unpolished debug code.
*   ❌ **Current**: `Select at least 1 store.`
    *   ✅ **Proposed**: `Please choose one or more stores to continue.`
    *   🔍 **Rule violated**: **Rule 2: Blame-Free Error States**. "Select at least 1" is demanding; frame politely as instructions.
*   ❌ **Current**: `Next` / `Go back`
    *   ✅ **Proposed**: `Continue` / `Return to Campaigns`
    *   🔍 **Rule violated**: **Rule 3: CTA Verbs**. Stepper controls should be active ("Continue") and back buttons should specify their destination.

---

### 📋 Chunk 4: Action Plans & History

#### `widgets/stale_conflict_banner.dart` & related
> [!NOTE]
> Employs relational tree database terminology ("parent") and offline sync mechanics.

*   ❌ **Current**: `Your offline evidence was not synced — this plan was already closed.`
    *   ✅ **Proposed**: `This action plan was closed before your offline updates could be saved.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Remove developer terms like "synced".
*   ❌ **Current**: `This action plan was automatically closed because the parent audit was voided.`
    *   ✅ **Proposed**: `This action plan was automatically closed because the audit was voided.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. "Parent audit" exposes database schemas.
*   ❌ **Current**: `Mark this action plan as resolved? This cannot be undone.`
    *   ✅ **Proposed**: `Are you sure you want to resolve this action plan? This action is permanent.`
    *   🔍 **Rule violated**: **Rule 2: Blame-Free Error States**. "This cannot be undone" acts as a harsh system threat.

---

### 📋 Chunk 3: Scoring Simulator & Builder

#### `widgets/template_linter_panel.dart` & related
> [!IMPORTANT]
> The builder contains the most severe developer jargon in the entire app, using compiler terms directly in front of business coordinators.

*   ❌ **Current**: `Template Linter`
    *   ✅ **Proposed**: `Template Compliance Check`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. "Linter" is a pure engineering term; change to "Compliance Check" for clarity.
*   ❌ **Current**: `Bypass`
    *   ✅ **Proposed**: `Skip Checks`
    *   🔍 **Rule violated**: **Rule 3: CTA Verbs**. Replace passive systems terms with active verbs.
*   ❌ **Current**: `Blocking Errors` / `Advisory Warnings`
    *   ✅ **Proposed**: `Compliance Issues` / `Improvement Suggestions`
    *   🔍 **Rule violated**: **Rule 2: Blame-Free Error States**. Soften compiler jargon into helpful compliance recommendations.
*   ❌ **Current**: `These settings affect how audits are scored. Change with care.`
    *   ✅ **Proposed**: `These settings adjust how audit scores are calculated. Please verify details before saving changes.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Avoid scary disclaimers; explain options guidefully.

---

### 📋 Chunks 1 & 2: Auth, Dashboard & Audit Execution

#### `widgets/audit_form_dialogs.dart` & related
> [!NOTE]
> Uses device-focused terms ("GPS") and shortened metrics ("m") in high-visibility alerts.

*   ❌ **Current**: `Unverified location — ${result.distance}m from store`
    *   ✅ **Proposed**: `Location verification failed — you are ${result.distance} meters away from the store.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. Use clean descriptive wording rather than abbreviated notation.
*   ❌ **Current**: `Location unavailable — submitting without GPS`
    *   ✅ **Proposed**: `Location services are unavailable. Your audit will be saved without coordinate pinning.`
    *   🔍 **Rule violated**: **Rule 1: No Developer Jargon**. "GPS" focuses on device sensors rather than the operational outcome.
*   ❌ **Current**: `Forgot Password?` / `Got it`
    *   ✅ **Proposed**: `Reset Password` / `Continue`
    *   🔍 **Rule violated**: **Rule 3: CTA Verbs**. Replace passive questions and weak sheets-dismissal text with leading active CTAs.

---

## 💎 Checkly Copywriting System Best Practices

To maintain high-premium, state-of-the-art visual excellence, all future features must strictly adhere to the following three golden principles:

### 1. The Business Vocabulary Guide
*   **Engineering/Database Lingo**: `Syncing`, `Linter`, `Parent/Child`, `HTTP Status`, `GPS`, `m/km`, `Cache`, `Index`.
*   **Premium Business Translation**: `Saving updates`, `Compliance Check`, `Associated Item`, `Service Offline`, `Location Pinning`, `meters`, `Offline memory`, `Identifier`.

### 2. The Blame-Free Confirmation Formula
Never phrase dialog confirmations as systems warnings (e.g. `This cannot be undone.`).
*   **Formula**: `[Polite Question]? [Assuring advice of permanent state].`
*   **Example**: `Are you sure you want to delete this template? This action is permanent.`

### 3. Stepper & Wizard Action Guidelines
*   Steppers should always use `Continue` instead of a dry `Next` to lead the user forward.
*   Always implement proper dynamic conditional logic to resolve plural forms elegantly rather than using lazy placeholders like `item(s)` or `store(s)`.
