using System.Security.Claims;
using AccessGuard = Checkly.Api.Common.SubmissionAccessGuard;
using Xunit;

namespace Checkly.Api.Tests.Guards;

/// <summary>
/// TDD unit specs for SubmissionAccessGuard.CanDelegate(ClaimsPrincipal).
/// Source: implementation_plan_tactical_gate_idor.md.resolved
///
/// Test Plan:
///   - admin          → CanDelegate() == true  (happy path)
///   - area_manager   → CanDelegate() == true  (gap AC — currently broken by "manager" typo)
///   - auditor        → CanDelegate() == false (negative gate)
///   - store_manager  → CanDelegate() == false (negative gate)
///   - null/empty role → CanDelegate() == false (empty/boundary state)
/// </summary>
public class SubmissionAccessGuardUnitTests
{
    // ─── Helpers ──────────────────────────────────────────────────────────────

    private static ClaimsPrincipal MakeUser(string? role)
    {
        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, Guid.NewGuid().ToString())
        };
        if (role is not null)
            claims.Add(new Claim(ClaimTypes.Role, role));

        return new ClaimsPrincipal(new ClaimsIdentity(claims, "TestAuth"));
    }

    // ─── Happy Path ───────────────────────────────────────────────────────────

    [Fact]
    public void CanDelegate_Admin_ReturnsTrue()
    {
        // Arrange
        var user = MakeUser("admin");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.True(result);
    }

    [Fact]
    public void CanDelegate_AreaManager_ReturnsTrue()
    {
        // Arrange — RED: current code uses "manager" not "area_manager"; this MUST fail now
        var user = MakeUser("area_manager");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.True(result);
    }

    // ─── Negative Gate ────────────────────────────────────────────────────────

    [Fact]
    public void CanDelegate_Auditor_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser("auditor");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    [Fact]
    public void CanDelegate_StoreManager_ReturnsFalse()
    {
        // Arrange
        var user = MakeUser("store_manager");

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    // ─── Boundary / Empty State ───────────────────────────────────────────────

    [Fact]
    public void CanDelegate_NoRoleClaim_ReturnsFalse()
    {
        // Arrange — user with no role claim at all (edge: missing claim vs empty string)
        var user = MakeUser(null);

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }

    [Theory]
    [InlineData("")]
    [InlineData("superadmin")]
    [InlineData("ADMIN")]         // case-sensitivity guard
    [InlineData("Area_Manager")]  // underscore vs camel case guard
    public void CanDelegate_UnrecognizedRole_ReturnsFalse(string role)
    {
        // Arrange
        var user = MakeUser(role);

        // Act
        var result = AccessGuard.CanDelegate(user);

        // Assert
        Assert.False(result);
    }
}
