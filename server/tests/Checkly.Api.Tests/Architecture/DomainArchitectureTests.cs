using NetArchTest.Rules;
using Xunit;

namespace Checkly.Api.Tests.Architecture;

public class DomainArchitectureTests
{
    [Fact]
    public void CommonPersistenceEntities_ShouldNotDependOn_FeaturesNamespace()
    {
        // 1. Get the assembly containing our business entity models
        var assembly = typeof(Checkly.Api.Common.Persistence.Entities.Submission).Assembly;

        // 2. Define that types inside the core entity namespace do NOT depend on features or endpoints
        var result = Types.InAssembly(assembly)
            .That()
            .ResideInNamespace("Checkly.Api.Common.Persistence.Entities")
            .ShouldNot()
            .HaveDependencyOn("Checkly.Api.Features")
            .GetResult();

        // 3. Fail the test with detail if there are any violations
        if (!result.IsSuccessful && result.FailingTypes != null)
        {
            var failingTypeList = string.Join(", ", result.FailingTypes.Select(t => t.FullName));
            Assert.Fail($"Architecture Violation: Core database entities illegally depend on the Features (outer) layer! Failing types: {failingTypeList}");
        }

        Assert.True(result.IsSuccessful);
    }
}
