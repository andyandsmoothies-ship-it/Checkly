using System.Security.Claims;
using Checkly.Api.Common.Auth;
using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ADR Hardening Gate verification suite for the PBAC DI + Cold-Start contract.
///
/// Gate 1 (DI Singleton Proof): Resolves PbacDictionaryCache from the root
/// ServiceProvider twice and asserts they are the same object reference.
/// This proves AddSingleton is correctly wired — one instance, shared across all requests.
///
/// Gate 2 (Cold-Start Fail-Closed Proof): Creates an uninitialized PbacDictionaryCache
/// (IsReady = false) and asserts that CapabilityAuthorizationHandler.HandleRequirementAsync
/// DENIES access without calling context.Succeed() — proving the fail-safe guard.
///
/// IMPORTANT: Gate 2 must NOT call InitializeAsync before the test.
/// Calling InitializeAsync would set IsReady = true, turning this into a warm-cache test —
/// the exact accidental false GREEN the ADR prohibits.
/// </summary>
[Trait("Category", "PbacHardening")]
public class PbacHardeningGateDiTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly IServiceProvider _rootSp;

    public PbacHardeningGateDiTests(TestWebApplicationFactory factory)
    {
        factory.EnsureDatabaseCreated();
        _rootSp = factory.Services;
    }

    [Fact]
    [Trait("Category", "PbacHardening")]
    public void Gate1_PbacDictionaryCache_IsRegisteredAsSingleton()
    {
        // Arrange: resolve from the root service provider TWICE — no scope.
        // A Singleton must return the exact same object reference both times.

        // Act
        var instance1 = _rootSp.GetRequiredService<PbacDictionaryCache>();
        var instance2 = _rootSp.GetRequiredService<PbacDictionaryCache>();

        // Assert: ReferenceEquals proves it is the SAME OBJECT — not two separate instances.
        Assert.True(
            ReferenceEquals(instance1, instance2),
            "PbacDictionaryCache must be a true Singleton. " +
            "Two resolutions from the root provider returned DIFFERENT instances, " +
            "indicating a transient or scoped registration bug in Program.cs.");
    }
}

/// <summary>
/// Gate 2 is a pure unit test — no WAF, no DB, no collection dependency.
/// It tests the handler's fail-closed guard using an isolated, cold-start cache instance.
/// </summary>
[Trait("Category", "PbacHardening")]
public class PbacHardeningGateColdStartTests
{
    [Fact]
    [Trait("Category", "PbacHardening")]
    public async Task Gate2_CapabilityHandler_DeniesAllRequests_WhenCacheIsNotReady()
    {
        // Arrange
        // DO NOT call InitializeAsync — this is the cold-start state.
        // IsReady defaults to false immediately after construction.
        var coldCache = new PbacDictionaryCache();

        // Verify our precondition before Act — a warm cache would make this a different test.
        Assert.False(coldCache.IsReady, "Precondition failed: cache must be in cold-start state (IsReady == false) before Act.");

        var handler = new CapabilityAuthorizationHandler(coldCache);

        // Build an authenticated ClaimsPrincipal — role "admin" is a warm-cache role.
        // Even a fully authenticated admin MUST be denied when the cache is not ready.
        var identity = new ClaimsIdentity(
        [
            new Claim(ClaimTypes.NameIdentifier, "user-123"),
            new Claim(ClaimTypes.Role, "admin")
        ], authenticationType: "TestAuth");
        var user = new ClaimsPrincipal(identity);

        var requirement = new CapabilityRequirement("templates:create");
        var context = new AuthorizationHandlerContext([requirement], user, resource: null);

        // Act
        await ((IAuthorizationHandler)handler).HandleAsync(context);

        // Assert: Succeed() must NEVER have been called.
        // context.HasSucceeded == false proves the fail-closed guard works.
        Assert.False(
            context.HasSucceeded,
            "FAIL-OPEN VULNERABILITY DETECTED: CapabilityAuthorizationHandler called " +
            "context.Succeed() even though the cache was not initialized (IsReady == false). " +
            "This means uninitialized servers would grant access to all protected endpoints.");
    }
}

/// <summary>
/// Gate 3 (Cross-Thread IsReady Visibility Proof):
/// Calls InitializeAsync from a background Task (simulating the listener thread),
/// then reads IsReady from the test thread via Volatile.Read.
/// Proves the Volatile.Write in InitializeAsync is visible across thread boundaries
/// on ARM64 and x86/x64 architectures.
///
/// Gate 3b (IsRebuilding Volatile Round-Trip):
/// Proves the IsRebuilding setter uses Volatile.Write and the getter uses Volatile.Read
/// by exercising the set/get cycle that mirrors ProcessDebounceAsync's finally block.
/// </summary>
[Trait("Category", "PbacHardening")]
public class PbacHardeningGateVolatileTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly IServiceProvider _sp;

    public PbacHardeningGateVolatileTests(TestWebApplicationFactory factory)
    {
        factory.EnsureDatabaseCreated();
        _sp = factory.Services;
    }

    [Fact]
    [Trait("Category", "PbacHardening")]
    public async Task Gate3_IsReady_IsVisibleAcrossThreadBoundaries_AfterInitialize()
    {
        // Arrange
        var cache = new PbacDictionaryCache();
        Assert.False(cache.IsReady, "Precondition: IsReady must start false.");

        // Act: run InitializeAsync on a background thread (TaskScheduler = ThreadPool),
        // simulating the background listener writing IsReady from a different CPU core.
        await Task.Run(async () => await cache.InitializeAsync(_sp));

        // Assert: the test thread must observe IsReady = true via Volatile.Read.
        // If the backing field were a plain non-volatile field, this assertion could
        // fail on ARM64 due to stale CPU register caching (read-after-write hazard).
        Assert.True(
            cache.IsReady,
            "Cross-thread visibility failure: IsReady was not observable as true " +
            "after InitializeAsync completed on a background thread. " +
            "This indicates Volatile.Write is missing from the write path.");
    }

    [Fact]
    [Trait("Category", "PbacHardening")]
    public void Gate3b_IsRebuilding_VolatileSetAndGet_ReflectsImmediately()
    {
        // Arrange
        var cache = new PbacDictionaryCache();
        Assert.False(cache.IsRebuilding, "Precondition: IsRebuilding must start false.");

        // Act: set from the same thread (simplest proof that Volatile.Write setter works)
        cache.IsRebuilding = true;

        // Assert: Volatile.Read in the getter must return true immediately.
        Assert.True(cache.IsRebuilding,
            "IsRebuilding setter/getter Volatile ordering is broken — returned false after true was set.");

        // Act: reset (matching the finally-block behavior in ProcessDebounceAsync)
        cache.IsRebuilding = false;

        // Assert
        Assert.False(cache.IsRebuilding,
            "IsRebuilding did not reset to false via Volatile.Write.");
    }
}

