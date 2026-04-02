using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Submissions;
using Xunit;

namespace Checkly.Api.Tests.Submissions;

public class TemplateSnapshotBuilderTests
{
    [Fact]
    public void BuildSnapshot_MapsEntitiesToJsonCorrectly()
    {
        // Arrange
        var template = new Template
        {
            Id = Guid.NewGuid(),
            Title = "Food Safety",
            Version = 2,
            ScoringLogicConfig = "{\"scoringMode\":\"accumulation\"}",
            DisplayNoun = "Inspection"
        };

        var groups = new List<Group>
        {
            new Group
            {
                Id = Guid.NewGuid(),
                Title = "Kitchen Hygiene",
                Weight = 1.0m,
                OrderIndex = 1
            }
        };

        var criteria = new List<Criterion>
        {
            new Criterion
            {
                Id = Guid.NewGuid(),
                GroupId = groups[0].Id,
                Label = "Floors are clean",
                InputType = "pass_fail",
                PointsWeight = 10,
                OrderIndex = 1
            }
        };

        // Act
        var resultJson = TemplateSnapshotBuilder.BuildSnapshot(template, groups, criteria);

        // Assert
        Assert.False(string.IsNullOrWhiteSpace(resultJson));
        
        using var doc = JsonDocument.Parse(resultJson);
        var root = doc.RootElement;
        
        Assert.Equal("Food Safety", root.GetProperty("title").GetString());
        Assert.Equal(2, root.GetProperty("version").GetInt32());
        
        var groupsArray = root.GetProperty("groups");
        Assert.Equal(1, groupsArray.GetArrayLength());
        
        var firstGroup = groupsArray[0];
        Assert.Equal("Kitchen Hygiene", firstGroup.GetProperty("title").GetString());
        
        var criteriaArray = firstGroup.GetProperty("criteria");
        Assert.Equal(1, criteriaArray.GetArrayLength());
        Assert.Equal("Floors are clean", criteriaArray[0].GetProperty("label").GetString());
    }

    [Fact]
    public void BuildSnapshot_HandlesEmptyConfigurations()
    {
        // Arrange
        var template = new Template
        {
            Id = Guid.NewGuid(),
            Title = "Empty Audit",
            Version = 1
        };

        // Act
        var resultJson = TemplateSnapshotBuilder.BuildSnapshot(template, [], []);

        // Assert
        Assert.False(string.IsNullOrWhiteSpace(resultJson));
        
        using var doc = JsonDocument.Parse(resultJson);
        var root = doc.RootElement;
        
        Assert.Equal("Empty Audit", root.GetProperty("title").GetString());
        Assert.Equal(0, root.GetProperty("groups").GetArrayLength());
    }
}
