using System.Net;
using System.Net.Http.Json;
using System.Text.Json;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

/// <summary>
/// ATDD Acceptance Tests — Slice 1: Audit Template Linter (C# Backend)
/// Source: test_contracts_20260529_104152_audit_template_flexibility_240f4566-499b-43d5-884f-c338ffd53913.md
///
/// These tests verify the blocking rules and advisory rules of the Audit Template Linter.
/// </summary>
public class TemplateLinter_Slice1_Tests : IClassFixture<TestWebApplicationFactory>
{
    private readonly TestWebApplicationFactory _factory;
    private readonly HttpClient _client;

    public TemplateLinter_Slice1_Tests(TestWebApplicationFactory factory)
    {
        _factory = factory;
        _factory.EnsureDatabaseCreated();
        _client = _factory.CreateClient();
    }

    // ─── Shared Helpers ──────────────────────────────────────────────────────

    private async Task<HttpClient> GetAdminClientAsync()
    {
        var token = await _factory.LoginBootstrapAdminAsync(_client);
        return _factory.CreateAuthenticatedClient(token);
    }

    private async Task<string> CreateTemplateAsync(HttpClient admin, string title, string type = "qc")
    {
        var response = await admin.PostAsJsonAsync("/api/templates", new
        {
            title,
            type,
            description = "Linter test template"
        });

        if (!response.IsSuccessStatusCode)
        {
            Assert.Fail($"Setup failed: Could not create template. Status: {response.StatusCode}. Body: {await response.Content.ReadAsStringAsync()}");
        }

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        return body.GetProperty("id").GetString()!;
    }

    // ─── Scenario 1: Empty Structure Check (Blocking Rule) ──────────────────
    [Fact]
    public async Task SaveTemplateTree_WithEmptyStructure_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Empty Structure Template");

