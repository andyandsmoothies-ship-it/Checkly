# 1. Create console project
dotnet new console -n DataDump --force

# 2. Add dependencies
cd DataDump
dotnet add package Microsoft.EntityFrameworkCore.Design
dotnet add package Npgsql.EntityFrameworkCore.PostgreSQL
dotnet add package Microsoft.Extensions.Configuration.Json
dotnet add package Microsoft.Extensions.DependencyInjection
dotnet add reference ../server.csproj

# 3. Overwrite Program.cs
$program = @"
using System;
using System.Linq;
using System.IO;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Configuration;

// Assuming the namespace of your DbContext
using Checkly.Common.Persistence;

var builder = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: true)
    .AddJsonFile("../appsettings.Development.json", optional: true);

var configuration = builder.Build();
var connectionString = configuration.GetConnectionString("DefaultConnection");

if (string.IsNullOrEmpty(connectionString))
{
    // Fallback if appsettings aren't found relative to CWD
    connectionString = \"Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@\";
}

var services = new ServiceCollection();
services.AddDbContext<AppDbContext>(options =>
    options.UseNpgsql(connectionString));

using var serviceProvider = services.BuildServiceProvider();
using var scope = serviceProvider.CreateScope();
var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

var templates = await db.Templates
    .Include(t => t.Groups)
    .AsNoTracking()
    .ToListAsync();

foreach (var t in templates)
{
    Console.WriteLine(\"TITLE: \" + t.Title);
    Console.WriteLine(\"DESC: \" + t.Description);
    Console.WriteLine(\"CONFIG: \" + t.ScoringLogicConfig);
    Console.WriteLine(\"===\");
}
"@

$program | Out-File -FilePath Program.cs -Encoding utf8

# 4. Run it
dotnet run
