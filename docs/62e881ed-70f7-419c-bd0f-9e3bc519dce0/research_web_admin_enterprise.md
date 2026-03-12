# Research: Web Portal for Enterprise Scale (1000+ Stores)

> **Workflow**: /research | **Date**: 2026-03-12
> **Role**: Senior Architect

---

## The Question

At 1000+ stores, which roles need web (desktop) access beyond Admin?

## Per-Role Analysis

### Who needs what at scale?

| Role | Mobile App | Web Portal | Why |
|------|:---:|:---:|-----|
| **Admin** | ✅ Light use | ✅ **Must have** | Managing 500+ users, 1000 stores, bulk operations, data exports, system logs — impossible on a phone |
| **Area Manager** | ✅ Quick checks | ✅ **Must have** | Overseeing 50-100 stores per area. Needs comparison dashboards, regional trends, AP oversight across all stores. Phone screen can't show 50-store ranking table |
| **Store Manager** | ✅ Primary | 🟡 Nice-to-have | Manages 1 store. Phone works fine for daily AP responses. Web useful only for printing reports |
| **Auditor** | ✅ **Primary** | ❌ Not needed | Auditors work in the field with their phone. They don't need a desktop |

### What each role gets on web

```
ADMIN WEB PORTAL
├── User Management (table, bulk assign, import CSV)
├── Store Management (table, map view, bulk create)
├── Template Builder (full-screen editor, much better than phone)
├── Audit Approvals (queue with filters, bulk approve)
├── System Logs (searchable table, export)
├── Analytics (full-width charts, drilldowns, data export)
└── Reports (PDF/Excel generation)

AREA MANAGER WEB PORTAL
├── Regional Dashboard (KPIs across 50-100 stores)
├── Store Comparison (ranking table, heatmap)
├── AP Oversight (all open APs in region, sorted by urgency)
├── Trend Analysis (6-month trends per store, per area)
└── Reports (regional compliance reports)

STORE MANAGER WEB (optional)
├── Store Dashboard (same as mobile, wider layout)
├── AP Management (table view)
└── Print Report (PDF export of store audit history)
```

---

## Technology Decision

### Option 1: Flutter Web (Recommended ✅)

Use the **same Dart codebase** with a responsive layout that adapts between mobile and web.

| Pros | Cons |
|------|------|
| Same language, same models, same API services | Flutter Web has larger initial load (~2MB WASM) |
| 1 team maintains everything | Fewer web-specific packages than React ecosystem |
| Shared scoring engine, auth, sync logic | SEO not relevant (internal tool, so doesn't matter) |
| Hot reload for fast iteration | |

**How it works architecturally**:

```
lib/
├── _shared/         ← 100% shared (models, API, scoring, auth)
├── features/        ← Managers + services shared, UI differs
│   ├── admin/
│   │   ├── manager/        ← shared
│   │   ├── pages/          ← mobile layout
│   │   └── web_pages/      ← desktop layout (wider tables, sidebars)
```

The `manager/` layer (business logic) stays identical. Only the `pages/` layer gets a web-optimized variant with:
- `LayoutBuilder` or `MediaQuery` for responsive breakpoints
- `DataTable` instead of `ListView` for 1000-row tables
- Sidebar navigation instead of bottom nav
- Full-width charts instead of phone-width cards

### Option 2: React/Next.js (Alternative)

Build a separate web app in React that calls the same ASP.NET API.

| Pros | Cons |
|------|------|
| Mature web ecosystem, tons of admin templates | Separate codebase = double maintenance |
| Smaller bundle size (~200KB) | Must rewrite all models, auth, API calls in TypeScript |
| Better for content-heavy pages | Scoring engine duplicated in 3rd language (JS) |
| | 2 teams needed (Dart + TypeScript) |

### Verdict

**Flutter Web wins** for your situation because:
1. You already know Dart — no new language to learn
2. Scoring engine stays in ONE place (Dart) — no 3rd copy to maintain
3. API service layer, models, auth — all shared. Only UI layout changes
4. Internal tool = SEO and bundle size don't matter

---

## Phased Rollout

| Phase | What | Effort |
|-------|------|--------|
| **Now** | Mobile app for all roles (what you have) | ✅ Done |
| **Phase 2** | Add responsive breakpoints — same app works on tablet/desktop browser | 1-2 weeks |
| **Phase 3** | Admin-specific web layout (wider tables, sidebar nav, data export) | 2-3 weeks |
| **Phase 4** | Area Manager web dashboard (regional KPIs, store comparisons) | 1-2 weeks |
| **Phase 5** | PDF/Excel report generation | 1 week |

> [!TIP]
> **Phase 2 is the quick win.** Just adding `LayoutBuilder` responsive breakpoints to your existing pages lets the same Flutter app work reasonably well in a desktop browser. No separate codebase needed.
