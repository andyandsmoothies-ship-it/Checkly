# Walkthrough: Resolved Compiler and IDE Warnings across GetCategoryDetail, BodReportWorkerTests, and ProvinceBenchmarkCalculatorTests

Workflow: /implement | Track: A

## 1. Simplified Collection Initialization

In `GetCategoryDetail.cs` (line 56), the code initialized a list using `rawItems.Select(...).ToList()`. We modernized this to a C# 12 collection expression:

```csharp
            entries = [.. rawItems.Select(x => new CategoryStoreEntry(
                x.StoreName,
                x.TotalMaxScore > 0 ? Math.Round(x.TotalScore / x.TotalMaxScore * 100.0m, 1) : 0m,
                x.AuditCount,
                x.FailureCount
            ))];
```

## 2. Removed Synchronous Async in Fake Class

In `BodReportWorkerTests.cs` (line 289), the class `FakeFailingBodReportCalculator` declared an asynchronous override/new method `ComputeDailyReportAsync` but had no `await` operators inside it. We removed the `async` keyword and returned `Task.FromResult(JsonSerializer.Serialize(payload))` to run synchronously without warnings:

```csharp
        public new Task<string> ComputeDailyReportAsync(AppDbContext db, DateOnly date, CancellationToken ct)
        {
            var payload = new { ... };
            return Task.FromResult(JsonSerializer.Serialize(payload));
        }
```

## 3. Fixed Null Literal Conversion

In `ProvinceBenchmarkCalculatorTests.cs` (line 79), the test assigned `Province = null` during test data seeding for a store with a null province. Because `Province` is a required non-nullable string in the `StoreAddress` NRT model configuration, this was flagged by the compiler. We applied the null-forgiving operator `Province = null!` to tell the compiler that passing a null value is intentional for testing:

```csharp
            new Store { Id = storeNull1, Name = "Store Null 1", Address2 = new StoreAddress { Province = null! }, CreatedAt = DateTimeOffset.UtcNow, UpdatedAt = DateTimeOffset.UtcNow },
```

## Verification

We ran a full build and test execution:
- `rtk dotnet build`: 0 errors, 0 warnings
- `rtk dotnet test`: All backend tests passed successfully with 0 warnings.
