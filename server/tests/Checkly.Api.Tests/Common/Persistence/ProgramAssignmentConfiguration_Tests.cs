using Checkly.Api.Common.Persistence;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.EntityFrameworkCore;

namespace Checkly.Api.Tests.Persistence;

public class ProgramAssignmentConfiguration_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;

    public ProgramAssignmentConfiguration_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
    }

    [Fact]
    public void ProgramAssignment_HasIndex_OnAssigneeId()
    {
        // Arrange
        using var scope = _factory.Services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();

        // Act
        var entityType = db.Model.FindEntityType(typeof(Checkly.Api.Common.Persistence.Entities.ProgramAssignment));
        
        // Assert
        Assert.NotNull(entityType);
        
        var indexes = entityType.GetIndexes();
        
        // We expect at least one index to contain the AssigneeId property.
        // And preferably not just as a part of a composite key unless it's the first column, 
        // but for this test, we just check if an explicit index is defined with AssigneeId.
        var hasAssigneeIdIndex = indexes.Any(i => i.Properties.Any(p => p.Name == "AssigneeId"));
        
        Assert.True(hasAssigneeIdIndex, "Expected ProgramAssignment to have a database index on AssigneeId for performance.");
    }
}
