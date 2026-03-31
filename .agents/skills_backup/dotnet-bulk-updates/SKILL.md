---
name: dotnet-bulk-updates
description: >
  High-performance bulk database update and insert strategies in .NET using Dapper and EF Core against PostgreSQL. 
  Make sure to load and use this skill whenever the user asks to optimize database operations, needs to insert or update thousands of rows, encounters slow EF Core SaveChanges() performance, or specifically mentions bulk updates, batch queries, UNNEST, or binary COPY in C# / .NET.
---

# Optimizing Bulk Database Updates in .NET

> [!NOTE]
> **Performance Context:** Updating 10,000 rows in PostgreSQL can take 2,400ms using naive methods, but only 41ms using `.NET` binary COPY or UNNEST. The bottleneck is almost never the SQL execution—it is the number of database round-trips.

## Core Strategy

When dealing with bulk mutations (thousands of rows) in .NET, reducing multiple database calls to a **single statement** is where all performance gains are realized. 

Avoid writing loops containing `ExecuteAsync` or generating dynamic SQL strings with thousands of parameters (`@Id0, @Id1...`). Instead, leverage PostgreSQL-native array expansion or binary streaming.

## Approaches (From Slowest to Fastest)

### 1. The Anti-Pattern: Naive Dapper (DO NOT USE for bulk)
Iterating through a list and firing one `UPDATE` per row causes one network round-trip per row. This is the slowest possible method.

### 2. EF Core SaveChanges (Sub-optimal for bulk)
While `SaveChanges()` batches SQL statements (default batch size is 42) to cut down round-trips, it still generates 10,000 individual `UPDATE` statements and requires a preliminary `SELECT` to load entities into the Change Tracker.
* **Verdict:** Good for handfuls of rows, terrible for thousands. It is **not** a bulk update tool.

### 3. Dapper with `UNNEST` arrays (Recommended: Fast & Clean)
Passes data as two native PostgreSQL arrays (`Guid[]` and `DateTime[]`). Npgsql natively maps these to PostgreSQL arrays.

```csharp
var ids = updates.Select(u => u.Id).ToArray();
var processedAts = updates.Select(u => u.ProcessedAt).ToArray();

// Single statement, two parameters. Execution plan is cached.
await connection.ExecuteAsync(
    """
    UPDATE orders 
    SET processed_at = v.processed_at, status = 'Processed'
    FROM UNNEST(@Ids, @ProcessedAts) AS v(id, processed_at)
    WHERE orders.id = v.id
    """, 
    new { Ids = ids, ProcessedAts = processedAts }, 
    transaction: transaction);
```
* **Why it's great:** No dynamic SQL. The query text never changes, allowing PostgreSQL to cache the execution plan safely. No PostgreSQL parameter limits are hit (max is 65,535 for standard queries).

### 4. Npgsql Binary COPY (Recommended: Ultimate Scale)
Bypasses the SQL parameter system entirely and streams rows directly in PostgreSQL's binary wire format via `BeginBinaryImportAsync()`.

```csharp
await connection.ExecuteAsync(
    """
    CREATE TEMP TABLE temp_updates (
        id UUID NOT NULL,
        processed_at TIMESTAMPTZ NOT NULL
    ) ON COMMIT DROP
    """, transaction: transaction);

await using (var writer = await connection.BeginBinaryImportAsync(
    "COPY temp_updates (id, processed_at) FROM STDIN (FORMAT BINARY)"))
{
    foreach (var u in updates)
    {
        await writer.StartRowAsync();
        await writer.WriteAsync(u.Id, NpgsqlTypes.NpgsqlDbType.Uuid);
        await writer.WriteAsync(u.ProcessedAt, NpgsqlTypes.NpgsqlDbType.TimestampTz);
    }
    await writer.CompleteAsync();
}

await connection.ExecuteAsync(
    """
    UPDATE orders 
    SET processed_at = t.processed_at, status = 'Processed'
    FROM temp_updates t 
    WHERE orders.id = t.id
    """, transaction: transaction);
```
* **Why it's great:** Scales infinitely. At massive batch sizes (100k+ rows), binary COPY dominates because the payload is binary data without the overhead of forming parameter objects or massive SQL strings.

## Gotchas & Edge Cases

* **PostgreSQL Parameter Limit (65,535):** If you use the derived `VALUES` table approach (e.g. `VALUES (@Id0, @Val0), (@Id1, @Val1)`), you will hard-crash if you exceed 65,535 parameters in a single batch. Use `UNNEST` or Binary `COPY` to avoid this.
* **ExecuteSqlRaw Constraints:** If you choose to run raw SQL via EF Core (`db.Database.ExecuteSqlRawAsync`), remember that it **does not accept** Dapper's `DynamicParameters`. You must pass standard `NpgsqlParameter` objects natively.
* **UNNEST is Dialect-Specific:** `UNNEST` array expansion is highly specific to PostgreSQL. If the application targets SQL Server or MySQL, you must fall back to Table-Valued Parameters (SQL Server) or the derived `VALUES` approach.
* **Mixed Contexts:** You can query entities using EF Core and update them via Dapper within the **same transaction**. You do not have to pick one ORM exclusively for an entire feature slice.
