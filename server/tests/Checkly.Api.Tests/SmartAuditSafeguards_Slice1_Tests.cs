using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

public class SmartAuditSafeguards_Slice1_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public SmartAuditSafeguards_Slice1_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public void TemplateEntity_HasGeofencePropertiesAndMappings()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var model = context.Model;

        // Act
        var templateType = model.FindEntityType(typeof(Template));
        Assert.NotNull(templateType);

        var modeProp = templateType.FindProperty("GeofenceMode");
        var radiusProp = templateType.FindProperty("GeofenceRadiusMeters");

        // Assert
        Assert.NotNull(modeProp);
        Assert.Equal("geofence_mode", modeProp.GetColumnName());
        Assert.Equal("none", modeProp.GetDefaultValue());
        Assert.False(modeProp.IsNullable);

        Assert.NotNull(radiusProp);
        Assert.Equal("geofence_radius_meters", radiusProp.GetColumnName());
        Assert.Equal(100, radiusProp.GetDefaultValue());
        Assert.False(radiusProp.IsNullable);
    }

    [Fact]
    public void SubmissionEntity_HasGeofenceTelemetryPropertiesAndMappings()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();
        var model = context.Model;

        // Act
        var submissionType = model.FindEntityType(typeof(Submission));
        Assert.NotNull(submissionType);

        var bypassedProp = submissionType.FindProperty("IsGeofenceBypassed");
        var distanceProp = submissionType.FindProperty("DistanceMetersOff");

        // Assert
        Assert.NotNull(bypassedProp);
        Assert.Equal("is_geofence_bypassed", bypassedProp.GetColumnName());
        Assert.True(bypassedProp.IsNullable);

        Assert.NotNull(distanceProp);
        Assert.Equal("distance_meters_off", distanceProp.GetColumnName());
        Assert.True(distanceProp.IsNullable);
    }
}
