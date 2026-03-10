---
name: ToolKit Platform Rules
description: Architecture, C# coding standards, and plugin development rules for the ToolKit .NET 10 platform.
trigger: always_on
---

# ToolKit Platform Rules

## 1. Architecture

- **Purpose**: Enterprise-grade internal platform hosting modular mini tools under a single Blazor Server shell.
- **Philosophy**: Zero-Bloat, Transactional Integrity, Managerial UX.
- **Framework**: .NET 10 Blazor Server (InteractiveServer render mode).
- **3-Layer Model**:
  - **Shell** (`ToolKit.Shell`): Host app — layout, nav, admin panel, middleware, error boundaries.
  - **Shared** (`ToolKit.Shared`): Contracts (`IToolPlugin`) and cross-cutting services (`AuditLogService`, `LockService`, `PermissionService`, `ToolRegistry`).
  - **Tool RCLs** (`ToolKit.[Name]`): Business logic, tool-specific pages and services.
- **Data Persistence**: Local file-based storage ONLY. No external databases.
  - Shared: `data/shared/` (audit.log, permissions.json).
  - Per-tool: `data/{tool-id}/` (tool-specific data files).

## 2. Tech Stack

| Category | Technology | Version | Notes |
|:---------|:-----------|:--------|:------|
| Runtime | .NET | 10 | LTS, Blazor Server (InteractiveServer) |
| UI Framework | MudBlazor | 9.1.0 | Material Design components |
| Testing | xUnit | 2.9.x | Unit + integration tests |
| Testing | bUnit | 2.6.2 | Blazor component rendering tests |
| Circuit Mgmt | `CircuitHandler` | built-in | `IdleCircuitHandler` → lock cleanup on disconnect |
| Error Handling | `ErrorBoundary` | built-in | Auto-recovery via `OnParametersSet` |
| Error Handling | `DispatchExceptionAsync` | built-in | Surfaces background thread errors to UI |
| Observability | OpenTelemetry | — | Deferred (API incompatible with .NET 10) |

### Resilience Patterns
- **ErrorBoundary auto-recovery**: `MainLayout.razor` calls `_errorBoundary?.Recover()` in `OnParametersSet` — errors clear on navigation.
- **IdleCircuitHandler**: Scoped `CircuitHandler` in Shell that logs `CIRCUIT_OPENED`/`CIRCUIT_CLOSED` and releases `LockService` on disconnect.
- **DispatchExceptionAsync**: Background job exceptions in `Home.razor` are surfaced to ErrorBoundary via `InvokeAsync(() => DispatchExceptionAsync(ex))`.
- **Partial class pattern**: Large Razor pages use `.razor` (markup) + `.razor.cs` (code-behind) split for maintainability.

## 3. C# Coding Standards

### Zero Ghost Import Protocol (CRITICAL)
<strict-constraints>
- Do not use any namespace, class, or method without an explicit `using` statement or fully qualified name.
- Cross-reference `.csproj` to ensure packages are installed.
</strict-constraints>

### Dependency Injection (Layer Rules)
- **Shell `Program.cs`**: Register shared Singletons (`AuditLogService`, `LockService`, `PermissionService`, `ToolRegistry`).
- **Tool `RegisterServices()`**: Register tool-specific services ONLY (`Scoped`: session state; `Singleton`: tool-specific services).
- **NEVER** re-register a Shared service inside a tool's `RegisterServices()`.

### Async & Concurrency
- Always prefer `Task.Delay` over `Thread.Sleep`. Use `CancellationToken` when applicable.
- Multi-user logic must use `LockService` to prevent concurrent write collisions.

### Known Sensitivities
- **SignalR Circuit**: State is lost on refresh unless stored in Scoped service or persisted to disk.
- **Plugin Isolation**: A tool crash must NOT crash the Shell. All tool rendering goes through `<ErrorBoundary>`.
- **Data Root**: Use injected `Platform:DataRoot`, never hardcode `AppContext.BaseDirectory` for data directories.
- **File Locking**: Use `lock` objects or `FileShare.ReadWrite` for log writing (IIS can lock files).
- **Path Encoding**: Use `Encoding.UTF8` for all file I/O (Vietnamese character support).

## 4. Plugin Development

### Tool Structure
- Every tool is a Razor Class Library (RCL) in `src/ToolKit.[Name]/`.
- Every tool MUST implement `IToolPlugin` (preferably via `ToolPluginBase`).
- Tool pages MUST use the tool's `RoutePrefix` (e.g., `/vouchers/...`).
- Tool-specific static assets go in `wwwroot/` (served at `_content/ToolKit.[Name]/`).

### Data Isolation
- Tools write ONLY to `data/{DataDirectory}/`.
- Tools NEVER write to `data/shared/` directly — use shared services.
- Shell creates each tool's data directory on startup.

### Contract Safety
- Adding a member to `IToolPlugin` is a **BREAKING CHANGE** — all tools must be updated simultaneously.
- Always add defaults in `ToolPluginBase` first for backward compatibility.
- Removing or renaming contract members requires explicit user approval.

### Route Collision & Permissions
- Check all existing tool prefixes in `ToolRegistry` before assigning a `RoutePrefix`.
- New tools default to `RequiredRoles = ["admin"]` until configured in `permissions.json`.
- Tools MUST NOT bypass `PermissionService`.

## 5. Security Guardrails

<strict-constraints>
- SMTP credentials must NEVER be persisted to disk.
- Shell never contains business logic. Tools never modify Shell layout or Shared contracts without approval.
- Layer boundary must be identified (Shell / Shared / Tool RCL) before any implementation.
</strict-constraints>
