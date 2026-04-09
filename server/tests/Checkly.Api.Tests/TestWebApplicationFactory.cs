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

namespace Checkly.Api.Tests;

/// <summary>
/// Custom WebApplicationFactory using a separate PostgreSQL test database.
/// DB is created once per test run, not per class.
/// </summary>
public class TestWebApplicationFactory : WebApplicationFactory<Program>
{
    private const string TestConnectionString =
        "Host=localhost;Database=checkly_test;Username=postgres;Password=Aa1234567@";

    private static bool _dbInitialized;
    private static readonly object _lock = new();

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
        builder.ConfigureAppConfiguration((context, config) =>
        {
            config.AddInMemoryCollection(new Dictionary<string, string?>
            {
                ["ConnectionStrings:DefaultConnection"] = TestConnectionString
            });
        });

        builder.ConfigureServices(services =>
        {
            var descriptor = services.SingleOrDefault(
                d => d.ServiceType == typeof(DbContextOptions<AppDbContext>));
            if (descriptor is not null)
                services.Remove(descriptor);

            services.AddDbContext<AppDbContext>(options =>
                options.UseNpgsql(TestConnectionString));
        });
    }

    public void EnsureDatabaseCreated()
    {
        lock (_lock)
        {
            if (_dbInitialized) return;

            using var scope = Services.CreateScope();
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            db.Database.EnsureDeleted();
            db.Database.Migrate();

            // Seed a bootstrap admin so tests can create admin users via the API
            var userManager = scope.ServiceProvider.GetRequiredService<UserManager<AppUser>>();
            var adminUser = new AppUser
            {
                Id = Guid.NewGuid(),
                UserName = "bootstrap@admin.test",
                Email = "bootstrap@admin.test"
            };
            userManager.CreateAsync(adminUser, "Bootstrap123!@").GetAwaiter().GetResult();
            db.Profiles.Add(new Profile
            {
                Id = adminUser.Id,
                FullName = "Bootstrap Admin",
                Email = "bootstrap@admin.test",
                CreatedAt = DateTimeOffset.UtcNow,
                UpdatedAt = DateTimeOffset.UtcNow
            });
            db.AppUserRoles.Add(new UserRole
            {
                Id = Guid.NewGuid(),
                UserId = adminUser.Id,
                Role = "admin",
                CreatedAt = DateTimeOffset.UtcNow
            });
            db.SaveChanges();

            // CRITICAL: Reload PBAC cache after EnsureDeleted + Migrate wipes the test DB.
            // The app's PbacDictionaryCache was populated at startup from the old DB state.
            // After Migrate() re-seeds role_capabilities (including admin:manage_roles),
            // the cache must be refreshed or all PBAC-gated endpoints will 403.
            var pbacCache = scope.ServiceProvider.GetRequiredService<PbacDictionaryCache>();
            pbacCache.InitializeAsync(scope.ServiceProvider).GetAwaiter().GetResult();

            _dbInitialized = true;
        }
    }

    /// <summary>
    /// Returns a valid admin JWT by logging in as the seeded bootstrap admin.
    /// </summary>
    public async Task<string> LoginBootstrapAdminAsync(HttpClient client)
    {
        var response = await client.PostAsJsonAsync("/api/auth/login", new
        {
            email = "bootstrap@admin.test",
            password = "Bootstrap123!@"
        });
        response.EnsureSuccessStatusCode();
        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return json.GetProperty("token").GetString()!;
    }

    public async Task<(string Token, Guid UserId)> RegisterUserAsync(
        HttpClient client, string email, string password, string fullName, string role,
        string? adminToken = null)
    {
        var request = new HttpRequestMessage(HttpMethod.Post, "/api/auth/register")
        {
            Content = JsonContent.Create(new { email, password, fullName, role })
        };

        if (adminToken is not null)
            request.Headers.Authorization = new AuthenticationHeaderValue("Bearer", adminToken);

        var response = await client.SendAsync(request);

        if (!response.IsSuccessStatusCode)
        {
            var errorBody = await response.Content.ReadAsStringAsync();
            throw new Exception($"Registration failed ({response.StatusCode}): {errorBody}");
        }

        var json = await response.Content.ReadFromJsonAsync<JsonElement>();
        return (json.GetProperty("token").GetString()!, Guid.Parse(json.GetProperty("userId").GetString()!));
    }

    public HttpClient CreateAuthenticatedClient(string token)
    {
        var client = CreateClient();
        client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}
