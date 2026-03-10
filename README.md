# Checkly

Mobile audit platform built with Flutter and a self-hosted ASP.NET Core backend.

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Mobile App | Flutter 3.41 (Dart) |
| Backend API | ASP.NET Core 10 |
| Database | PostgreSQL 18 |
| Local Storage | Drift (SQLite) |

## Project Structure

```
Checkly/
├── lib/           ← Flutter app code
├── android/       ← Android build config
├── ios/           ← iOS build config
├── server/        ← ASP.NET Core Web API
├── test/          ← Flutter tests
└── docs/          ← Project documentation
```

## Prerequisites

- Flutter SDK 3.41+
- .NET SDK 10+
- PostgreSQL 18+
- Android Studio (for Android SDK & emulator)
- JDK 25+

## Getting Started

```bash
# Run Flutter app
flutter run

# Run API server
dotnet run --project server/Checkly.Api.csproj
```
