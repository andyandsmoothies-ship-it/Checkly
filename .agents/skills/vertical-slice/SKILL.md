---
name: vertical-slice
description: >
  Vertical Slice Architecture (VSA) for .NET applications. Enforces separation of concerns per feature without using giant static classes. Mandates Raw Handler Classes (no MediatR) and Result<T> for business logic. Load this skill when adding features to a feature-folder project or discussing vertical slice patterns.
---

# Vertical Slice Architecture (VSA) - AI Optimized

## Core Principles

1. **One File Per Concern, No Giant Files** — Do not put Endpoint, Handler, and Validator inside one giant static class. Split them into tiny files (e.g., `Endpoint.cs`, `Handler.cs`, `Validator.cs`) to keep AI context clean.
2. **Raw Classes Only (No MediatR)** — Do not use MediatR, Wolverine, or hidden event buses for core logic. Use direct class instantiation (e.g., `await handler.Execute(...)`) so the call stack is visible and traceable.
3. **Errors as Data (`Result<T>`)** — Never throw Exceptions for business validation (like "Item out of stock"). Return a `Result<T>` object. Exceptions are only for system crashes.
4. **No Shared Business Logic** — The `Shared/` folder is ONLY for infrastructure (like JSON parsers or Base Classes). Never put business logic or cross-slice coupling in `Shared/`.

## Pattern: Raw Handlers (Recommended Default)

Every feature gets its own folder containing specific files for each concern.

### Folder Structure
```text
src/MyApp.Api/Features/Orders/CreateOrder/
  CreateOrderEndpoint.cs
  CreateOrderHandler.cs
  CreateOrderValidator.cs
  CreateOrderRequest.cs
```

### 1. The Endpoint File (`CreateOrderEndpoint.cs`)
Parses the HTTP request, calls the handler, and translates the `Result<T>` to HTTP status codes. No business logic here.

```csharp
public sealed class CreateOrderEndpoint : IEndpointGroup
{
    public void Map(IEndpointRouteBuilder app)
    {
        app.MapPost("/api/orders", async (CreateOrderRequest request, CreateOrderHandler handler, CancellationToken ct) =>
        {
            var result = await handler.ExecuteAsync(request, ct);
            return result.IsSuccess
                ? TypedResults.Created($"/api/orders/{result.Value.Id}", result.Value)
                : result.ToProblemDetails();
        });
    }
}
```

### 2. The Handler File (`CreateOrderHandler.cs`)
Contains the core logic. Uses standard dependency injection. Returns `Result<T>`.

```csharp
public class CreateOrderHandler(AppDbContext db, TimeProvider clock)
{
    public async Task<Result<OrderResponse>> ExecuteAsync(CreateOrderRequest request, CancellationToken ct)
    {
        var order = Order.Create(request.CustomerId, request.Items, clock.GetUtcNow());
        
        db.Orders.Add(order);
        await db.SaveChangesAsync(ct);

        return Result.Success(new OrderResponse(order.Id));
    }
}
```

## Anti-Patterns

### ❌ Anti-Pattern 1: The Giant Static Class
Do not group all records and handlers into one massive `public static class CreateOrder`. This creates 500+ line files that break AI context limits. Split by concern instead.

### ❌ Anti-Pattern 2: MediatR Magic
Do not use `_mediator.Send(request)`. It breaks the causal link. Use direct Dependency Injection for handlers.

### ❌ Anti-Pattern 3: Cross-Feature Coupling
Do not call a handler from another feature (e.g., do not call `GetProductHandler` inside `CreateOrderHandler`). If a feature needs data, query the database directly. Features must remain fully isolated.