        var payload = new
        {
            Title = "Empty Structure Template",
            Type = "qc",
            Description = "Empty groups test",
            Version = 1,
            Groups = Array.Empty<object>()
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "EmptyStructureCheck");
    }

    // ─── Scenario 2: Empty Section Name (Blocking Rule) ─────────────────────
    [Fact]
    public async Task SaveTemplateTree_WithEmptySectionName_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Empty Section Name Template");

        var payload = new
        {
            Title = "Empty Section Name Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "   ", // Blank spaces or null
                    Description = "Hygiene section",
                    Weight = (decimal?)10.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "EmptySectionName");
    }

    // ─── Scenario 3: Penalty Mode Group Sum (Blocking Rule) ──────────────────
    [Fact]
    public async Task SaveTemplateTree_WithWeightsSummingTo95_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Group Sum Template");

        var payload = new
        {
            Title = "Group Sum Template",
            Type = "qc",
            ScoringLogicConfig = "{\"scoringMode\":\"penalty\"}",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Kitchen",
                    Weight = (decimal?)95.0m, // Only 95%
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "PenaltyModeGroupSum");
    }

    // ─── Scenario 4: Duplicate ID Key Collision Check (Blocking Rule) ────────
    [Fact]
    public async Task SaveTemplateTree_WithDuplicateIds_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Duplicate ID Template");
        var duplicateId = Guid.NewGuid();

        var payload = new
        {
            Title = "Duplicate ID Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)duplicateId,
                    Title = "Kitchen",
                    Weight = (decimal?)50.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                },
                new
                {
                    Id = (Guid?)duplicateId, // Duplicate UUID key!
                    Title = "Service",
                    Weight = (decimal?)50.0m,
                    OrderIndex = 1,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "DuplicateIdCheck");
    }

    // ─── Scenario 5: Max Nesting Depth Exceeded Check (Blocking Rule) ────────
    [Fact]
    public async Task SaveTemplateTree_WithDepth3Exceeded_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Nesting Depth Template");

        // 3 levels of nesting: Group -> Subsection -> Subsubsection
        var payload = new
        {
            Title = "Nesting Depth Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Level 1",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Criteria = Array.Empty<object>(),
                    Children = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Title = "Level 2",
                            Weight = (decimal?)null,
                            OrderIndex = 0,
                            Criteria = Array.Empty<object>(),
                            Children = new[]
                            {
                                new
                                {
                                    Id = (Guid?)null,
                                    Title = "Level 3 - Illegal Nesting!",
                                    Weight = (decimal?)null,
                                    OrderIndex = 0,
                                    Children = Array.Empty<object>(),
                                    Criteria = Array.Empty<object>()
                                }
                            }
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "MaxNestingDepthExceeded");
    }

    // ─── Scenario 6: Poison Pill Payload Size Limit (Blocking Rule) ──────────
    [Fact]
    public async Task SaveTemplateTree_WithMoreThan500Nodes_Returns400()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Poison Pill Template");

        // Build a massive tree with 501 elements (1 group, 500 criteria)
        var criteria = new List<object>();
        for (int i = 0; i < 500; i++)
        {
            criteria.Add(new
            {
                Id = (Guid?)null,
                Label = $"Criterion {i}",
                InputType = "pass_fail",
                PointsWeight = (decimal?)1.0m,
                OrderIndex = i
            });
        }

        var payload = new
        {
            Title = "Poison Pill Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Massive Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = criteria.ToArray()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.BadRequest, response.StatusCode);
    }

    // ─── Scenario 7: IDOR Tenant Ownership Authorization (Blocking Rule) ─────
    [Fact]
    public async Task SaveTemplateTree_AsDifferentUser_Returns403()
    {
        // Arrange
        var client = _factory.CreateClient();

        // Register two Admin users
        var (tokenA, userIdA) = await _factory.RegisterUserAsync(client, "adminA@test.test", "Pass123!@", "Admin A", "admin");
        var (tokenB, userIdB) = await _factory.RegisterUserAsync(client, "adminB@test.test", "Pass123!@", "Admin B", "admin");

        var clientA = _factory.CreateAuthenticatedClient(tokenA);
        var clientB = _factory.CreateAuthenticatedClient(tokenB);

        // Client A creates a template
        var templateId = await CreateTemplateAsync(clientA, "Client A Template");

        var payload = new
        {
            Title = "Hostile Modification",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Hacked Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act - Client B tries to save the tree
        var response = await clientB.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    // ─── Scenario 8: Progressive Repeat Penalty Overflow Safety (SRE Flop) ────
    [Fact]
    public void ProgressiveRepeat_OverflowSafety_CalculatesCorrectly()
    {
        // Arrange
        var criterion = new Criterion
        {
            PointsWeight = 10m,
            MinusImpact = 2m
        };
        var answer = new Answer
        {
            Value = "non_conform",
            NumericValue = 1,
            RepeatedFaults = 50000
        };

        // Act
        var deduction = ScoringHelpers.GetDeduction(criterion, new[] { answer }, progressiveRepeatPenalty: true);

        // Assert
        // Correct calculation (no overflow):
        // 50,000^2 = 2,500,000,000.
        // Base deduction = 1 * 2 = 2.
        // Repeat deduction = 2,500,000,000 * 2 = 5,000,000,000.
        // Total = 5,000,000,002.
        Assert.Equal(5000000002m, deduction);
    }

    // ─── Scenario 9: Mixed Audit Scored and Unscored Criteria (Advisory) ─────
    [Fact]
    public async Task SaveTemplateTree_WithMixedScoredAndUnscored_ReturnsWarning()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Mixed Scored Template");

        var payload = new
        {
            Title = "Mixed Scored Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Mixed Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Scored Criterion",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            OrderIndex = 0
                        },
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Unscored Comments",
                            InputType = "text", // unscored
                            PointsWeight = (decimal?)null,
                            OrderIndex = 1
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("lintResult", out var lintResultObj));
        Assert.True(lintResultObj.TryGetProperty("warnings", out var warningsList));
        var list = warningsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "MixedAuditWarning");
    }

    // ─── Scenario 10: Silent Risk In Survey Template (Advisory) ──────────────
    [Fact]
    public async Task SaveTemplateTree_WithSilentRiskInSurvey_ReturnsWarning()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Survey Template", type: "survey");

        var payload = new
        {
            Title = "Survey Template",
            Type = "survey",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Survey Section",
                    Weight = (decimal?)null,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Risk Question",
                            InputType = "text",
                            IsRisk = true, // isRisk = true in survey!
                            OrderIndex = 0
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("lintResult", out var lintResultObj));
        Assert.True(lintResultObj.TryGetProperty("warnings", out var warningsList));
        var list = warningsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "SilentRiskInSurvey");
    }

    // ─── Scenario 11: Progressive Zero Impact (Advisory) ─────────────────────
    [Fact]
    public async Task SaveTemplateTree_WithProgressiveZeroImpact_ReturnsWarning()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Zero Impact Template");

        var payload = new
        {
            Title = "Zero Impact Template",
            Type = "qc",
            ScoringLogicConfig = "{\"scoringMode\":\"penalty\",\"progressiveRepeat\":true}",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Zero Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Zero Impact Criterion",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)10.0m,
                            MinusImpact = (decimal?)0.0m, // minusImpact = 0!
                            OrderIndex = 0
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("lintResult", out var lintResultObj));
        Assert.True(lintResultObj.TryGetProperty("warnings", out var warningsList));
        var list = warningsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "ProgressiveZeroImpact");
    }

    // ─── Scenario 12: Existing Valid Template Saves Successfully ────────────
    [Fact]
    public async Task SaveTemplateTree_WithFullyValidTree_SavesSuccessfully()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Valid Template");

        var payload = new
        {
            Title = "Valid Template",
            Type = "qc",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Valid Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Valid Scored Criterion",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            OrderIndex = 0
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("lintResult", out var lintResultObj));
        Assert.True(lintResultObj.TryGetProperty("errors", out var errorsList));
        Assert.True(lintResultObj.TryGetProperty("warnings", out var warningsList));
        Assert.Empty(errorsList.EnumerateArray());
        Assert.Empty(warningsList.EnumerateArray());
    }

    // ─── Scenario 13: New Weighted JSON Format Group Sum (Blocking Rule - TC-09) ──────
    [Fact]
    public async Task SaveTemplateTree_WithNewWeightedJsonSummingTo95_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "New Weighted Group Sum Template");

        var payload = new
        {
            Title = "New Weighted Group Sum Template",
            Type = "qc",
            ScoringLogicConfig = "{\"scoreDirection\":\"down\",\"isWeighted\":true}",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Kitchen",
                    Weight = (decimal?)95.0m, // Only 95%
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "PenaltyModeGroupSum");
    }

    // ─── Scenario 14: New Unweighted JSON Format Group Sum (No Blocking - TC-09b) ────
    [Fact]
    public async Task SaveTemplateTree_WithNewUnweightedJsonSummingTo95_SavesSuccessfully()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "New Unweighted Group Sum Template");

        var payload = new
        {
            Title = "New Unweighted Group Sum Template",
            Type = "qc",
            ScoringLogicConfig = "{\"scoreDirection\":\"down\",\"isWeighted\":false}",
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Kitchen",
                    Weight = (decimal?)95.0m, // Not 100%, but isWeighted = false so sum check is skipped
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = Array.Empty<object>()
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    // ─── Scenario 15: Category Type Mismatch Rule (Blocking Rule) ─────────────
    [Fact]
    public async Task SaveTemplateTree_WithCcpAndNonQcCategory_Returns422()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Mismatch Category Template", type: "safety");

        var payload = new
        {
            Title = "Mismatch Category Template",
            Type = "safety", // Mismatch category type (must be qc due to CCP/Risk)
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "Safety Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "Safety Checkpoint",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            IsCcp = true, // Critical Control Point
                            OrderIndex = 0
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.UnprocessableEntity, response.StatusCode);

        var body = await response.Content.ReadFromJsonAsync<JsonElement>();
        Assert.True(body.TryGetProperty("errors", out var errorsObj));
        Assert.True(errorsObj.TryGetProperty("lintResult", out var errorsList));
        var list = errorsList.EnumerateArray().ToList();
        Assert.Contains(list, x => x.GetProperty("ruleId").GetString() == "CategoryTypeMismatch");
    }

    [Fact]
    public async Task SaveTemplateTree_WithCcpAndQcCategory_SavesSuccessfully()
    {
        // Arrange
        var admin = await GetAdminClientAsync();
        var templateId = await CreateTemplateAsync(admin, "Valid CCP Template", type: "qc");

        var payload = new
        {
            Title = "Valid CCP Template",
            Type = "qc", // Valid category type for CCP/Risk
            Version = 1,
            Groups = new[]
            {
                new
                {
                    Id = (Guid?)null,
                    Title = "QC Section",
                    Weight = (decimal?)100.0m,
                    OrderIndex = 0,
                    Children = Array.Empty<object>(),
                    Criteria = new[]
                    {
                        new
                        {
                            Id = (Guid?)null,
                            Label = "QC Critical Checkpoint",
                            InputType = "pass_fail",
                            PointsWeight = (decimal?)5.0m,
                            IsCcp = true, // Critical Control Point
                            OrderIndex = 0
                        }
                    }
                }
            }
        };

        // Act
        var response = await admin.PutAsJsonAsync($"/api/templates/{templateId}/tree", payload);

        // Assert
        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }
}
