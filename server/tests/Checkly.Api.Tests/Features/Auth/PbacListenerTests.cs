using System.Diagnostics;
using Checkly.Api.Common.Auth;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Logging.Abstractions;

namespace Checkly.Api.Tests.Features.Auth;

// @[/atdd] SDET Generated Test Suite for PBAC Slice 3
[Collection("ApiCollection")]
public class PbacListenerTests(TestWebApplicationFactory fixture) : IClassFixture<TestWebApplicationFactory>, IAsyncLifetime
{
    private readonly IServiceProvider _sp = fixture.Services;
    
    public async Task InitializeAsync() 
    {
        fixture.EnsureDatabaseCreated();

        // Ensure DB is ready and seeded
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        // Seed initial data if necessary to avoid DbUpdateExceptions later
        if (!await db.RoleCapabilities.AnyAsync(r => r.Capability == "test:seeded"))
        {
            db.RoleCapabilities.Add(new RoleCapability { Id = Guid.NewGuid(), Role = "auditor", Capability = "test:seeded", CreatedAt = DateTime.UtcNow });
            await db.SaveChangesAsync();
        }
    }
    
    public Task DisposeAsync() => Task.CompletedTask;

    [Fact]
    public async Task GetCapabilities_DuringSwap_NeverSeesPartialState()
    {
        // Arrange
        // We will manually instantiate the cache and populate it.
        var cache = new PbacDictionaryCache();
        await cache.InitializeAsync(_sp);

        Exception? threadException = null;
        var readerBlocker = new ManualResetEventSlim(false);

        // Act
        // Spawn 50 reader threads constantly querying the cache
        var readerTasks = Enumerable.Range(0, 50).Select(_ => Task.Run(() =>
        {
            readerBlocker.Wait(); // wait for start signal
            for (int i = 0; i < 1000; i++)
            {
                try
                {
                    var caps = cache.GetCapabilities("auditor");
                    Assert.NotNull(caps);
                }
                catch (Exception ex)
                {
                    threadException = ex;
                    throw; // Will fail the test
                }
            }
        })).ToArray();

        // Spawn 1 writer thread constantly calling InitializeAsync
        var writerTask = Task.Run(async () =>
        {
            readerBlocker.Wait();
            for (int i = 0; i < 50; i++)
            {
                await cache.InitializeAsync(_sp);
            }
        });

        // Fire the gun
        readerBlocker.Set();

        await Task.WhenAll(readerTasks.Append(writerTask));

        // Assert
        Assert.Null(threadException);
    }

    [Fact]
    public async Task CacheReloads_OnNotification_WithAtomicSwap()
    {
        // Arrange
        using var scope = _sp.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var config = scope.ServiceProvider.GetRequiredService<IConfiguration>();

        var cache = new PbacDictionaryCache();
        await cache.InitializeAsync(_sp);
        
        var listener = new PbacCacheListenerService(cache, config, new NullLogger<PbacCacheListenerService>(), _sp);
        var cts = new CancellationTokenSource();
        
        // Act
        var listenerTask = listener.StartAsync(cts.Token);
        
        // Add a new capability into DB
        db.RoleCapabilities.Add(new RoleCapability { Id = Guid.NewGuid(), Role = "auditor", Capability = "test:notify", CreatedAt = DateTime.UtcNow });
        await db.SaveChangesAsync(); // This should trigger the NOTIFY
        
        // Wait for propagation
        await Task.Delay(1000);
        
        await cts.CancelAsync();
        await listener.StopAsync(CancellationToken.None);

        // Assert
        var caps = cache.GetCapabilities("auditor");
        Assert.Contains("test:notify", caps);
    }
}
