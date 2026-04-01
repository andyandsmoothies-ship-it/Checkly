using System.Reflection;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;
using Xunit;

namespace Checkly.Api.Tests;

public class VoidAuditTests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public VoidAuditTests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public void Submission_Fields_CorrectColumnMapping()
    {
        // Arrange
        var type = typeof(Submission);

        // Act
        var voidReasonProp = type.GetProperty("VoidReason", BindingFlags.Public | BindingFlags.Instance);
        var voidedAtProp = type.GetProperty("VoidedAt", BindingFlags.Public | BindingFlags.Instance);

        // Assert
        Assert.NotNull(voidReasonProp);
        Assert.Equal(typeof(string), voidReasonProp?.PropertyType);

        Assert.NotNull(voidedAtProp);
        Assert.Equal(typeof(DateTimeOffset?), voidedAtProp?.PropertyType);
    }

    [Fact]
    public async Task Submission_StatusConstraint_AllowsVoided()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            Status = "voided",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Submissions.Add(submission);

        // Act
        var exception = await Record.ExceptionAsync(() => db.SaveChangesAsync());

        // Assert
        Assert.Null(exception); // We expect this NOT to throw an exception once the constraint is updated
    }

    [Fact]
    public async Task Submission_StatusConstraint_RejectsInvalidStatus()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<Checkly.Api.Common.Persistence.AppDbContext>();

        var submission = new Submission
        {
            Id = Guid.NewGuid(),
            Status = "illegal_status_999",
            CreatedAt = DateTimeOffset.UtcNow,
            UpdatedAt = DateTimeOffset.UtcNow
        };

        db.Submissions.Add(submission);

        // Act
        var exception = await Record.ExceptionAsync(() => db.SaveChangesAsync());

        // Assert
        Assert.NotNull(exception);
        Assert.IsType<DbUpdateException>(exception);
    }
}
