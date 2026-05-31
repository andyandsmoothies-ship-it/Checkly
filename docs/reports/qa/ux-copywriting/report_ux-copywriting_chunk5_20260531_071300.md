# UX Copywriting & Semantic Tone Report | Chunk 5: Program Execution & Management

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 5: Program Execution & Management** across `lib/features/programs/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **6 Violations** | Lazy developer formatting ("item(s)"), Passive navigation CTAs ("Next", "Go back"), Accusatory guidance ("Select at least 1") | 🟡 Medium |

---

## Detailed Violations & Recommendations

### 📋 1. lib/features/programs/

#### `pages/program_dashboard_page.dart`
> [!NOTE]
> Uses lazy developer-style formatting ("item(s)") rather than natural, polished copy.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `${a.evidence.length} evidence item(s)` | `a.evidence.length == 1 ? '1 evidence file' : '${a.evidence.length} evidence files'` | **Rule 1: No Developer Jargon** | Parentheses formatting like "item(s)" looks like lazy placeholder code. Use clean conditional logic to present elegant singular/plural forms. |

---

#### `widgets/wizard/step_stores.dart`
> [!WARNING]
> Uses direct, demanding validation language instead of polite and helpful guidance.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Select at least 1 store.` | `Please choose one or more stores to continue.` | **Rule 2: Blame-Free Error States** | "Select at least 1 store" reads like a cold system warning. Make it warmer and instruction-focused. |

---

#### `pages/program_execution_page.dart`
> [!NOTE]
> Uses passive navigation cues ("Go back") instead of actionable target descriptors.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Go back` | `Return to Campaigns` | **Rule 3: Call-to-Action Verbs** | "Go back" is a vague direction. "Return to Campaigns" states the destination clearly with an active verb. |

---

#### `widgets/wizard/step_info.dart` & `widgets/wizard/step_stores.dart` & `widgets/wizard/step_template.dart`
> [!NOTE]
> "Next" is a weak and passive transition button.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Next` | `Continue` | **Rule 3: Call-to-Action Verbs** | "Next" is static. "Continue" is a much stronger active CTA for wizard step navigation. |

---

#### `pages/program_store_selector_page.dart`
> [!NOTE]
> Simple generic confirmation verbs ("Done", "Retry") can be improved.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Done` | `Confirm Selection` | **Rule 3: Call-to-Action Verbs** | "Done" is passive. "Confirm Selection" clearly commits the store selection. |
| `Retry` | `Try Again` | **Rule 3: Call-to-Action Verbs** | "Try Again" is a warmer, more polished action verb than "Retry". |

---

## 💎 Best Practices & Quick Reference

### 1. Pluralization Polish
Never write `item(s)`, `store(s)`, `template(s)` in user-facing components. Always implement simple inline ternary checks (`count == 1 ? 'item' : 'items'`) to ensure high-premium typography.

### 2. Multi-Step Button Design
When building stepper wizards, always use `Continue` instead of a dry `Next` to keep the user moving forward.
