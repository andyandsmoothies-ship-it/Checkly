# UX Copywriting & Semantic Tone Report | Chunk 3: Scoring Simulator & Builder

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 3: Scoring Simulator & Builder** across `lib/features/templates/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **6 Violations** | Extreme developer jargon ("Linter", "Bypass"), Aggressive/robotic alerts ("Change with care", "Blocking Errors") | 🔴 High |

---

## Detailed Violations & Recommendations

### 📋 1. lib/features/templates/

#### `widgets/template_linter_panel.dart`
> [!IMPORTANT]
> The word "Linter" is severe developer-only jargon. No non-technical user knows what a code linter does.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Template Linter` | `Template Compliance Check` | **Rule 1: No Developer Jargon** | "Linter" is a programming utility term. Use compliance check to describe verifying the structure. |
| `Bypass` | `Skip Checks` | **Rule 3: Call-to-Action Verbs** | "Bypass" is passive and slightly mechanical. "Skip Checks" is highly actionable. |
| `Blocking Errors` | `Compliance Issues` | **Rule 2: Blame-Free Error States** | "Blocking Errors" sounds like compiler/syntactic errors. Soften to compliance issues. |
| `Advisory Warnings` | `Improvement Suggestions` | **Rule 2: Blame-Free Error States** | "Advisory Warnings" sounds bureaucratic. Rephrase to helpful suggestions. |

---

#### `widgets/advanced_settings_card.dart`
> [!WARNING]
> Uses developer-style scary alerts ("Change with care") that discourage user exploration.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `These settings affect how audits are scored. Change with care.` | `These settings adjust how audit scores are calculated. Please verify details before saving changes.` | **Rule 1: No Developer Jargon** | "Change with care" is a cold engineering disclaimer. Use polite, clarifying instructions. |

---

#### `pages/widgets/live_score_simulator.dart`
> [!NOTE]
> Uses robotic systems language ("global risk failure") rather than clear business outcomes.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Simulate global risk failure` | `Simulate a critical safety alert` | **Rule 1: No Developer Jargon** | "Global risk failure" is backend jargon for score manipulation. Business users understand it as a safety alert/critical failure. |

---

## 💎 Best Practices & Quick Reference

### 1. Eliminating Developer Jargon
Always ask yourself: "Would a Store Coordinator or a Quality Assurance Manager understand this term?"
- ❌ `Linter`, `Parser`, `Array`, `Bypass`, `Handler`, `State Drift`
- ✅ `Compliance Checker`, `Builder`, `List`, `Skip Checks`, `Manager`, `Out of Sync`

### 2. Warning Card Copy
Avoid using warning phrases like "Change with care", "At your own risk", or "This cannot be undone". Focus instead on explaining the outcome: "This will permanently update..." or "Please confirm changes before saving...".
