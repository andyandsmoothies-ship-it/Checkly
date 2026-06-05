using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;

namespace Checkly.Api.Tests.Features.Auth;

public class TrackingServiceProvider : IServiceProvider
{
    private readonly IServiceProvider _inner;
    public int DbContextResolutions { get; set; }

    public TrackingServiceProvider(IServiceProvider inner) => _inner = inner;

    public object? GetService(Type serviceType)
    {
        if (serviceType == typeof(IServiceScopeFactory))
            return new TrackingServiceScopeFactory(_inner.GetRequiredService<IServiceScopeFactory>(), this);

        if (serviceType == typeof(AppDbContext))
            DbContextResolutions++;

        return _inner.GetService(serviceType);
    }
}

public class TrackingServiceScopeFactory : IServiceScopeFactory
{
    private readonly IServiceScopeFactory _inner;
    private readonly TrackingServiceProvider _tracker;

    public TrackingServiceScopeFactory(IServiceScopeFactory inner, TrackingServiceProvider tracker)
    {
        _inner = inner;
        _tracker = tracker;
    }

    public IServiceScope CreateScope()
    {
        return new TrackingServiceScope(_inner.CreateScope(), _tracker);
    }
}

public class TrackingServiceScope : IServiceScope, IServiceProvider
{
    private readonly IServiceScope _innerScope;
    private readonly TrackingServiceProvider _tracker;

    public TrackingServiceScope(IServiceScope innerScope, TrackingServiceProvider tracker)
    {
        _innerScope = innerScope;
        _tracker = tracker;
    }

    public IServiceProvider ServiceProvider => this;

    public object? GetService(Type serviceType)
    {
        if (serviceType == typeof(AppDbContext))
            _tracker.DbContextResolutions++;

        return _innerScope.ServiceProvider.GetService(serviceType);
    }

    public void Dispose() => _innerScope.Dispose();
}

[Collection("Sequential")]
public class PbacCacheListenerServiceTests(TestWebApplicationFactory fixture) : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
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
    public async Task CacheReloads_OnConnect_Immediately_BeforeNotify()
    {
        // Arrange
        var tracker = new TrackingServiceProvider(_sp);
        var cache = new PbacDictionaryCache();
        var config = _sp.GetRequiredService<IConfiguration>();
        var listener = new PbacCacheListenerService(cache, config, new NullLogger<PbacCacheListenerService>(), tracker);
        var cts = new CancellationTokenSource();

        // Act
        Assert.False(cache.IsReady, "Pre-condition: Cache should not be ready initially.");

        var listenerTask = listener.StartAsync(cts.Token);

        // Give the service 1 second to connect and theoretically call InitializeAsync
        await Task.Delay(1000);

        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        Assert.True(cache.IsReady, "Cache should be ready immediately after connection (Resync-on-Connect implementation missing).");
        Assert.Equal(1, tracker.DbContextResolutions);
    }

    [Fact]
    public async Task CacheReloads_DebouncesMultipleNotifyEvents_IntoSingleRefresh()
    {
        // Arrange
        var tracker = new TrackingServiceProvider(_sp);
        var cache = new PbacDictionaryCache();
        var config = _sp.GetRequiredService<IConfiguration>();
        var listener = new PbacCacheListenerService(cache, config, new NullLogger<PbacCacheListenerService>(), tracker);
        var cts = new CancellationTokenSource();

        // Act
        var listenerTask = listener.StartAsync(cts.Token);

        // Wait for connection to establish so it is waiting on WaitAsync
        await Task.Delay(1000);

        // Reset tracker count so we only count post-connect Initializations!
        // Right now the service DOES NOT initialize on connect, but once fixed, this will be 1 here.
        // We set to 0 to specifically measure the burst response behavior!
        tracker.DbContextResolutions = 0;

        // Burst 50 Postgres NOTIFYs
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        for (int i = 0; i < 50; i++)
        {
            await db.Database.ExecuteSqlRawAsync("NOTIFY pbac_invalidate;");
        }

        // Wait for debounce window (assume around 1000ms max in future config) plus safety margin
        await Task.Delay(2000);

        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        // Expect exactly ONE invocation of InitializeAsync after 50 NOTIFYs
        Assert.Equal(1, tracker.DbContextResolutions);
    }

    [Fact]
    [Trait("Category", "Pbac")]
    public async Task Consumer_RemainsAlive_AfterProcessingNotify_CanProcessSubsequentSignal()
    {
        // Arrange
        var tracker = new TrackingServiceProvider(_sp);
        var cache = new PbacDictionaryCache();
        var config = _sp.GetRequiredService<IConfiguration>();
        var listener = new PbacCacheListenerService(cache, config, new NullLogger<PbacCacheListenerService>(), tracker);
        var cts = new CancellationTokenSource();

        var listenerTask = listener.StartAsync(cts.Token);

        // Act
        // Phase 1 (Resync-on-Connect):
        await Task.Delay(1500);
        Assert.True(cache.IsReady, "Resync-on-Connect should initialize cache.");
        Assert.True(tracker.DbContextResolutions >= 1);

        // Phase 2 (NOTIFY cycle):
        tracker.DbContextResolutions = 0;
        using (var scope = _sp.CreateScope())
        {
            var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
            await db.Database.ExecuteSqlRawAsync("NOTIFY pbac_invalidate;");
        }

        await Task.Delay(2000);

        // Phase 3 (Teardown):
        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        Assert.Equal(1, tracker.DbContextResolutions);
        Assert.True(cache.IsReady);
        Assert.False(cache.IsRebuilding);
    }
}
