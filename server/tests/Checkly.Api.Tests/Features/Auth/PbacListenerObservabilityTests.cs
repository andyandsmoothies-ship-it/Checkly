using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging;

namespace Checkly.Api.Tests.Features.Auth;

public class TestLogger<T> : ILogger<T>
{
    public List<(LogLevel Level, string Message, Exception? Exception)> Logs { get; } = new();

    public IDisposable? BeginScope<TState>(TState state) where TState : notnull => null;

    public bool IsEnabled(LogLevel logLevel) => true;

    public void Log<TState>(LogLevel logLevel, EventId eventId, TState state, Exception? exception, Func<TState, Exception?, string> formatter)
    {
        Logs.Add((logLevel, formatter(state, exception), exception));
    }
}

[Collection("ApiCollection")]
public class PbacListenerObservabilityTests(TestWebApplicationFactory fixture) : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private IServiceProvider _sp = null!;

    public async Task InitializeAsync()
    {
        _sp = fixture.Services;
        fixture.EnsureDatabaseCreated();
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.ExecuteSqlRawAsync("SELECT 1;"); // Ensure DB is warmed up
    }

    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public void T01_PbacDictionaryCache_HasIsRebuilding_Property()
    {
        // Arrange
        var cacheType = typeof(PbacDictionaryCache);

        // Act
        var prop = cacheType.GetProperty("IsRebuilding");

        // Assert
        Assert.NotNull(prop); // Red state expects this to fail
        Assert.Equal(typeof(bool), prop.PropertyType);
    }

    [Fact]
    public async Task T02_CacheListener_SetsIsRebuilding_DuringDebounceWindow()
    {
        // Arrange
        var cache = new PbacDictionaryCache();
        var config = _sp.GetRequiredService<IConfiguration>();
        var logger = new TestLogger<PbacCacheListenerService>();
        var listener = new PbacCacheListenerService(cache, config, logger, _sp);
        var cts = new CancellationTokenSource();

        // Act
        var listenerTask = listener.StartAsync(cts.Token);
        await Task.Delay(1000); // Give it time to connect and issue LISTEN

        // Trigger a NOTIFY
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        await db.Database.ExecuteSqlRawAsync("NOTIFY pbac_invalidate;");

        // Wait briefly to allow the channel consumer to wake up, set IsRebuilding = true, 
        // and enter the Task.Delay(DebounceWindowMs)
        await Task.Delay(200);

        // At this specific moment, IsRebuilding should be true.
        var isRebuildingProp = typeof(PbacDictionaryCache).GetProperty("IsRebuilding");
        Assert.NotNull(isRebuildingProp); // Ensures T-01 is respected
        var isRebuildingValue = (bool)isRebuildingProp.GetValue(cache)!;

        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        Assert.True(isRebuildingValue, "IsRebuilding was not set to true during the debounce window.");
    }

    [Fact]
    public async Task T03_CacheListener_EscalatesToErrorLog_After3ConsecutiveFailures()
    {
        // Arrange
        var cache = new PbacDictionaryCache();

        // Port 1 usually refuses connection instantly. Timeout=1 ensures strict bounding.
        var badConfig = new ConfigurationBuilder().AddInMemoryCollection(new Dictionary<string, string?>
        {
            { "ConnectionStrings:DefaultConnection", "Host=localhost;Port=1;Database=bad;Username=bad;Password=bad;Timeout=1;Max Auto Retries=0" }
        }).Build();

        var logger = new TestLogger<PbacCacheListenerService>();
        var listener = new PbacCacheListenerService(cache, badConfig, logger, _sp);
        var cts = new CancellationTokenSource();

        // Act
        var listenerTask = listener.StartAsync(cts.Token);

        // Wait for connection to fail at least 3 times.
        // Attempt 1 fails instantly -> wait 1s -> Attempt 2 fails -> wait 2s -> Attempt 3 fails -> wait 4s
        await Task.Delay(4000);

        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        var failureLogs = logger.Logs.Where(l => l.Message.Contains("connection failed")).ToList();
        Assert.True(failureLogs.Count >= 3, $"Expected at least 3 failures, got {failureLogs.Count}.");

        // First and second failures should be Warning
        Assert.Equal(LogLevel.Warning, failureLogs[0].Level);
        Assert.Equal(LogLevel.Warning, failureLogs[1].Level);

        // Third failure MUST escalate to Error (currently Warning in implementation)
        Assert.Equal(LogLevel.Error, failureLogs[2].Level);
    }
}
