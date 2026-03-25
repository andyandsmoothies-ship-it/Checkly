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

![Checkly Architecture Diagram](https://www.plantuml.com/plantuml/svg/dLPBRzim3BxxLt0v9HZQt7CecjfDLw2FjCxQmrOCYiscGcp9a-IjmT3_Faf-n4tax9537kH7yZD9VSgfDaoPCi-23-O5SuGYOrm4Uir5mHJB8P5v8GKA4vjDXg0mCKoiCkn0MXly2e1UPonPhvGiHHhAJ2fuVE46AuzKAQhA6Z6rlb1i4xnrKXKKobR_dIWmt12DGVY2oJhRGBpH1dEOgiH69gPKEFagPiZijwCuumcc4A7cAm73MHoDu2Cye38yOHauzxjO63x4qz4W21gQWp3Zr1guOXjK4vXbfJ6eA9MlmcXGFrRRKXZ4BqmH89GsUSQNus_QMGZBDDJUAig-ljpBaWeyRGtJebZOkNLDyqkeUGqZBaULYvfZFrhcDKLTbNskVxKSVTW9B32d_J0swlCbzUhiIeRZQoO8fIhACmVf976KchYpacSqjpdXd_o8EbcFTrhm6DKFQkeMyDP-Eq1yMgRSz9Ekt3kadN4cLUwXwtn-hixLJxHwTsyfCsp9DF6yVNxEk42OezASLbOaw8XTILh4wAox0Sv4Er-73YDyvJYExwveITjHjoMydOVZuvFzZiC4xf6bUloeA9KEF3se0jyzkoygy4uKZevEsWUQGFF88QFp9LR1Vbl_8k109T_EK9Pu8nAG1Ifck1Iwh-pU57j2Wxxrh5lbFOhxoNl0T6QJJ9Of33uj5lCORj3yb6fDwaUIoDJ6xKXjx8YIJKigL8lIyStveXAOQovuJijZ2mqFo5mh0dsAeLs1yUoWQ3HDWGPMIPfN7q9566mZpaLQI2xCpicwGBCLe1vCcoDQtEg_4ucuNEPSQvhf3bLox19rM5F9HJ_BJiOUK0VX8_hcQRyzyZ1D4jJR2OGopwKOTsIZ4hIEeQiTT5b4or0AWw-qO-SpjnQZpjKHoPnkVo9DzoX7lIydUplgJakpbnEtMlVulKHjN43ZSMUgRyfMG-ozjX_XdtW_tZkUT_3WuBxLPz_V9ifZ-yr4Mij63xi_vBWhKV56N_s4_uL5S6YobR3iJfLINBD2Wv5MORQtq5ngir98TmaCux9mrcgVGgj2xXwYWDvYbdQ39BcaD6DOX7FwloC4AGijUt2A8hL_Ddy3)

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart 3.11+) | Cross-platform iOS & Android |
| **Backend API** | ASP.NET Core (.NET 10) | Vertical Slice Minimal API |
| **Database** | PostgreSQL (Self-Hosted) | Primary data store |
| **ORM** | Entity Framework Core | Server-side data access |
| **Auth** | ASP.NET Core Identity (JWT) | Authentication + RBAC |
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
- **PostgreSQL** 18+
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
