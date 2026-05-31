# UX Copywriting & Semantic Tone Report | Chunk 6: Administration & Security

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 6: Administration & Security** across `lib/features/admin/` and `lib/features/user_groups/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **8 Violations** | Technical Security Jargon ("state drift", "stale security state"), User Blaming ("You do not have permission"), Weak/Generic CTAs | 🔴 High |

---

## Detailed Violations & Recommendations

### 🔐 1. lib/features/admin/

#### `widgets/offline_detail_lock_view.dart`
> [!WARNING]
> Uses developer/architect jargon ("security state drift") that is completely abstract and confusing to business users.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Capability changes are online-only to prevent security state drift.` | `Changing permissions requires an internet connection to keep security settings synchronized.` | **Rule 1: No Developer Jargon** | End-users do not understand "state drift". Phrasing it as "keeping security settings synchronized" is clear, natural, and helpful. |

---

#### `widgets/offline_lock_view.dart`
> [!WARNING]
> Exposes developer vocabulary ("stale security state") to explain a simple online requirement.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Role management is online-only to prevent stale security state.` | `Role management requires an internet connection to keep security settings up to date.` | **Rule 1: No Developer Jargon** | End-users do not understand "stale security state". Focus on the positive outcome (keeping settings up to date). |

---

#### `pages/schedule_audit_page.dart`
> [!WARNING]
> Uses accusatory and direct language ("You do not have...") instead of a neutral capability statement.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `You do not have permission to schedule audits.` | `Scheduling audits requires administrator permissions.` | **Rule 2: Blame-Free Error States** | Instead of pointing a finger at the user's lack of permission, neutrally state what the requirement is. |

---

#### `pages/audit_approval_page.dart`
> [!NOTE]
> Uses cold error language and a generic weak CTA button ("Retry").

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Error loading audits` | `We couldn't load the audit list. Please try again.` | **Rule 2: Blame-Free Error States** | Make error screens softer and blame-free using "We couldn't...". |
| `Retry` | `Try Again` | **Rule 3: CTA Verbs** | "Try Again" is a warmer, more user-friendly action verb than a cold "Retry". |

---

#### `widgets/user_management_dialogs.dart` & `pages/widgets/risk_form_sheet.dart`
> [!NOTE]
> Uses raw, isolated action verbs ("Deactivate", "Reset") on confirmation dialogs that can lead to accidental taps.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Deactivate` (Deactivate User?) | `Deactivate User` | **Rule 3: CTA Verbs** | In a deactivation confirmation context, "Deactivate User" is much more explicit and prevents action slip errors. |
| `Deactivate` (Deactivate Risk?) | `Deactivate Risk` | **Rule 3: CTA Verbs** | Explicit context-rich action buttons reduce confirmation slips. |
| `Reset` (Reset Password?) | `Reset Password` | **Rule 3: CTA Verbs** | Make it highly clear what is being reset on tap. |

---

## 💎 Best Practices & Quick Reference

### 1. Security Framing
When explaining online constraints, always avoid database/system jargon (e.g., `state drift`, `stale`, `volatile cache`). Instead, frame it around transparency and synchronization (e.g., `keep settings up to date`, `synchronized`).

### 2. Dialog Actions
Never use single-word buttons like `Deactivate`, `Reset`, `Delete` in warning dialogs if they can be expanded to full, context-aware verb phrases (`Deactivate User`, `Delete Store`).
