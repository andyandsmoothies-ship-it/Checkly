using System.Reflection;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Checkly.Api.Tests.Architecture;

public class AppDbContextSplitTests
{
    [Fact]
    public void AppDbContext_Uses_ApplyConfigurationsFromAssembly()
    {
        // This test ensures that the entities are extracted into IEntityTypeConfiguration<T> classes.
        var assembly = typeof(AppDbContext).Assembly;
        
        var configurationTypes = assembly.GetTypes()
            .Where(t => !t.IsAbstract && t.GetInterfaces().Any(i => 
                i.IsGenericType && i.GetGenericTypeDefinition() == typeof(IEntityTypeConfiguration<>)))
            .ToList();

        // There should be at least a few extracted configurations.
        Assert.True(configurationTypes.Count >= 5, $"Expected AppDbContext configurations to be extracted, but found {configurationTypes.Count}. AppDbContext is oversized and must be refactored.");
        
        // Ensure some key entities have their own configuration classes
        var hasSubmissionConfig = configurationTypes.Any(t => t.GetInterfaces().Any(i => i.GenericTypeArguments.Contains(typeof(Submission))));
        var hasTemplateConfig = configurationTypes.Any(t => t.GetInterfaces().Any(i => i.GenericTypeArguments.Contains(typeof(Template))));
        var hasActionPlanConfig = configurationTypes.Any(t => t.GetInterfaces().Any(i => i.GenericTypeArguments.Contains(typeof(ActionPlan))));

        Assert.True(hasSubmissionConfig, "SubmissionConfiguration is missing.");
        Assert.True(hasTemplateConfig, "TemplateConfiguration is missing.");
        Assert.True(hasActionPlanConfig, "ActionPlanConfiguration is missing.");
    }
}
