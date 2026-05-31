# UX Copywriting & Semantic Tone Report | Chunks 1 & 2: Auth, Dashboard & Audit Execution

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 1: Authentication & Connection** and **Chunk 2: Dashboard, Metrics, Quick Actions, and Audit Execution** across `lib/features/auth/`, `lib/features/dashboard/`, and `lib/features/audit/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **7 Violations** | Technical jargon ("syncing", "GPS"), Dry/harsh alerts ("This will permanently void"), Vague transition CTAs ("Got it", "Forgot Password?") | 🟡 Medium |

---

## Detailed Violations & Recommendations

### 📋 1. Chunk 2: Dashboard & Audit Execution (`lib/features/dashboard/`, `lib/features/audit/`)

#### `pages/widgets/submission_row.dart` & `pages/widgets/history_list_view.dart`
> [!NOTE]
> Employs engineering terms like "syncing" and cold system disclaimers.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `This audit is syncing. Please wait a moment.` | `We are saving your audit. Please wait a moment.` | **Rule 1: No Developer Jargon** | "Syncing" is an implementation detail. Use "saving" to keep it human-centric. |
| `This will permanently void` | `Are you sure you want to void this audit? This action is permanent.` | **Rule 2: Blame-Free Error States** | "This will permanently void" is cut-off and reads like a scary system warning. Rephrase to a polite question. |

---

#### `widgets/audit_form_dialogs.dart`
> [!NOTE]
> Uses developer syntax and technical acronyms (GPS, m) in high-visibility alerts.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Unverified location — ${result.distance}m from store` | `Location verification failed — you are ${result.distance} meters away from the store.` | **Rule 1: No Developer Jargon** | Shortened notations like "m" and cold "unverified" headers feel like debug code. Rephrase to be warmer and descriptive. |
| `Location unavailable — submitting without GPS` | `Location services are unavailable. Your audit will be saved without coordinate pinning.` | **Rule 1: No Developer Jargon** | "GPS" and "submitting without GPS" focuses on the device hardware. Phrase in terms of location pinning outcomes. |
| `⚠ ${total - answered} criteria unanswered` | `Please note: ${total - answered} questions are still unanswered.` | **Rule 2: Blame-Free Error States** | Warning icons with harsh "criteria unanswered" text sound accusatory. Soften the warning style. |

---

### 📋 2. Chunk 1: Authentication & Connection (`lib/features/auth/`)

#### `pages/login_page.dart`
> [!NOTE]
> Navigation actions and confirmations are passive/directional instead of verb-driven.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Forgot Password?` | `Reset Password` or `Request Password Reset` | **Rule 3: Call-to-Action Verbs** | "Forgot Password?" is a passive question. Use a leading verb. |
| `Got it` | `Dismiss` or `Continue` | **Rule 3: Call-to-Action Verbs** | "Got it" is informal/passive. Use clear, verb-driven actions for sheet dismissals. |

---

## 💎 Best Practices & Quick Reference

### 1. Hardware & System Transparency
Avoid using device/protocol terms like `GPS`, `cellular`, `database sync`, or `payload`. Describe the outcomes in business-friendly terms (e.g., `Location Pinning`, `Saving Updates`, `Offline Access`).

### 2. Confirmations & Warning Banners
Always frame form incomplete issues politely (e.g. `Please note: X questions are still unanswered` instead of `⚠ X Criteria Unanswered!`). This keeps the UX blame-free and encouraging.
