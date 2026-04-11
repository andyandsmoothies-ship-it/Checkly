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
