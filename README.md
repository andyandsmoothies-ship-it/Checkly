# Checkly

**Mobile-first audit & inspection platform** — build dynamic templates, run audits offline, score automatically, and track corrective actions. Built with Flutter and a self-hosted ASP.NET Core API backed by PostgreSQL.

---

## Key Features

- **Dynamic Template Engine** — 4 scoring modes (Penalty, Accumulation, Checklist, Survey), 5 input types, nested sections, CCP/RISK overrides, and weighted density. One engine powering food safety audits, mystery shops, training quizzes, daily checklists, and employee surveys.
- **Offline-First** — Complete audits without internet. Data is persisted to a local SQLite database (Drift) and synced to the server when connectivity returns.
- **Real-Time Scoring** — Live score HUD during audits with section breakdowns, progressive repeat penalties, and confirm-correct mode.
- **Role-Based Analytics** — Dedicated dashboards for Admins (global KPIs), Area Managers (store leaderboard), Store Managers (store snapshot), and Auditors (personal calibration stats).
- **Action Plan Workflow** — Create corrective actions from failed criteria with deadlines, reminders, and status tracking.
- **Server-Side Score Verification** — The backend independently recalculates scores and rejects submissions with suspicious deltas (>5%).

---

## Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart 3.11+) | Cross-platform iOS & Android |
| **Backend API** | ASP.NET Core (.NET 10) | Vertical Slice Minimal API |
| **Database** | PostgreSQL (via Supabase) | Primary data store |
| **ORM** | Entity Framework Core | Server-side data access |
| **Auth** | Supabase Auth (JWT) | Authentication + RBAC |
| **Local DB** | Drift (SQLite) | Offline cache & sync |
| **DI** | get_it / watch_it | Flutter service locator |

### Roles

| Role | Scope | Capabilities |
|------|-------|-------------|
| **Admin** | Global | Manage templates, users, stores, analytics, survey results |
| **Area Manager** | Regional (assigned area) | View store leaderboard, area-level compliance |
| **Store Manager** | Single store | View store dashboard, manage action plans |
| **Auditor** | Self | Conduct audits, view personal stats |

---

## Project Structure

```
Checkly/
├── lib/                          ← Flutter app (Feature-Sliced Design)
│   ├── features/
│   │   ├── audit/                ← Audit form, scoring engine, manager
│   │   ├── templates/            ← Template builder, detail, list
│   │   ├── analytics/            ← Analytics dashboards
│   │   ├── admin/                ← Admin panel
│   │   └── profile/              ← User profile & settings
│   └── _shared/                  ← Router, widgets, services, database
├── server/                       ← ASP.NET Core Web API
│   ├── Features/                 ← Vertical Slice handlers
│   │   ├── Templates/            ← Template CRUD
│   │   ├── Submissions/          ← Audit submissions
│   │   ├── Analytics/            ← KPI & reporting endpoints
│   │   ├── Stores/               ← Store management
│   │   └── Admin/                ← User & role management
│   └── Common/
│       └── Persistence/          ← EF Core DbContext, Entities, Migrations
├── test/                         ← Flutter unit & integration tests
├── server/tests/                 ← .NET integration tests
└── docs/                         ← Reference documentation
```

---

## Prerequisites

- **Flutter SDK** 3.41+ (Dart 3.11+)
- **.NET SDK** 10+
- **PostgreSQL** 18+ (or a Supabase project)
- **Android Studio** (for Android SDK & emulator)
- **JDK** 25+

---

## Getting Started

### 1. Clone & Install Dependencies

```bash
git clone <your-repo-url>
cd Checkly

# Flutter dependencies
flutter pub get

# .NET dependencies (restored automatically on build)
dotnet restore server/Checkly.Api.csproj
```

### 2. Configure Environment

Create a `server/appsettings.Development.json` with your database connection:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Host=localhost;Database=checkly;Username=postgres;Password=your_password"
  },
  "Supabase": {
    "Url": "https://your-project.supabase.co",
    "JwtSecret": "your-jwt-secret"
  }
}
```

### 3. Run Database Migrations

```bash
cd server
dotnet ef database update
```

### 4. Start the Application

```bash
# Terminal 1 — API server
dotnet run --project server/Checkly.Api.csproj

# Terminal 2 — Flutter app
flutter run
```

---

## Documentation

| Document | Description |
|----------|------------|
| [Database Schema](docs/DATABASE_SCHEMA.md) | Full table definitions and relationships |
| [Scoring Logic](docs/reference/SCORING_LOGIC.md) | Scoring modes, formulas, CCP/RISK rules |
| [Supported Use Cases](docs/reference/SUPPORTED_USE_CASES.md) | 15 real-world template configurations |
| [Mobile Dev Setup](docs/MOBILE_DEV_SETUP.md) | Device setup and debugging guide |

---

## Testing

```bash
# Flutter tests
flutter test

# .NET tests
dotnet test server/tests/Checkly.Api.Tests/
```
