using Checkly.Api.Common.Auth;
using Xunit;

namespace Checkly.Api.Tests.Features.Auth;

/// <summary>
/// TDD: TC-CAPS-01 — Verify AppCapabilities constants.
/// Sentinel writes this test first. It will fail to compile because AppCapabilities does not exist.
/// </summary>
public class AppCapabilitiesTests
{
    [Fact]
    public void AppCapabilities_Constants_HaveCorrectValues()
    {
        // Arrange & Act
        // (Nothing to arrange, testing static constants)

        // Assert
        Assert.Equal("admin:access",       AppCapabilities.AdminAccess);
        Assert.Equal("templates:create",   AppCapabilities.TemplatesCreate);
        Assert.Equal("templates:update",   AppCapabilities.TemplatesUpdate);
        Assert.Equal("templates:delete",   AppCapabilities.TemplatesDelete);
        Assert.Equal("stores:write",       AppCapabilities.StoresWrite);
        Assert.Equal("areas:write",        AppCapabilities.AreasWrite);
        Assert.Equal("users:manage",       AppCapabilities.UsersManage);
        Assert.Equal("analytics:admin",    AppCapabilities.AnalyticsAdmin);
        Assert.Equal("analytics:view",     AppCapabilities.AnalyticsView);
        Assert.Equal("analytics:area",     AppCapabilities.AnalyticsArea);
        Assert.Equal("submissions:list",   AppCapabilities.SubmissionsList);
        Assert.Equal("programs:execute",   AppCapabilities.ProgramsExecute);
        Assert.Equal("admin:manage_roles", AppCapabilities.AdminManageRoles);
    }
}
