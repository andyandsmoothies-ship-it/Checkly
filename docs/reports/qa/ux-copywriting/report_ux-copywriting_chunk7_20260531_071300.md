# UX Copywriting & Semantic Tone Report | Chunk 7: Analytics & Store Insights

`Conversation ID`: f625c2e4-0fdd-4c33-9271-185cf5df427c

```
[Extracted UI Strings]
          │
          ├──> Rule 1: No Developer Jargon ──> Checked
          ├──> Rule 2: Blame-Free Error ─────> Checked
          └──> Rule 3: Call-to-Action Verbs ─> Checked
```

This report details a complete static copywriting audit of **Chunk 7: Analytics & Store Insights** across `lib/features/analytics/` and `lib/features/stores/` against the 3 rules of the Checkly UX Copywriting System.

---

## Summary of Findings

| Violations Found | Primary Issue Types | Critical Rating |
| :--- | :--- | :--- |
| **5 Violations** | Developer Jargon (Database timeouts, "Recomputation"), Weak/Passive CTAs | 🟡 Medium |

---

## Detailed Violations & Recommendations

### 📊 1. lib/features/analytics/

#### `widgets/bod_dashboard_body.dart`
> [!WARNING]
> Contains technical database jargon ("database timeouts") that exposes system architecture to the business user.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Some board metrics could not be fully calculated due to temporary database timeouts. Leaderboard scores may be incomplete.` | `We couldn't load all boardroom metrics because the server took too long to respond. The leaderboard might be slightly out of date, but you can try refreshing.` | **Rule 1: No Developer Jargon** | Business users do not know what database timeouts are. Rephrase to focus on natural consequences (taking too long to respond) and offer a helpful path forward. |

---

#### `pages/bod_analytics_page.dart`
> [!NOTE]
> Uses developer jargon ("recomputation") and simple non-descriptive verbs for critical board operations.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Trigger Recomputation` | `Refresh Dashboard` | **Rule 1: No Developer Jargon** & **Rule 3: CTA Verbs** | "Recomputation" is developer jargon. "Refresh Dashboard" is simple, clear, and uses an active leading verb. |
| `Try Again` / `Retry` | `Reload Dashboard` | **Rule 3: CTA Verbs** | "Reload Dashboard" or "Try Again" is cleaner, more concrete, and clearly tells the user what will reload. |

---

#### `widgets/bod_store_sync_modal.dart`
> [!NOTE]
> "Perform Live Sync" is overly technical. Let's make it action-driven.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Perform Live Sync` | `Sync Boardroom Data` | **Rule 1: No Developer Jargon** & **Rule 3: CTA Verbs** | "Perform Live Sync" uses formal developer vocabulary. "Sync Boardroom Data" is direct and clearly states the action. |

---

### 🏪 2. lib/features/stores/

#### `pages/store_selector_page.dart`
> [!NOTE]
> Uses basic, generic CTAs that can be improved.

| Current String | Recommended Rewrite | Violated Rule | Rationale |
| :--- | :--- | :--- | :--- |
| `Retry` | `Search Again` | **Rule 3: CTA Verbs** | If no stores were found, "Search Again" is a much more descriptive action-oriented verb than a generic "Retry". |

---

## 💎 Best Practices & Quick Reference

### 1. Jargon Filter
Always check strings for terms like `database`, `timeout`, `sync`, `recomputation`, `exception`, `error`, `null`, `500`. Swap them for real-world scenarios (e.g., `the server took too long to respond`).

### 2. User-First Positioning
Never say "You entered...". Say "The information entered doesn't match...". Avoid passive blame or harsh status indicators.

### 3. Active Action Verb leading CTAs
Instead of: `Retry`, `Cancel`, `Submit`.
Prefer: `Try Again`, `Keep Writing`, `Submit Audit`.
