# UX Copywriting & Semantic Tone Report | Chunk 4: Action Plans & History

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 4: Action Plans & History** across `lib/features/action_plans/`, `lib/features/notifications/`, and related pages in `lib/features/audit/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **7 Violations** | Developer Jargon ("synced", "parent audit", "syncing"), Threat-based validation ("This will permanently void"), Passive directionals ("Go Back") | 🟡 Medium |

---

## Detailed Violations & Recommendations

### 📋 1. lib/features/action_plans/ & lib/features/notifications/

#### `widgets/stale_conflict_banner.dart`
> [!NOTE]
> Uses developer-heavy synchronization terminology that is confusing to non-technical users.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Your offline evidence was not synced — this plan was already closed.` | `This action plan was closed before your offline updates could be saved.` | **Rule 1: No Developer Jargon** | Words like "synced" and "offline evidence" describe system implementations rather than the user's situation. Rephrase to focus on the outcome. |

---

#### `widgets/action_plan_detail_list.dart`
> [!NOTE]
> Uses backend-centric database tree concepts ("parent audit") instead of simple business language.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `This action plan was automatically closed because the parent audit was voided.` | `This action plan was automatically closed because the audit was voided.` | **Rule 1: No Developer Jargon** | "Parent audit" exposes the relational database tree structure to the user. "The audit" is clean, clear, and sufficient. |

---

#### `pages/action_plan_detail_page.dart`
> [!NOTE]
> Navigation CTA uses passive directionals instead of specific destinations.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Go Back` | `Return to Action Plans` | **Rule 3: Call-to-Action Verbs** | "Go Back" is passive and lacks descriptive value. "Return to Action Plans" uses a leading verb and clearly states the destination. |

---

#### `widgets/action_plan_detail_actions.dart`
> [!WARNING]
> Uses harsh warning language ("This cannot be undone") that causes anxiety.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Mark this action plan as resolved? This cannot be undone.` | `Are you sure you want to resolve this action plan? This action is permanent.` | **Rule 2: Blame-Free Error States** | "This cannot be undone" sounds like a harsh system threat. Rephrase with polite confirmation language. |

---

### 📋 2. lib/features/audit/pages/ & related

#### `widgets/history_list_view.dart`
> [!NOTE]
> Uses technical process words ("syncing") and scary confirmation headers.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `This audit is syncing. Please wait a moment.` | `We are saving your audit. Please wait a moment.` | **Rule 1: No Developer Jargon** | "Syncing" is an engineering concept. "Saving your audit" is warm and clear. |
| `This will permanently void` | `Are you sure you want to void this audit? This action is permanent.` | **Rule 2: Blame-Free Error States** | "This will permanently void" is a harsh system warning. Soften the tone into a helpful confirmation dialog. |

---

#### `audit_preview_sheet.dart`
> [!NOTE]
> Employs jargon like "Legacy" and complex data hierarchy descriptors.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Legacy audit — section details unavailable.` | `Older audit — some details are not available.` | **Rule 1: No Developer Jargon** | "Legacy audit" and "section details unavailable" sound like internal debug messages. Simplify the description for the user. |

---

## 💎 Best Practices & Quick Reference

### 1. The Offline/Sync Vocabulary
Instead of saying "synced", "syncing", "offline mode", or "caching", choose clean, human terms like "saving", "updates", "sending", or "offline updates". This maintains premium, human-centric copywriting.

### 2. Dialog Confirmations
Ensure confirmation alerts never use aggressive words like "This cannot be undone." Instead, write polite questions ending with a simple advisory note (e.g., `Are you sure you want to... This action is permanent.`).
