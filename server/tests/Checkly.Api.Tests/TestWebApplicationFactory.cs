using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc.Testing;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// Custom WebApplicationFactory using a dedicated local PostgreSQL database (checkly_test).
/// EnsureDeleted() is used here to reset the DB state before tests.
/// </summary>
public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    private static bool _dbInitialized;
    private static readonly System.Threading.Lock _lock = new();

    public TestWebApplicationFactory()
    {
    }

    protected override void ConfigureWebHost(IWebHostBuilder builder)
    {
        builder.UseEnvironment("Development");

        // Suppress Serilog re-initialisation. Program.cs runs CreateBootstrapLogger() at the
        // top level on every WebApplicationFactory build. When the static Log.Logger is already
        // frozen from a previous factory instance, a second call throws InvalidOperationException.
        // Clearing the logging providers here prevents any Serilog sink from being re-wired and
        // routes all test logging to /dev/null.
        builder.ConfigureLogging(logging =>
        {
            // logging.ClearProviders(); // We need to see the DbUpdateException
            logging.AddConsole();
        });

        // Ensure IConfiguration["ConnectionStrings:DefaultConnection"] matches the test DB
        // so background listeners connect to the right database.
        var testConnectionString = "Host=127.0.0.1;Port=5432;Database=checkly_test;Username=postgres;Password=Aa1234567@";
        builder.ConfigureAppConfiguration((context, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = testConnectionString
            });
        });

        builder.ConfigureServices(services =>
        {
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
            if (descriptor is not null)
                services.Remove(descriptor);

            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(testConnectionString)
                       .ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning)));
        });
    }

    public void EnsureDatabaseCreated()
    {
        lock (_lock)
        {
            if (!_dbInitialized)
            {
                using var scopeInit = Services.CreateScope();
                var dbInit = scopeInit.ServiceProvider.GetRequiredService<AppDbContext>();

                // SAFETY GUARD: Prevent tests from ever touching the main/production database.
                var connString = dbInit.Database.GetConnectionString() ?? "";
                if (!connString.Contains("_test", StringComparison.OrdinalIgnoreCase))
                {
                    throw new InvalidOperationException($"SAFETY ABORT: Test factory is connected to '{connString}'. Tests must ONLY run against a dedicated '_test' database to prevent accidental data wipes.");
                }

                // The database is migrated automatically by Program.cs during app startup.
                // We rely on tests creating unique entities (Guid.NewGuid) to avoid conflicts.

                // Seed a bootstrap admin so tests can create admin users via the API
                var userManagerInit = scopeInit.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
                var existingAdmin = userManagerInit.FindByEmailAsync("bootstrap@admin.test").GetAwaiter().GetResult();
                if (existingAdmin == null)
                {
                    var adminUserInit = new AppUser
                    {
                        Id = Guid.NewGuid(),
                        UserName = "bootstrap@admin.test",
                        Email = "bootstrap@admin.test"
                    };
                    userManagerInit.CreateAsync(adminUserInit, "Bootstrap123!@").GetAwaiter().GetResult();
                    dbInit.Profiles.Add(new Profile
                    {
                        Id = adminUserInit.Id,
                        FullName = "Bootstrap Admin",
                        Email = "bootstrap@admin.test",
                        CreatedAt = DateTimeOffset.UtcNow,
                        UpdatedAt = DateTimeOffset.UtcNow
                    });
                    dbInit.AppUserRoles.Add(new UserRole
                    {
                        Id = Guid.NewGuid(),
                        UserId = adminUserInit.Id,
                        Role = "admin",
                        CreatedAt = DateTimeOffset.UtcNow
                    });
                    dbInit.SaveChanges();
                }
                _dbInitialized = true;
            }

            // CRITICAL: Reload PBAC cache for THIS factory instance.
            // Even if the DB was initialized by another factory, this factory's Singleton cache
            // must be hydrated from the DB, otherwise the Fail-Closed security gate blocks all requests.
            using var scopeCache = Services.CreateScope();
            var pbacCache = scopeCache.ServiceProvider.GetRequiredService<PbacDictionaryCache>();

            // Seed PBAC capabilities that Program.cs seeds on startup.
            // EnsureDeleted() wipes those rows, so we must re-seed them here.
            var dbCache = scopeCache.ServiceProvider.GetRequiredService<AppDbContext>();
            dbCache.Database.ExecuteSqlRaw("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES (gen_random_uuid(), 'admin',         'global_risks:manage',        now()),
                       (gen_random_uuid(), 'admin',         'programs:create',             now()),
                       (gen_random_uuid(), 'admin',         'programs:list',               now()),
                       (gen_random_uuid(), 'admin',         'programs:assignments_list',   now()),
                       (gen_random_uuid(), 'area_manager',  'programs:assignments_list',   now()),
                       (gen_random_uuid(), 'admin',         'programs:review',             now()),
                       (gen_random_uuid(), 'admin',         'programs:manage',             now()),
                       (gen_random_uuid(), 'store_manager', 'programs:assignments_my',     now()),
                       (gen_random_uuid(), 'store_manager', 'programs:execute',            now()),
                       (gen_random_uuid(), 'area_manager',  'programs:assignments_my',     now()),
                       (gen_random_uuid(), 'area_manager',  'programs:execute',            now()),
                       (gen_random_uuid(), 'store_manager', 'action_plans:write',          now()),
                       (gen_random_uuid(), 'admin',         'action_plans:write',          now()),
                       (gen_random_uuid(), 'auditor',       'action_plans:verify',         now()),
                       (gen_random_uuid(), 'area_manager',  'action_plans:verify',         now()),
                       (gen_random_uuid(), 'admin',         'action_plans:verify',         now()),
                       (gen_random_uuid(), 'admin',         'analytics:bod',               now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);

            pbacCache.InitializeAsync(scopeCache.ServiceProvider).GetAwaiter().GetResult();
        }
    }

    /// <summary>
    /// Returns a valid admin JWT by logging in as the seeded bootstrap admin.
    /// Includes a retry loop to bypass 429 rate limits during parallel test execution.
    /// </summary>
    public async Task<string> LoginBootstrapAdminAsync(HttpClient client)
    {
        for (int i = 0; i < 5; i++)
        {
            var response = await client.PostAsJsonAsync("/api/auth/login", new
            {
                email = "bootstrap@admin.test",
                password = "Bootstrap123!@"
            });

            if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            {
                await Task.Delay(200 * (int)Math.Pow(2, i));
                continue;
            }

            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            return json.GetProperty("token").GetString()!;
        }
        throw new Exception("Rate limit exceeded for LoginBootstrapAdminAsync after retries.");
    }

    public async Task<(string Token, Guid UserId)> RegisterUserAsync(
        HttpClient client, string email, string password, string fullName, string role,
        string? adminToken = null)
    {
        // Automatically make emails unique to avoid parallel test suite conflicts
        if (email.Contains('@'))
        {
            var parts = email.Split('@');
            email = $"{parts[0]}-{Guid.NewGuid():N}@{parts[1]}";
        }
        // Auto-elevate: non-auditor roles require an admin JWT per CRIT-01 in Register.cs
        if (adminToken is null && role != "auditor")
            adminToken = await LoginBootstrapAdminAsync(client);

        for (int i = 0; i < 5; i++)
        {
            var request = new HttpRequestMessage(HttpMethod.Post, "/api/auth/register")
            {
                Content = JsonContent.Create(new { email, password, fullName, role })
            };

            if (adminToken is not null)
                request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

            var response = await client.SendAsync(request);

            if (response.StatusCode == System.Net.HttpStatusCode.TooManyRequests)
            {
                await Task.Delay(200 * (int)Math.Pow(2, i));
                continue;
            }

            if (!response.IsSuccessStatusCode)
            {
                var errorBody = await response.Content.ReadAsStringAsync();
                throw new Exception($"Registration failed ({response.StatusCode}): {errorBody}");
            }

            var json = await response.Content.ReadFromJsonAsync<JsonElement>();
            return (json.GetProperty("token").GetString()!, Guid.Parse(json.GetProperty("userId").GetString()!));
        }
        throw new Exception("Rate limit exceeded for RegisterUserAsync after retries.");
    }

    public HttpClient CreateAuthenticatedClient(string token)
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}
