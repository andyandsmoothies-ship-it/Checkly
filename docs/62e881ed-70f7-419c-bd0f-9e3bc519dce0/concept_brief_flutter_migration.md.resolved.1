# UDAT Mobile App — Greenfield Flutter Build

> **Author**: Scout (Lead Architect) — applying `ecosystem-advisor` skill framework
> **Date**: 2026-03-10
> **Status**: Concept Brief — Awaiting Decision
> **Framing**: This is a **new app** that replicates the same user experience and workflows as the current React PWA. It is NOT a code conversion.

## Context & References

| Source | Path |
|--------|------|
| Ecosystem Advisor Skill | [SKILL.md](file:///c:/Users/HP/Documents/GitHub/checkly-smart/.agent/skills/ecosystem-advisor/SKILL.md) |
| Product Vision | [project_overview_and_vision.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/product_strategy_and_roadmap/artifacts/project_overview_and_vision.md) |
| Offline Architecture | [overview.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/offline_architecture_and_sync/artifacts/overview.md) |
| FSD Entity Map | [entity_mapping.md](file:///C:/Users/HP/.gemini/antigravity/knowledge/fsd_architecture_and_entities/artifacts/entity_mapping.md) |

---

## 1. Executive Summary (The Elevator Pitch)

> Build a new Flutter mobile app that gives your field auditors the **exact same audit workflow** they use today — login, pick a store, run an audit, capture photos, score, submit — but running as a **real native app** on their iPhones and Androids. Distribute it privately via **TestFlight** (iOS) and **Firebase App Distribution** (Android). The entire **Supabase backend stays untouched** — same database, same RLS policies, same Edge Functions, same triggers. You're only building a new front door.

---

## 2. The Recommended Ecosystem

| Layer | Technology | Why |
|-------|-----------|-----|
| **Client Framework** | **Flutter 3.x** (Dart) | Single codebase → iOS + Android. AOT-compiled, 60fps native performance |
| **State Management** | **Riverpod** | Type-safe, testable. Maps naturally to your TanStack Query mental model (`ref.watch` ≈ `useQuery`) |
| **Offline Database** | **Drift** (SQLite ORM) | Type-safe, reactive, unlimited storage. Replaces Dexie.js/IndexedDB |
| **Backend / Auth / DB** | **Supabase** (existing) ⭐ | Zero changes. `supabase_flutter` SDK has near-identical APIs to the JS client |
| **Navigation** | **GoRouter** | Declarative, supports deep links, role-based guards |
| **Camera** | `image_picker` | Native camera access — far more reliable than Web File API |
| **GPS** | `geolocator` | Native GPS — consistent cross-platform |
| **Charts** | `fl_chart` | Beautiful, customizable charts for dashboard |
| **Push Notifications** | `firebase_messaging` | Native APNs + FCM — finally reliable on iOS |
| **OTA Updates** | **Shorebird** | Push Dart code updates without re-deploying via TestFlight (like your current SW auto-update) |

---

## 3. The Business Translation (Why Flutter Wins)

| Win | Trade-off |
|-----|-----------|
| **Reliable offline storage**: SQLite gives you virtually unlimited, OS-level storage. No more IndexedDB browser quota limits or safari eviction | You need to learn Drift ORM (1 week ramp-up) |
| **Native camera & GPS**: Field auditors get consistent, reliable hardware access. No more iOS Safari camera permission bugs | App requires installation (TestFlight/APK) instead of just opening a URL |
| **True background sync**: `workmanager` plugin enables real background processing on both iOS and Android. Unlike the PWA, iOS won't kill your sync mid-flight | Background sync on iOS still has 15-minute minimum intervals. Not instant |
| **One codebase, two platforms**: Same Dart code runs on iPhone and Android. No need for two native teams | Flutter updates (major versions) may require migration work ~once/year |
| **Backend reuse is 100%**: Supabase stays exactly as-is. RLS, triggers, Edge Functions, storage buckets — all unchanged | Client Dart code must be written from scratch. No TypeScript reuse (but logic patterns are identical) |

---

## 4. What "Exact Same App" Means — Functional Parity Checklist

This is the **behavioral specification** — what every screen and flow must do, identical to the current PWA:

### 4.1 Auth & Roles (Behavior to Replicate)

| Behavior | Current PWA | Flutter App Must Do |
|----------|-------------|---------------------|
| Email/password login | Supabase Auth | Same provider, `supabase_flutter` |
| Session persistence across app restarts | localStorage + Dexie | Supabase Flutter's built-in `SharedPreferences` persistence |
| Role-based route guards (Admin, Auditor, SM, AM) | React router guards | GoRouter redirect guards reading `user_roles` |
| Profile fetch on login | TanStack Query | Riverpod `FutureProvider` |

### 4.2 Audit Flow (Core Business Logic)

| Behavior | Current PWA | Flutter App Must Do |
|----------|-------------|---------------------|
| Browse templates & stores | TanStack Query + cache | Riverpod providers + Drift local cache |
| Start audit → multi-section form | React Hook Form + Zod | `flutter_form_builder` or custom form widgets |
| Answer types: Pass/Fail, N/A, text notes | Custom radio groups | Flutter `ToggleButtons` / custom widgets |
| Photo capture per criteria | Web File API | `image_picker` (camera + gallery) |
| Real-time score calculation | `scoringEngine.ts` (pure functions) | Port to pure Dart functions (same algorithm) |
| CCP/Risk auto-fail triggers | Same engine | Same logic in Dart |
| GPS verification on submit | `navigator.geolocation` | `geolocator` plugin |
| Submit audit | Supabase `INSERT` + Edge Function | Same Supabase calls via Dart SDK |

### 4.3 Offline Capability (Must Match 8 Phases)

| PWA Phase | Flutter Equivalent | Behavior |
|-----------|-------------------|----------|
| Read-path caching | Drift tables caching templates + stores | User sees cached data when offline |
| Auth persistence | `supabase_flutter` built-in session storage | App opens offline without re-login prompt |
| Photo blob storage | `dart:io` file system + `path_provider` | Photos saved locally, synced later |
| Transactional outbox | Drift `outbox` table | Submissions queued locally with FIFO ordering |
| Sync engine | Dart service + `connectivity_plus` | Auto-sync on reconnect + periodic retry |
| Draft auto-save | Drift `drafts` table | Crash recovery — resume in-progress audits |
| Airplane reboot test | Same validation gate | App must work after cold reboot with no internet |

### 4.4 Action Plans, Dashboard, Notifications

| Feature | Behavior to Replicate |
|---------|----------------------|
| Action Plans | CRUD lifecycle: Open → Evidence Submitted → Closed/Rejected. Status change notifications |
| Dashboard | MTD metrics, charts (submission count, score trends, store comparisons) |
| Notifications | Real-time via Supabase channels + push via FCM/APNs. Bell icon with unread count |
| Dark Mode | Theme switching with persistence |

### 4.5 Features to EXCLUDE from Mobile (Keep Web-Only)

| Feature | Reason |
|---------|--------|
| **Template Builder** | Desktop-class drag-and-drop UX. Admin-only. Keep on web |
| **Admin User Management** | Rare admin task. Supabase Dashboard or web admin |
| **System Logs Viewer** | Admin-only diagnostic tool. Web is better |
| **AI Chat Assistant** | Consider for Phase 2. SSE streaming + Generative UI is complex in Flutter |

---

## 5. Manageable Risks & Mitigation Strategies

> [!IMPORTANT]
> Every risk below has a concrete mitigation. No dead ends.

| Risk | Mitigation |
|------|------------|
| **Full greenfield build — significant effort** | The backend is 100% reusable (Supabase). The scoring engine is pure math → direct Dart port. The effort is concentrated in UI and offline engine only |
| **Two apps to maintain (PWA + Flutter)** | Strategy A: Keep PWA for admin features, Flutter for field use (split by role). Strategy B: If Flutter Web proves viable for admin screens, sunset the React PWA entirely → one Dart codebase for everything |
| **Team needs to learn Dart** | Dart syntax is 90% identical to TypeScript. A TS developer is productive in Dart within 1-2 weeks. Riverpod patterns map to TanStack Query patterns |
| **iOS distribution requires Apple Developer account** | $99/year. TestFlight supports up to 10,000 internal testers with automatic updates. No App Store review needed for TestFlight builds |
| **Offline engine is complex to rebuild** | Use **Drift** (typed SQLite ORM) which is more reliable than IndexedDB. Follow the exact same 8-phase architecture you already battle-tested. Same patterns, different language |
| **Losing PWA's instant-URL access** | Install once via TestFlight/Firebase. After that, auto-updates are seamless. **Shorebird** adds code-push for instant Dart updates without re-deploying |

---

## 6. Internal Distribution Strategy

### iOS — TestFlight ⭐ (Recommended)

| Aspect | Detail |
|--------|--------|
| **Cost** | $99/year Apple Developer Program |
| **Tester Limit** | 10,000 internal testers |
| **Auto-Update** | ✅ Yes — testers get notified of new builds |
| **Review Required** | ❌ No App Store review for internal/TestFlight builds |
| **Build Upload** | Xcode → App Store Connect, or CI (GitHub Actions + Fastlane) |
| **Expiry** | Builds expire after 90 days. Just upload a new one |

### Android — Firebase App Distribution ⭐ (Recommended)

| Aspect | Detail |
|--------|--------|
| **Cost** | Free |
| **Tester Limit** | Unlimited |
| **Auto-Update** | ✅ Testers get email/in-app notification of new builds |
| **Build Upload** | CLI (`firebase appdistribution:distribute`) or CI |
| **Alternative** | Direct APK sideload (no auto-update, but zero setup) |

### OTA Code Push — Shorebird

| Aspect | Detail |
|--------|--------|
| **What** | Push Dart code updates to deployed apps without going through TestFlight/Firebase again |
| **Experience** | Like your current PWA Service Worker auto-update — users get new code instantly |
| **Cost** | Free tier available for small teams |
| **Limitation** | Cannot change native plugins or assets. Dart code only |

---

## 7. Alternatives Considered (And Why They Didn't Win)

### ❌ React Native

| Factor | Assessment |
|--------|------------|
| **Pro** | Team already knows React + TypeScript. Some component logic could be shared |
| **Con** | Offline-first is weaker. No equivalent to Drift. Bridge architecture has performance overhead for photo-heavy workflows. Expo's offline story is less mature than Flutter's |
| **Verdict** | Failed the **offline stress test**. UDAT's offline-first requirement is the hardest constraint, and Flutter's native Dart + SQLite pipeline is stronger |

### ❌ Keep PWA + Improve

| Factor | Assessment |
|--------|------------|
| **Pro** | Zero development cost. Already works |
| **Con** | iOS Safari kills Service Workers aggressively. IndexedDB storage is browser-dependent and limited. Camera/GPS APIs are fragmented. No real background sync on iOS. Push notifications still flaky |
| **Verdict** | Failed the **iOS reliability stress test**. Your field auditors on iPhones are the primary users, and the PWA is fundamentally constrained by Safari's limitations |

### ❌ Kotlin Multiplatform (KMP)

| Factor | Assessment |
|--------|------------|
| **Pro** | Shared business logic in Kotlin, native UI per platform |
| **Con** | Still need SwiftUI + Jetpack Compose for UI (two UI codebases). Ecosystem is young. Supabase Kotlin SDK is less mature |
| **Verdict** | Failed the **single-codebase stress test**. You want one team writing one UI, not two native UI layers |

---

## 8. Phased Roadmap

### Phase 1: Foundation & Auth (2-3 weeks)
- Flutter project scaffold (Clean Architecture + feature folders)
- `supabase_flutter` integration
- Auth flow (login, session persistence, RBAC route guards)
- Navigation shell (GoRouter)
- Design system (theme tokens, shared widgets matching current UI)
- CI pipeline: GitHub Actions → TestFlight + Firebase App Distribution

### Phase 2: Core Audit Flow — Online (3-4 weeks)
- Template list + detail viewer
- Store selector with search
- Audit form (multi-section, criteria rendering, answer capture)
- Photo capture (`image_picker`)
- Scoring engine (pure Dart port — TDD)
- GPS verification (`geolocator`)
- Online submission path

### Phase 3: Offline Engine (3-4 weeks)
- Drift database schema (templates, stores, profiles, outbox, drafts)
- Read-path caching
- Transactional outbox + FIFO sync
- Photo blob persistence
- Connectivity monitoring + auto-sync
- **Gate**: Airplane Reboot Test ✅

### Phase 4: Secondary Features (2-3 weeks)
- Action Plan management
- Dashboard with `fl_chart`
- Notifications (realtime channels + FCM push)
- Dark mode / theme switching

### Phase 5: Distribution & Polish (1-2 weeks)
- TestFlight first build + tester onboarding
- Firebase App Distribution first build
- Shorebird integration for OTA updates
- Performance profiling
- UAT with real field auditors

> **Total: ~11-16 weeks** (1 full-time developer)

---

## 9. Key Decision Points for You

| # | Question | Impact |
|---|----------|--------|
| 1 | **Flutter mobile-only, or Flutter Web too?** | If Flutter Web → you can eventually sunset the React PWA and have one codebase for everything. Trade-off: Template Builder drag-and-drop is harder in Flutter |
| 2 | **Start with a POC?** | A 2-3 day proof of concept (auth + one offline audit submit) would validate the approach before committing to 3-4 months of work |
| 3 | **What happens to the React PWA?** | Option A: Run both (PWA for admin, Flutter for field). Option B: Sunset PWA once Flutter reaches parity. Option C: Flutter Web replaces everything |
| 4 | **Team capacity?** | 1 dev × 16 weeks, or 2 devs × 8-10 weeks? |
| 5 | **Apple Developer account?** | Do you already have one, or need to create? ($99/year, requires Apple ID) |

---

> **Scout's Note**: This is a **greenfield build**, not a migration. You're building a brand-new app from scratch that happens to behave exactly like the current one. The Supabase backend is your bridge — it stays 100% unchanged. The scoring engine is pure math and ports directly to Dart. The rest (UI, offline engine, navigation) is all new Dart code designed from the ground up for mobile.
