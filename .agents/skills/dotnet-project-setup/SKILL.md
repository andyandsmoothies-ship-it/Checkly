---
name: dotnet-project-setup
description: >
  Enterprise .NET solution architecture: Directory.Build.props, Central Package Management (Directory.Packages.props), 
  EditorConfig, and Static Code Analysis. Make sure to load and use this skill whenever you are instructed to create a 
  new .NET project/solution, fix NuGet dependency version drifts, implement global compiler warnings, set up CI/CD workflows, 
  or standardize code configuration across multiple C# projects.
---

# 6 Steps for Setting Up a New .NET Project

> [!NOTE]
> **Architectural Context:** Setting up multiple `.csproj` files with duplicate `<PropertyGroup>` and `<PackageReference>` nodes creates massive technical debt. Do not manually update versions in individual projects.

## Core Strategy

Never rely on individual `.csproj` files to manage framework targets, C# versions, warnings, nullable contexts, or external NuGet versions in a multi-project solution. Elevate configuration to the Solution Root using **Directory configuration files**.

## 1. Directory.Build.props (Central Build Config)
Place this file in the solution root to enforce build settings universally. Delete these identical `<PropertyGroup>` tags from all individual `.csproj` files.

```xml
<Project>
  <PropertyGroup>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>enable</Nullable>
    <TreatWarningsAsErrors>true</TreatWarningsAsErrors>
    <!-- Code Analysis Rules -->
    <AnalysisLevel>latest</AnalysisLevel>
    <AnalysisMode>All</AnalysisMode>
    <CodeAnalysisTreatWarningsAsErrors>true</CodeAnalysisTreatWarningsAsErrors>
    <EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>
  </PropertyGroup>

  <!-- Global Code Analysis Packages -->
  <ItemGroup>
    <PackageReference Include="SonarAnalyzer.CSharp" PrivateAssets="all" IncludeAssets="runtime; build; native; contentfiles; analyzers; buildtransitive" />
  </ItemGroup>
</Project>
```

## 2. Directory.Packages.props (Central Package Management)
Prevents "version drift" where `ModuleA` uses EntityFramework `10.0.1` and `ModuleB` uses `10.0.0`. 

```xml
<Project>
  <PropertyGroup>
    <ManagePackageVersionsCentrally>true</ManagePackageVersionsCentrally>
  </PropertyGroup>
  <ItemGroup>
    <!-- Define VERSIONS here -->
    <PackageVersion Include="Microsoft.AspNetCore.OpenApi" Version="10.0.0" />
    <PackageVersion Include="SonarAnalyzer.CSharp" Version="10.15.0.120848" />
  </ItemGroup>
</Project>
```

**Inside your actual `.csproj` files, never specify the version:**
```xml
<!-- GOOD -->
<PackageReference Include="Microsoft.AspNetCore.OpenApi" />

<!-- BAD (Will cause a build error unless VersionOverride is used) -->
<PackageReference Include="Microsoft.AspNetCore.OpenApi" Version="10.0.0" />
```

## 3. Enforce Code Style (.editorconfig)
Always drop an `.editorconfig` at the root. The project will automatically enforce these rules during the build phase because of `<EnforceCodeStyleInBuild>true</EnforceCodeStyleInBuild>`.

If the `SonarAnalyzer.CSharp` is too strict, suppress the specific rule in the `.editorconfig`, instead of turning off the entire analyzer:
```ini
[*.cs]
dotnet_diagnostic.S1128.severity = none # E.g., suppress unused usings
```

## 4. Local Orchestration (.NET Aspire or Docker Compose)
Every developer machine must match production boundaries locally.
* **.NET Aspire (Recommended):** Code-driven orchestration (`builder.AddPostgres("db")`). It handles service discovery and OpenTelemetry automatically without needing massive YAML config loops.
* **Docker Compose:** The legacy fallback path. Map your `AppHost` layer to define `postgres`, `redis`, and core integration boundaries so tests can hook into Testcontainers easily.

## 5. CI Automation (GitHub Actions)
Prevent bad code from being merged. Your baseline `.github/workflows/build.yml` must include `--no-restore` on build and `--no-build` on test steps to reuse build output caching.

```yaml
name: Build
on:
  push:
    branches: [main]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-dotnet@v5
        with:
          dotnet-version: 10.0.x
      - run: dotnet restore
      - run: dotnet build --no-restore --configuration Release
      - run: dotnet test --no-build --configuration Release
```

## Gotchas & Edge Cases

* **VersionOverride Syntax:** If you enable `<ManagePackageVersionsCentrally>true`, adding a standard `Version="X.Y.Z"` attribute to a `.csproj` will crash the compiler. If a sub-project absolutely MUST use a different version from the global `Directory.Packages.props`, you must use `VersionOverride="X.Y.Z"`.
* **PrivateAssets="all" for Analyzers:** In `Directory.Build.props`, any analyzer packages (like `SonarAnalyzer.CSharp`) MUST include `PrivateAssets="all"`. If omitted, the dependency will leak to consumer projects if you build a library or a NuGet package, ballooning the package size with unintended compiler tooling.
* **Overriding TargetFrameworks:** If you have a shared library that builds multiple targets (`<TargetFrameworks>net8.0;netstandard2.0</TargetFrameworks>`), placing it overridingly in the `.csproj` will conflict with `<TargetFramework>` in `Directory.Build.props`. Handle this carefully by placing common properties in `Directory.Build.props` but leaving standard exclusions cleanly separated.
