# Implementation Plan: Deepen Audit Logger (Domain Events)

## Objective
Replace the shallow, tightly-coupled `AuditLogger.Log` static wrapper with a decoupled Domain Event architecture using MediatR.

## Architectural Changes (The Seam & Adapter)
1. **The Seam (Interface)**: `IAuditableEvent` — A marker interface inheriting from `MediatR.INotification` that enforces a standard contract for any event that should hit the audit log.
2. **The Adapter (Implementation)**: `AuditEventHandler` — A single generic MediatR notification handler (`INotificationHandler<IAuditableEvent>`) that intercepts these events, extracts the `IHttpContextAccessor` details (TraceId, UserId), and saves the `SystemLog` to the database.

## Migration Strategy
To minimize the blast radius, we will not rewrite the entire system in one go.
1. Build the new Seam and Adapter.
2. Mark the old `AuditLogger.cs` as `[Obsolete]`.
3. Migrate ONE vertical slice (`CreateProgram.cs`) to prove the pattern. Future slices will adopt the pattern naturally.

## Required File Modifications

### 1. `server/Common/Audit/IAuditableEvent.cs` [NEW]
```csharp
using MediatR;

namespace Checkly.Api.Common.Audit;

public interface IAuditableEvent : INotification
{
    Guid EntityId { get; }
    string EntityType { get; }
    string Action { get; }
    string? Message { get; }
}
```

### 2. `server/Common/Audit/AuditEventHandler.cs` [NEW]
```csharp
using System.Security.Claims;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using MediatR;
using Microsoft.AspNetCore.Http;

namespace Checkly.Api.Common.Audit;

public class AuditEventHandler(AppDbContext db, IHttpContextAccessor httpContextAccessor) 
    : INotificationHandler<IAuditableEvent>
{
    public Task Handle(IAuditableEvent notification, CancellationToken cancellationToken)
    {
        var user = httpContextAccessor.HttpContext?.User;
        _ = Guid.TryParse(user?.FindFirstValue(ClaimTypes.NameIdentifier), out var uid);

        db.SystemLogs.Add(new SystemLog
        {
            Id = Guid.NewGuid(),
            UserId = uid == Guid.Empty ? null : uid,
            Action = notification.Action,
            Category = "audit",
            EntityType = notification.EntityType,
            EntityId = notification.EntityId,
            Message = notification.Message,
            Path = httpContextAccessor.HttpContext?.Request.Path.Value,
            TraceId = httpContextAccessor.HttpContext?.TraceIdentifier,
            UserEmail = user?.FindFirstValue(ClaimTypes.Email),
            Level = "info",
            CreatedAt = DateTimeOffset.UtcNow
        });

        // We do NOT call SaveChangesAsync here. 
        // The event is published within the caller's transaction scope.
        return Task.CompletedTask;
    }
}
```

### 3. `server/Features/Programs/Events/ProgramCreatedEvent.cs` [NEW]
```csharp
using Checkly.Api.Common.Audit;

namespace Checkly.Api.Features.Programs.Events;

public record ProgramCreatedEvent(Guid ProgramId, string? Message = null) : IAuditableEvent
{
    public Guid EntityId => ProgramId;
    public string EntityType => "Program";
    public string Action => "program_created";
}
```

### 4. `server/Features/Programs/CreateProgram.cs` [MODIFIED]
- **Change**: Inject `IMediator mediator`.
- **Change**: Remove the call to `AuditLogger.Log(...)`.
- **Change**: Before `await db.SaveChangesAsync(ct);`, add:
  ```csharp
  await mediator.Publish(new ProgramCreatedEvent(program.Id, $"Program '{program.Title}' created with {assignments.Count} store assignment(s)."), ct);
  ```

### 5. `server/Common/Services/AuditLogger.cs` [MODIFIED]
- **Change**: Add `[Obsolete("Use IAuditableEvent and MediatR instead to decouple auditing from business logic.")]` to the class.

## Proposed Changes
- Create `server/Common/Audit/IAuditableEvent.cs` (Marker Interface)
- Create `server/Common/Audit/AuditEventHandler.cs` (MediatR Adapter)
- Create `server/Features/Programs/Events/ProgramCreatedEvent.cs` (Concrete Event)
- Modify `server/Features/Programs/CreateProgram.cs` to publish the event.
- Modify `server/Common/Services/AuditLogger.cs` to add `[Obsolete]`.

## Risk Assessment
- **Severity**: Low. We are maintaining the exact same schema and DbContext behavior. The MediatR event is fired inline, so it naturally participates in the EF Core transaction that is saved on the subsequent `await db.SaveChangesAsync(ct)` call.
- **Blast Radius**: Isolated. `CreateProgram.cs` is the only modified caller. All other callers continue to use the `[Obsolete]` static class until they are naturally migrated.

## Verification Plan
1. Recompile the server to ensure MediatR `INotification` types are resolved.
2. Run `rtk dotnet test server/tests --filter Program_Slice1_Tests` (or the generic test suite) to prove that `CreateProgram.cs` still successfully creates programs and does not throw DI or MediatR exceptions.
