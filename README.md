# Checkly

![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter)
![.NET 10](https://img.shields.io/badge/.NET-10.0-512BD4?logo=dotnet)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-Self_Hosted-336791?logo=postgresql)
![AI Governed](https://img.shields.io/badge/AI_Governed-Strict_SDLC-8A2BE2)
![Status](https://img.shields.io/badge/Status-UAT-success)

**Mobile-first audit & inspection platform** — build dynamic templates, run audits offline, score automatically, and track corrective actions. Built with Flutter and a self-hosted ASP.NET Core API backed by PostgreSQL. 

> **Last Updated:** May 13, 2026

---

## Key Features

- **Dynamic Template Engine** — 4 scoring modes (Penalty, Accumulation, Checklist, Survey), 5 input types, nested sections, CCP/RISK overrides, and weighted density. One engine powering food safety audits, mystery shops, training quizzes, daily checklists, and employee surveys.
- **Programs & Campaigns** — Assign specific templates to target stores or areas with strict deadlines. Program assignments sync automatically to offline devices for execution.
- **Offline-First** — Complete audits without internet. Data is persisted to a local SQLite database (Drift) and synced via a resilient, plugin-based background Sync Engine featuring exponential backoff when connectivity returns.
- **Real-Time Scoring** — Live score HUD during audits with section breakdowns, progressive repeat penalties, and confirm-correct mode.
- **Enterprise & Boardroom Analytics** — Role-aware command center with contextual stat cards, hierarchical drilldowns, and SQLite aggregations for Auditors, Managers, and Admins. Features a Boardroom Executive Dashboard with OLAP-style pre-computed snapshots for Store Leaderboards, Category Weakness, and Auditor Productivity.
- **Action Plan Workflow** — Auto-generated corrective actions from failed criteria with deadlines, reminders, and status tracking.
- **Server-Side Score Verification** — The backend independently recalculates scores and rejects submissions with suspicious mathematical deltas.
- **Notification Engine** — Real-time SignalR notifications and in-app inbox for audit submissions and action plan deadlines.
- **AI-Agent Governed** — Architecture is rigidly maintained by autonomous AI agents using context-cascading `GEMINI.md` rule files, double-loop ATDD workflows, and Python script quality gates.

---

## Architecture

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Mobile App** | Flutter (Dart 3.11+) | Cross-platform iOS & Android |
| **Backend API** | ASP.NET Core (.NET 10) | Vertical Slice Architecture |
| **Database** | PostgreSQL 18+ (Self-Hosted) | Primary data store |
| **ORM** | Entity Framework Core 10 | Server-side data access |
| **Auth & Security** | ASP.NET Core Identity (JWT) | Authentication + PBAC |
| **Local DB** | Drift (SQLite) | Offline cache & sync outbox |
| **State & DI** | PFA (get_it / watch_it) | Pragmatic Flutter Architecture |

### Roles & Access Control

Checkly relies entirely on **Permission-Based Access Control (PBAC)**. Roles are mapped to capabilities (e.g., `templates:create`) via a cached `role_capabilities` system. The UI and API evaluate granular capabilities rather than hardcoded role strings.

| Role | Scope | Capabilities |
|------|-------|-------------|
| **Admin** | Global | Manage templates, users, stores, areas, analytics, survey results |
| **Area Manager** | Regional (assigned area) | View store leaderboard, area-level compliance, verify action plans |
| **Store Manager** | Single store | View store dashboard, manage/submit action plan evidence |
| **Auditor** | Self | Conduct audits, view personal stats |

---

## Project Structure

```text
Checkly/
├── lib/                          ← Flutter app (Feature-Sliced Design)
│   ├── features/
│   │   ├── action_plans/         ← Corrective workflow, status boards
│   │   ├── admin/                ← Users, Stores, Areas, System Logs
│   │   ├── analytics/            ← Analytics dashboards & charts
│   │   ├── audit/                ← Audit form, scoring engine, offline manager
│   │   ├── auth/                 ← Login, cached offline sessions
│   │   ├── dashboard/            ← Enterprise command center
│   │   ├── notifications/        ← SignalR inbox
│   │   ├── profile/              ← User profile & settings
│   │   ├── programs/             ← Campaign targeting & assignments
│   │   ├── stores/               ← Store directory & management
│   │   ├── templates/            ← Template builder, detail, list
│   │   └── user_groups/          ← RBAC management
│   └── _shared/                  ← Router, widgets, services, Drift DB
├── server/                       ← ASP.NET Core Web API (Vertical Slice)
│   ├── Features/
│   │   ├── ActionPlans/          ← Corrective plan CRUD
│   │   ├── Admin/                ← System logs & admin tools
│   │   ├── Analytics/            ← KPI & reporting endpoints
│   │   ├── Areas/                ← Area hierarchy management
│   │   ├── Auth/                 ← JWT issuance & PBAC
│   │   ├── GlobalRisks/          ← Template-agnostic critical flags
│   │   ├── Notifications/        ← SignalR hub & alerts
│   │   ├── Photos/               ← Offline sync & media storage
│   │   ├── Programs/             ← Program & assignment logic
│   │   ├── Stores/               ← Store management
│   │   ├── Submissions/          ← Audit submissions & score verification
│   │   ├── System/               ← Health checks & background workers
│   │   ├── Templates/            ← Template CRUD
│   │   ├── UserGroups/           ← Role & permission mapping
│   │   └── Users/                ← Profile & assignment management
│   └── Common/                   ← Shared Infrastructure (Persistence, Scoring)
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

**1. Backend**
```bash
# Terminal 1 — API server
dotnet run --project server/Checkly.Api.csproj
```
*(Leave this terminal open to keep the backend ALIVE).*

**2. Frontend**
Find your PC's LAN IP (`ipconfig`) and your connected Android Device ID (`adb devices`).
```powershell
flutter run -d <DEVICE_ID> --dart-define=API_BASE_URL=http://<YOUR_LAN_IP>:5288/api
```
*(For Windows Desktop fallback without a phone: `flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5288/api`)*

---

## 📚 Documentation
- [Product Requirements (PRD)](docs/project/PRD_checkly_mobile.md)
- [Database Schema (PBAC)](docs/project/DATABASE_SCHEMA.md)
- [Supported Use Cases (Scoring Modes)](docs/reference/SUPPORTED_USE_CASES.md)
- [Core Workflows & State Machines](docs/reference/CORE_WORKFLOWS.md)
- [Scoring Logic Architecture](docs/reference/SCORING_LOGIC.md)

---

## Testing

```bash
# Flutter tests
flutter test

# .NET tests
dotnet test server/tests/Checkly.Api.Tests/
```
