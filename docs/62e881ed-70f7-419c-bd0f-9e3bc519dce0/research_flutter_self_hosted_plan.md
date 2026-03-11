# Checkly Flutter — Development Plan (Self-Hosted Backend)

> **Author**: Scout (Lead Architect)
> **Date**: 2026-03-10 (Updated: 2026-03-10)
> **Status**: ✅ Approved — Prerequisites Complete, Ready for Phase 0
> **Trigger**: User constraints: No Supabase, No App Store publishing. Self-hosted on Windows Server.
> **Repo**: [github.com/andyandsmoothies-ship-it/Checkly](https://github.com/andyandsmoothies-ship-it/Checkly)

## Context & References

| Source | Notes |
|--------|-------|
| [concept_brief_flutter_migration.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/62e881ed-70f7-419c-bd0f-9e3bc519dce0/concept_brief_flutter_migration.md) | Original concept brief (Supabase-based) |
| [backend_database_architecture.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/62e881ed-70f7-419c-bd0f-9e3bc519dce0/backend_database_architecture.md) | Original backend plan (Supabase-based) |
| [flutter_starter_knowledge_pack.md](file:///c:/Users/HP/Documents/GitHub/Checkly/docs/62e881ed-70f7-419c-bd0f-9e3bc519dce0/flutter_starter_knowledge_pack.md) | Knowledge transfer checklist |
| KI: Product Strategy | Platform vision and scoring model |
| KI: Offline Architecture | Battle-tested 8-phase offline pattern |
| Skill: `flutter-architecture` | PFA pattern with get_it/watch_it |
| Skill: `flutter-development` | Flutter best practices |

---

## 1. Answering Your Questions First

### Q1: "Do I need to publish on App Store / Play Store for internal use?"

**No.** You do NOT need to publish on any store.

| Platform | Internal Distribution Method | Cost | Store Required? |
|----------|------------------------------|------|-----------------|
| **Android** | Build APK → share via file transfer (USB, cloud drive, messaging) | **Free** | ❌ No |
| **Android** | Build APK → host on your Windows Server as download link | **Free** | ❌ No |
| **iOS** | Build IPA → install via Xcode on connected iPhones | **Free** (with free Apple ID) | ❌ No |
| **iOS** | Ad-hoc distribution (IPA signed with provisioning profile) | **$99/yr** Apple Developer Program | ❌ No store, but need developer account |
| **iOS (Easiest)** | TestFlight (internal only, up to 10,000 testers, auto-update) | **$99/yr** Apple Developer Program | ❌ No App Store review needed |

> [!IMPORTANT]
> **Android is trivially easy** — just build the APK and share the file. Users enable "Install from unknown sources" once.
>
> **iOS is harder** — Apple restricts sideloading. Your realistic options:
> - **If you have < 3 iPhones**: Install directly via Xcode + USB cable. Free.
> - **If you have 3-25 iPhones**: Ad-hoc provisioning ($99/yr). Register each device's UDID.
> - **If you have 25+ iPhones**: TestFlight ($99/yr). Easiest for updates. No store review.
> - **Enterprise Program** ($299/yr): Unlimited devices, but Apple rarely approves small companies.

**Scout's Recommendation**: If your users are mostly Android → just share APK files. If iOS users exist → TestFlight internal testing is the least painful option for $99/yr.

---

### Q2: "I will use a local database, not Supabase. Setup on my PC now, deploy to Windows Server later."

This is a **fundamental architecture change** from the original plan. Here's what it means:

| Aspect | Original Plan (Supabase) | Revised Plan (Self-Hosted) |
|--------|-------------------------|---------------------------|
| **Backend database** | Supabase PostgreSQL (cloud) | ✅ **PostgreSQL 18** on Windows Server |
| **API layer** | Supabase auto-generated REST + RLS | ✅ **ASP.NET Core 10 Web API** (`Checkly.Api`) |
| **Authentication** | Supabase Auth (JWT) | Custom auth (ASP.NET Identity, or simple JWT) |
| **File storage** | Supabase Storage buckets | Local file system on Windows Server |
| **Real-time** | Supabase Realtime channels | SignalR (ASP.NET) or WebSockets |
| **Edge Functions** | Supabase Edge Functions (Deno) | Controller actions in your API |
| **RLS security** | Automatic via Supabase policies | Manual middleware + authorization guards |
| **Server triggers** | PostgreSQL triggers | Application-level event handlers |
| **Dev setup** | Just connect to Supabase Cloud | Install PostgreSQL/SQL Server locally |
| **Deployment** | Already deployed (Supabase Cloud) | Deploy API + DB to your Windows Server |

> [!WARNING]
> **This is significantly more work than the original plan.** With Supabase, the backend was 100% done — you only needed to build the Flutter client. Now you also need to build an entire backend API + manage your own database server + handle auth + manage file storage. This roughly **doubles the project scope**.

---

## 2. Revised Technology Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| **Mobile Client** | **Flutter 3.41.4** (Dart 3.11.1) | ✅ Installed — single codebase for iOS + Android |
| **State Management** | **get_it + watch_it + command_it** (PFA pattern) | Type-safe, testable, avoids code-gen overhead of Riverpod. Follows the `flutter-architecture` skill |
| **Local Database (Mobile)** | **Drift** (SQLite ORM) | Same as original — type-safe, reactive, offline-first |
| **Navigation** | **GoRouter** | Same as original |
| **Backend API** | **ASP.NET Core 10 Web API** ⭐ | ✅ Project created (`Checkly/server/Checkly.Api`) |
| **Server Database** | **PostgreSQL 18.3** | ✅ Installed. Database `checkly` created |
| **ORM (Server)** | **Entity Framework Core 10** | Familiar from ToolKit. Type-safe, migrations built-in |
| **Authentication** | **ASP.NET Identity + JWT Bearer** | Standard .NET auth. JWT tokens work identically to Supabase tokens from Flutter's perspective |
| **File Storage** | **Local file system** on Windows Server | Simple. Served via static file middleware or API endpoint |
| **Real-time** | **SignalR** | Built into ASP.NET Core. Push notifications for status changes |
| **Camera** | `image_picker` | Same as original |
| **GPS** | `geolocator` | Same as original |

### Why ASP.NET Core for the Backend?

| Reason | Detail |
|--------|--------|
| **You already know C#** | ToolKit Shell, Shared, and Tools are all .NET 10 Blazor. Same language, same ecosystem |
| **Native Windows Server** | ASP.NET Core runs natively on Windows Server as a Windows Service or IIS site. Zero friction |
| **Entity Framework Core** | You already use this pattern mental model. Same ORM for server-side data access |
| **Built-in Auth** | ASP.NET Identity + JWT is a well-documented, battle-tested auth pipeline |
| **SignalR** | Real-time push for notifications, audit status changes. Built-in, no external dependency |
| **Single deployment** | API + database + file storage all on one Windows Server. Simple ops |

> [!TIP]
> **Alternative backend**: If you prefer something lighter, **Node.js + Express + Prisma** is another option. But since you already have deep .NET skills from ToolKit, ASP.NET Core is the path of least resistance.

---

## 3. Revised Architecture Diagram

```
┌──────────────────────────────────────────────────────────────┐
│                      MOBILE DEVICE                           │
│                                                              │
│  ┌──────────────┐   ┌───────────────┐   ┌───────────────┐  │
│  │  Flutter UI   │──▶│  Managers     │──▶│  Repository   │  │
│  │  (Widgets)    │   │  (get_it/PFA) │   │  Layer        │  │
│  └──────────────┘   └───────────────┘   └───┬───────┬───┘  │
│                                              │       │       │
│                                    ┌─────────▼┐ ┌───▼─────┐ │
│                                    │  Drift    │ │  API    │ │
│                                    │  (SQLite) │ │  Client │ │
│                                    └──────┬────┘ └───┬─────┘ │
│                                           │          │       │
│                                    ┌──────▼──────────▼─────┐ │
│                                    │     Sync Engine        │ │
│                                    └───────────┬───────────┘ │
└────────────────────────────────────────────────┼─────────────┘
                                                 │ HTTPS
                                                 ▼
┌──────────────────────────────────────────────────────────────┐
│                    WINDOWS SERVER                            │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐   │
│  │           ASP.NET Core 10 Web API                     │   │
│  │  ┌──────────┐ ┌──────────┐ ┌────────┐ ┌──────────┐  │   │
│  │  │ Auth     │ │ Audit    │ │ Store  │ │ Scoring  │  │   │
│  │  │ Controller│ │ Controller│ │ Ctrl  │ │ Service  │  │   │
│  │  └──────────┘ └──────────┘ └────────┘ └──────────┘  │   │
│  │  ┌──────────┐ ┌──────────┐ ┌────────────────────┐   │   │
│  │  │ SignalR  │ │ File     │ │ EF Core + Migrations│   │   │
│  │  │ Hub      │ │ Storage  │ │                     │   │   │
│  │  └──────────┘ └──────────┘ └─────────┬──────────┘   │   │
│  └──────────────────────────────────────┼──────────────┘   │
│                                          │                   │
│  ┌───────────────────────────────────────▼─────────────────┐ │
│  │             PostgreSQL 18                                │ │
│  │  (Same schema as current Supabase — migrated)            │ │
│  └──────────────────────────────────────────────────────────┘ │
│                                                              │
│  ┌──────────────────────────────────────────────────────────┐ │
│  │         File System (photos/, evidence/)                  │ │
│  └──────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────┘
```

---

## 4. What Changes from the Original Plan

### 4.1 Removed (No Longer Applicable)

| Item | Reason |
|------|--------|
| Supabase SDK (`supabase_flutter`) | No Supabase. Use `http`/`dio` + custom API client |
| Supabase Auth | Replace with ASP.NET Identity + JWT |
| Supabase Realtime channels | Replace with SignalR |
| Supabase Storage buckets | Replace with file system + API endpoints |
| Supabase Edge Functions | Replace with ASP.NET Controller actions |
| RLS policies | Replace with .NET authorization middleware |
| `get_changes_since` RPC | Build as a standard API endpoint |
| TestFlight / Firebase App Distribution | APK sideload + optional TestFlight if iOS needed |
| Shorebird OTA | Still possible, but less critical without store distribution |
| Firebase Cloud Messaging (FCM) | Can still use FCM for push, or skip if SignalR is enough |

### 4.2 Unchanged (Still Applies)

| Item | Notes |
|------|-------|
| **Flutter client framework** | Same |
| **Drift local database** | Same — local-first architecture stays |
| **Scoring engine** | Same — pure Dart port of the algorithm |
| **Offline architecture (8 phases)** | Same pattern, different sync target (your API instead of Supabase) |
| **Photo capture (`image_picker`)** | Same |
| **GPS verification (`geolocator`)** | Same |
| **GoRouter navigation** | Same |
| **Design system (tokens, fonts)** | Same |

### 4.3 New (Must Build)

| Component | Effort Estimate | Priority |
|-----------|----------------|----------|
| **ASP.NET Core Web API** (full backend) | 3-4 weeks | 🔴 Critical |
| **PostgreSQL schema migration** (from Supabase DDL) | 2-3 days | 🔴 Critical |
| **Auth system** (ASP.NET Identity + JWT) | 1 week | 🔴 Critical |
| **API Client** in Dart (replaces Supabase SDK) | 1 week | 🔴 Critical |
| **File upload/download endpoints** | 2-3 days | 🟡 High |
| **SignalR hub for notifications** | 2-3 days | 🟢 Medium |
| **Server-side scoring verification** | 2-3 days | 🟡 High |
| **Database triggers → Application events** | 1 week | 🟡 High |

---

## 5. Revised Phased Roadmap

### Phase 0: Backend Foundation (3-4 weeks) ⭐ NEW

> This phase didn't exist in the original plan because Supabase was "done."

| Task | Detail |
|------|--------|
| **PostgreSQL setup on your PC** | ✅ Done — PostgreSQL 18.3 installed, database `checkly` created |
| **ASP.NET Core Web API project** | ✅ Done — `Checkly.Api` at `server/`. Clean Architecture or Vertical Slice |
| **EF Core + schema** | Map all tables (`profiles`, `user_roles`, `stores`, `templates`, `groups`, `criteria`, `submissions`, `answers`, `action_plans`, `notifications`, `photos`) |
| **Auth endpoints** | `POST /auth/login`, `POST /auth/register`, `POST /auth/refresh`. JWT bearer tokens |
| **CRUD endpoints** | RESTful controllers for all entities. Role-based authorization |
| **File upload endpoint** | `POST /photos/upload`, `GET /photos/{id}` |
| **Scoring verification** | `POST /submissions/finalize` — server-side score recalculation |
| **Delta sync endpoint** | `GET /sync/{entity}?since={timestamp}` — returns changed rows since last sync |
| **SignalR hub** | Real-time notification push |

### Phase 1: Flutter Foundation & Auth (2-3 weeks) — *Mostly same as original*

| Task | Change from Original |
|------|---------------------|
| Flutter project scaffold | Same — PFA pattern with feature folders |
| Auth flow | **Changed**: Custom JWT auth instead of `supabase_flutter` |
| API Client class | **New**: `dio` or `http` package pointing to `http://localhost:5000` (dev) → `https://your-server.com` (prod) |
| Navigation + GoRouter guards | Same |
| Design system | Same |
| CI pipeline | **Simplified**: Just build APK. No TestFlight/Firebase upload step |

### Phase 2: Core Audit Flow — Online (3-4 weeks) — *Same scope*

| Task | Change from Original |
|------|---------------------|
| Template list + detail | **Changed**: API call to your backend instead of Supabase |
| Store selector | Same pattern, different API |
| Audit form | Same |
| Photo capture | Same |
| Scoring engine (Dart port) | Same — pure functions, no API dependency |
| GPS verification | Same |
| Online submission | **Changed**: `POST /submissions` to your API instead of Supabase INSERT |

### Phase 3: Offline Engine (3-4 weeks) — *Same architecture*

| Task | Change from Original |
|------|---------------------|
| Drift schema | Same tables |
| Read-path caching | Same — but delta sync hits your API |
| Transactional outbox | Same pattern |
| Photo blob persistence | Same |
| Connectivity + auto-sync | **Changed**: Sync target is your API, not Supabase |
| **Gate**: Airplane Reboot Test | Same validation |

### Phase 4: Secondary Features (2-3 weeks) — *Same scope*

| Task | Change from Original |
|------|---------------------|
| Action Plans | Same CRUD, different API |
| Dashboard | Same — charts via `fl_chart` |
| Notifications | **Changed**: SignalR instead of Supabase Realtime |
| Dark mode | Same |

### Phase 5: Deployment & Polish (1-2 weeks)

| Task | Change from Original |
|------|---------------------|
| Deploy API to Windows Server | **New**: IIS or Windows Service hosting |
| Deploy PostgreSQL to Windows Server | **New**: PostgreSQL installer on Windows |
| Build APK | Share file to Android users |
| Build IPA (if iOS needed) | TestFlight or direct Xcode install |
| UAT with field auditors | Same |

---

## 6. Total Effort Estimate (Revised)

| Phase | Original (Supabase) | Revised (Self-Hosted) | Delta |
|-------|---------------------|----------------------|-------|
| Phase 0: Backend | N/A (already done) | **3-4 weeks** | +3-4 weeks |
| Phase 1: Foundation | 2-3 weeks | 2-3 weeks | Same |
| Phase 2: Audit Flow | 3-4 weeks | 3-4 weeks | Same |
| Phase 3: Offline | 3-4 weeks | 3-4 weeks | Same |
| Phase 4: Features | 2-3 weeks | 2-3 weeks | Same |
| Phase 5: Deploy | 1-2 weeks | 1-2 weeks | Same |
| **TOTAL** | **11-16 weeks** | **14-20 weeks** | **+3-4 weeks** |

> [!IMPORTANT]
> The self-hosted backend adds ~3-4 weeks of work, but gives you **full control** over your data, **zero monthly hosting costs** (besides your own server), and **no vendor lock-in**.

---

## 7. Development Setup — ✅ COMPLETED

| Step | Status | Actual |
|------|--------|--------|
| PostgreSQL | ✅ Done | PostgreSQL 18.3, database: `checkly`, port 5432 |
| ASP.NET Core API | ✅ Done | `Checkly.Api` at `Checkly/server/`, .NET 10 |
| Flutter project | ✅ Done | `checkly` at `Checkly/`, org: `com.checkly`, platforms: Android + iOS |
| Flutter SDK | ✅ Done | 3.41.4 stable, Dart 3.11.1 |
| JDK | ✅ Done | Temurin 25.0.2 LTS |
| Android SDK | ✅ Done | API 36, Build Tools 36 |
| Android Emulator | ✅ Done | Pixel 9, API 36.1 (Google Play) |
| Git + GitHub | ✅ Done | Pushed to `andyandsmoothies-ship-it/Checkly` |
| iOS build strategy | 📋 Planned | Develop on Windows, build IPA via Codemagic CI |

### Next: Add NuGet packages to `server/Checkly.Api`

```powershell
dotnet add server/Checkly.Api.csproj package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add server/Checkly.Api.csproj package Microsoft.AspNetCore.Identity.EntityFrameworkCore
dotnet add server/Checkly.Api.csproj package Microsoft.AspNetCore.Authentication.JwtBearer
```

### Next: Add Dart packages to Flutter

```powershell
flutter pub add drift go_router dio get_it watch_it
flutter pub add dev:drift_dev dev:build_runner
```

---

## 8. Key Decision Points

| # | Question | Decision |
|---|----------|----------|
| 1 | **PostgreSQL or SQL Server?** | ✅ **PostgreSQL 18** — confirmed and installed |
| 2 | **Do you have iOS users?** | ✅ **Yes** — develop/test both, deploy Android first. iOS build via Codemagic CI |
| 3 | **Start with backend or Flutter first?** | ✅ **Backend first** (Phase 0) — both projects scaffolded, ready to go |
| 4 | **ASP.NET Clean Architecture or Vertical Slice?** | ⏳ Pending — decide when starting Phase 0 |
| 5 | **Push notifications needed?** | ⏳ Pending — SignalR for foreground, FCM for background if needed |
| 6 | **One developer or team?** | ⏳ Pending — 14-20 weeks solo, 10-12 weeks with 2 devs |

---

## 9. Windows Server Deployment Preview

When you're ready to deploy (after everything works locally):

```
Windows Server
├── IIS / Kestrel
│   └── Checkly.Api (ASP.NET Core Web API)
│       ├── appsettings.json (connection string, JWT secret)
│       └── wwwroot/uploads/ (photo storage)
├── PostgreSQL 18
│   └── checkly database
└── Firewall
    └── Open port 443 (HTTPS) for mobile app access
```

- **HTTPS**: Use Let's Encrypt or a self-signed certificate (for internal use, self-signed is fine)
- **Domain**: Point an internal DNS or use the server's IP address
- **Flutter config**: Change API base URL from `http://localhost:5000` → `https://your-server-ip-or-domain`

---

> **Scout's Summary**: Dropping Supabase means you own the full stack — more control, zero vendor costs, but ~3-4 weeks extra to build the backend. Since you already know ASP.NET Core + EF Core from ToolKit, the backend is familiar territory. The Flutter client architecture stays nearly identical — the only difference is that API calls go to your server instead of Supabase. Start with **Phase 0 (Backend)** on your PC, then build the Flutter app against it.
>
> **Handoff**: Prerequisites complete ✅. All tools installed, projects scaffolded, pushed to GitHub. Ready to assign Forge to execute **Phase 0 (Backend API)**.
