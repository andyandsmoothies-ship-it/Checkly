# Flutter Starter Knowledge Pack — What to Bring

> **Author**: Scout (Lead Architect)
> **Date**: 2026-03-10
> **Purpose**: Complete checklist of everything to extract from the current React/Supabase project when starting the new Flutter project.

---

## How to Use This Document

Copy the listed files into a `docs/` folder in your new Flutter project. These become the **specification** that Forge (the builder) follows. The Flutter app doesn't share code with the React app — it shares **knowledge**.

---

## Tier 1: Critical — Must Have Before Writing Any Code

These are your **specification documents**. Without them, the Flutter builder will have to reverse-engineer the app.

### 📐 1.1 Business Logic Specs

| What | Source File | Why You Need It |
|------|------------|-----------------|
| **Scoring Algorithm** | [SCORING_LOGIC.md](file:///c:/Users/HP/Documents/GitHub/checkly-smart/docs/SCORING_LOGIC.md) | The exact penalty formulas, CCP/Risk rules, progressive repeat penalty, server verification pipeline. This is ported line-by-line to Dart |
| **Workflow State Machines** | [CORE_WORKFLOWS.md](file:///c:/Users/HP/Documents/GitHub/checkly-smart/docs/CORE_WORKFLOWS.md) | Audit lifecycle (Scheduled→Draft→Completed), Action Plan lifecycle (Open→Pending Verify→Closed), Review disposition, notification triggers, cache strategy, app lifecycle tiers |
| **Scoring Engine Source** | [scoringEngine.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/lib/scoringEngine.ts) | The actual TypeScript implementation. Port to Dart function-by-function |
| **Validation Schemas** | [validationSchemas.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/lib/validationSchemas.ts) | All Zod schemas for domain inputs. Translate to Dart validators |

### 🎨 1.2 Design System

| What | Source File | Why You Need It |
|------|------------|-----------------|
| **Design Tokens** | [DESIGN_SYSTEM.md](file:///c:/Users/HP/Documents/GitHub/checkly-smart/docs/DESIGN_SYSTEM.md) | Color palette (primary/destructive/success/warning/info with shade scales), typography scale, z-index, elevation, border radius, component patterns (status badges, score traffic light), dark mode approach |
| **CSS Variables** | [tokens.css](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/tokens.css) | Raw HSL values for every token. Translate to Flutter `ThemeData` |
| **Font** | Plus Jakarta Sans (Google Fonts) | Same font in Flutter via `google_fonts` package |

### 🗄️ 1.3 Database Schema

| What | Source File | Why You Need It |
|------|------------|-----------------|
| **Full Supabase Types** | [types.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/integrations/supabase/types.ts) | Every table, column, type, and relationship. This is your schema contract |
| **Baseline Migration** | [00000000000000_baseline.sql](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/migrations/00000000000000_baseline.sql) | The complete DDL — tables, indexes, triggers, RLS policies, functions. The Flutter app's Drift schema must mirror this |
| **All Migrations** | [supabase/migrations/](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/migrations/) (52 files) | The full evolution of the schema. Extract the **final state**, not the history |
| **GEMINI.md §4** | The Database Schema table in GEMINI.md | Concise reference of all tables, relationships, RLS status, and FK conventions |

### 🔑 1.4 Auth & Security

| What | Source File | Why You Need It |
|------|------------|-----------------|
| **RBAC Model** | GEMINI.md §4 (`user_roles` table) | 4 roles: `admin`, `auditor`, `store_manager`, `area_manager`. Role→route mapping |
| **RLS Policy Convention** | GEMINI.md §4 (RLS Convention note) | All policies use `(select auth.uid())` subselect. This convention is critical for understanding what data each role can see |
| **Assignment Rules** | SCORING_LOGIC.md §6 | 1 SM per store, 1 AM per area, SM transfer protocol. These constraints must be enforced in the Flutter app |

---

## Tier 2: Reference — Needed During Active Development

### 🔌 2.1 API Contracts (Supabase RPCs & Edge Functions)

| What | Source | Why You Need It |
|------|--------|-----------------|
| **Edge Function: admin-api** | [admin-api/index.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/functions/admin-api/index.ts) | User creation, banning, profile updates. Understand its request/response format |
| **Edge Function: ai-assistant** | [ai-assistant/](file:///c:/Users/HP/Documents/GitHub/checkly-smart/supabase/functions/ai-assistant/) (10 files) | SSE streaming chat with Gemini. Full tool architecture. Phase 2 feature |
| **RPC: finalize_audit** | In migrations (`20260220_score_verification_enforce.sql`) | The server-side audit finalization. Must call it the same way from Flutter |
| **RPC: get_stores_with_managers** | In migrations | Used by store picker. Returns stores with their SM names |
| **RPC: transfer_store_manager** | In migrations | Atomic SM swap + AP transfer |
| **DB Triggers** | In baseline + later migrations | `handle_submission_completion`, `handle_action_plan_status_change`, `send_deadline_reminders`, `send_schedule_reminders` — these fire server-side, your Flutter app triggers them by writing data |

> [!TIP]
> You don't need to copy all 52 migration files. Extract the **final schema state** by running `pg_dump --schema-only` against your Supabase database, or use the baseline + latest types.ts.

### 📱 2.2 UI Flows & Screen Map

| What | Source | Why You Need It |
|------|--------|-----------------|
| **Navigation Standards** | KI: [UI and Navigation Standards](file:///C:/Users/HP/.gemini/antigravity/knowledge/ui_and_navigation_standards/artifacts/viewport_layout_standards.md) | Fixed header/footer pattern, FAB visibility rules, bottom navigation ordering |
| **Mobile Audit UX** | KI: [mobile_audit_ux_patterns.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/ui_and_navigation_standards/artifacts/mobile_audit_ux_patterns.md) | Scroll management, sticky HUD, quick-jump nav. These UX patterns should be replicated |
| **Page Map** | `src/pages/` directory listing | Every screen in the app. Map 1:1 to Flutter screens |
| **Component Library** | `src/components/ui/` | shadcn/ui components used. Find Flutter equivalents |

### 🔄 2.3 Offline & Sync Patterns

| What | Source | Why You Need It |
|------|--------|-----------------|
| **Offline Architecture Overview** | KI: [overview.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/offline_architecture_and_sync/artifacts/overview.md) | 8-phase architecture, boundaries, workflow |
| **Sync Engine Source** | [syncEngine.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/services/offline/syncEngine.ts) | Heartbeat logic, FIFO processing, auth-aware pause, DLQ routing |
| **Outbox Source** | [outbox.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/services/offline/outbox.ts) | Mutation stats, next mutation retrieval, indexed queries |
| **Dexie Schema** | [db.ts](file:///c:/Users/HP/Documents/GitHub/checkly-smart/src/services/offline/db.ts) | IndexedDB table definitions → translate to Drift tables |
| **Hostile Test Suite** | KI: [hostile_test_suite_offline.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/offline_architecture_and_sync/artifacts/verification/hostile_test_suite_offline.md) | Test scenarios to validate offline behavior. Use as acceptance criteria |

---

## Tier 3: Shared Backend — Zero Changes, Just Understand

These stay in the current project. The Flutter app **calls them but doesn't modify them**.

| Component | Location | Action for Flutter |
|-----------|----------|-------------------|
| Supabase PostgreSQL | Cloud | Connect via `supabase_flutter` SDK. Same URL + anon key |
| RLS policies | DB | Automatically enforced. No client code needed |
| Edge Functions | Supabase | Call via `supabase.functions.invoke()`. Same API |
| Storage buckets | Supabase | Upload/download via `supabase.storage`. Same API |
| DB Triggers | DB | Fire automatically on data changes |
| pg_cron jobs | DB | Run on schedule. No client dependency |
| Vault secrets | DB | Used by Edge Functions. No client access |

---

## Tier 4: Optional — Nice to Have Later

| What | Source | When |
|------|--------|------|
| **AI Assistant docs** | [AI_ASSISTANT.md](file:///c:/Users/HP/Documents/GitHub/checkly-smart/docs/AI_ASSISTANT.md) | Phase 2. Complex SSE + tool architecture |
| **Knowledge base docs** | `docs/*.md` synced to `ai_knowledge_base` table | Only if porting AI assistant |
| **Test Drivers** | `src/test/drivers/` | Reference for how tests are structured. Adapt for Flutter testing |
| **Performance benchmarks** | Various KI artifacts | For optimization phase |
| **Theme variations** | KI: UI Theming Architecture | Sakura Zen, Festive Red — seasonal themes |

---

## Tier 5: NOT Needed — Stays with React

| What | Reason |
|------|--------|
| React components (`src/components/`) | Different framework. Build new Flutter widgets |
| Tailwind config | Flutter uses `ThemeData`. Use token values from DESIGN_SYSTEM.md |
| Vite config | Flutter has its own build system |
| Service Worker / PWA config | Flutter is native. No SW needed |
| TanStack Query setup | Replaced by Riverpod |
| React Hook Form | Replaced by Flutter form widgets |
| shadcn/ui components | Find Flutter equivalents or build custom |
| Lovable compatibility rules | Not deploying on Lovable |
| Node.js / npm toolchain | Flutter uses Dart / pub |

---

## Recommended Folder Structure for Knowledge Transfer

```
flutter-udat/
├── docs/                           # ← Copy these from React project
│   ├── SCORING_LOGIC.md            # Tier 1: Scoring algorithm spec
│   ├── CORE_WORKFLOWS.md           # Tier 1: State machines & workflows
│   ├── DESIGN_SYSTEM.md            # Tier 1: Color tokens & typography
│   ├── SCHEMA.sql                  # Tier 1: Final DB schema (pg_dump)
│   ├── API_CONTRACTS.md            # Tier 2: RPCs & Edge Function signatures (extract from migrations)
│   ├── OFFLINE_ARCHITECTURE.md     # Tier 2: Sync patterns (copy from KI)
│   └── HOSTILE_TESTS.md            # Tier 2: Offline acceptance criteria
├── reference/                      # ← Source code for porting
│   ├── scoringEngine.ts            # Tier 1: Port to Dart
│   ├── validationSchemas.ts        # Tier 1: Port to Dart validators
│   ├── syncEngine.ts               # Tier 2: Reference for Dart sync engine
│   ├── outbox.ts                   # Tier 2: Reference for Dart outbox
│   └── db.ts                       # Tier 2: Dexie schema → Drift tables
├── lib/                            # ← New Flutter code
│   └── ...
└── .agent/                         # ← Agent rules for the new project
    ├── GEMINI.md                   # New project-specific rules
    └── skills/                     # Relevant skills (ecosystem-advisor, etc.)
```

---

## Things You Might Still Be Missing

| # | Item | Status | Recommendation |
|---|------|--------|----------------|
| 1 | **Screenshots / screen recordings of the current app** | ❌ Not captured | Take screenshots of every screen. This is the fastest way for a Flutter developer to understand the target UX |
| 2 | **Supabase project URL + keys** | Need to copy | The `SUPABASE_URL` and `SUPABASE_ANON_KEY` for your project. The Flutter app connects to the **same** Supabase project |
| 3 | **Test user accounts** | Reuse | Same auth users work in Flutter (same Supabase Auth) |
| 4 | **`.env` config pattern** | Need to create | Flutter uses `flutter_dotenv` or compile-time `--dart-define` for environment variables |
| 5 | **Apple Developer account** | Need to verify | Required for TestFlight. Check if you already have one ($99/yr) |
| 6 | **Firebase project** | Need to create | For Firebase App Distribution (Android) and FCM push notifications |
| 7 | **App icons and splash screen** | Need to create | Design app icon. Use `flutter_launcher_icons` and `flutter_native_splash` packages |
| 8 | **Entity relationship diagram** | Partially captured | GEMINI.md has the table list. Consider exporting a visual ERD from Supabase |

---

> **Scout's Summary**: You need **8 files** from the current project as your core specification (Tier 1). Everything else is reference material. The backend is 100% shared — the Flutter app simply connects to the same Supabase project with the same credentials. The biggest effort is in the UI and offline engine, which are written from scratch in Dart but follow the same patterns documented in your existing specs.
