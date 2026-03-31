---
name: dotnet-pgvector-search
description: >
  Implementing vector search, RAG, and semantic similarity using PostgreSQL (pgvector) and Microsoft.Extensions.AI in .NET 10.
  Make sure to load and use this skill whenever the user asks to implement semantic search, similarity matching, RAG pipelines, 
  generate embeddings (Ollama, OpenAI), or explicitly mentions pgvector, HNSW indexes, or Microsoft.Extensions.AI in C#.
---

# Vector Search with pgvector in .NET

> [!NOTE]
> **Architectural Context:** Do not jump to deploying dedicated vector databases (Pinecone, Qdrant) if the system already uses PostgreSQL. The `pgvector` extension gives you highly scalable similarity search right next to your relational data using the exact same connection pool.

## Core Strategy
Traditional searches (like `LIKE %keyword%`) find exact matches. Vector search finds **semantic meaning**. 
1. `Microsoft.Extensions.AI` converts text into an array of floats (vector embedding).
2. These vectors are saved into a PostgreSQL `vector(dim)` column.
3. Queries convert the search term into a vector and use PostgreSQL's Cosine Distance operator (`<=>`) to find the nearest matches.

## Implementation Details

### 1. Npgsql & Dapper Configuration
To enable pgvector in Dapper, you need `Aspire.Npgsql`, `Pgvector.Dapper`, and `Microsoft.Extensions.AI` abstractions.

```csharp
// Program.cs
// Example using Ollama local embeddings, but works identically for OpenAI
builder.AddOllamaApiClient("ollama-qwen3-embedding")
       .AddEmbeddingGenerator(); 

builder.AddNpgsqlDataSource("articles", configureDataSourceBuilder: b => 
{
    // Must explicitly tell Npgsql to map the vector type
    b.UseVector(); 
});

// Register the type handler for Dapper universally
SqlMapper.AddTypeHandler(new VectorTypeHandler());
```

### 2. Database Initialization & Indexing
You must enable the extension and build the Highly Navigable Small World (HNSW) index, otherwise searches will do a deadly sequential scan.

```csharp
await using var conn = await dataSource.OpenConnectionAsync();

// 1. Enable extension
await conn.ExecuteAsync("CREATE EXTENSION IF NOT EXISTS vector");

// 2. Critical: Reload Npgsql's type cache so it knows 'vector' exists for this connection
conn.ReloadTypes(); 

// 3. Create table
await conn.ExecuteAsync("""
    CREATE TABLE IF NOT EXISTS articles (
        id SERIAL PRIMARY KEY,
        url TEXT NOT NULL,
        title TEXT NOT NULL,
        embedding vector(1024) NOT NULL
    )
""");

// 4. Create HNSW Index (Fast Approximate Nearest-Neighbor)
await conn.ExecuteAsync("""
    CREATE INDEX IF NOT EXISTS articles_embedding_idx 
    ON articles USING hnsw (embedding vector_cosine_ops)
""");
```

### 3. Generating and Storing Embeddings
```csharp
var embeddingResponse = await embeddingGenerator.GenerateAsync(content);
// Extract the float array and wrap it in the Dapper Vector type
var vector = new Vector(embeddingResponse.Vector.ToArray());

await conn.ExecuteAsync(
    "INSERT INTO articles (url, title, embedding) VALUES (@Url, @Title, @Embedding)",
    new { Url = articleUrl, Title = title, Embedding = vector });
```

### 4. Semantic Search (Cosine Distance)
We embed the user's search query, and query PostgreSQL using the `<=>` (Cosine Distance) operator. Lower values are more similar.

```csharp
var searchEmbedding = await embeddingGenerator.GenerateAsync(query);
var queryVector = new Vector(searchEmbedding.Vector.ToArray());

var results = await conn.QueryAsync<SearchResult>("""
    SELECT title, url, embedding <=> @QueryVector as distance 
    FROM articles 
    ORDER BY embedding <=> @QueryVector 
    LIMIT @Limit
    """, new { QueryVector = queryVector, Limit = 5 });
```

## Gotchas & Edge Cases (CRITICAL)

* **Dimension Mismatches Hard-Crash:** The dimension size of your PostgreSQL column (`vector(1024)`) MUST exactly match the output dimensions of your embedding model. (e.g., `qwen3` = 1024, `text-embedding-ada-002` = 1536, `text-embedding-3-large` = 3072). If you change the model later, the data cannot be inserted into the old column.
* **Query/Storage Model Parity:** You CANNOT mix models. The user's search query MUST be embedded with the exact same model used to generate the embeddings in the database, otherwise the vector space comparison is meaningless and returns garbage.
* **The ReloadTypes() Failure:** After sending `CREATE EXTENSION IF NOT EXISTS vector`, you MUST immediately call `conn.ReloadTypes()` on the exact same connection instance. If you skip this, Npgsql will throw a mapping exception because it doesn't recognize the `vector` type.
* **Missing Index (Sequential Scan):** If you forget the `USING hnsw (embedding vector_cosine_ops)` index, pgvector will work perfectly in development but will execute a brutal full-table Sequential Scan in production, destroying database CPU.
