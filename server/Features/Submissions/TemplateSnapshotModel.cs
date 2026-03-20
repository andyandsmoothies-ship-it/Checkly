using System.Text.Json.Serialization;

namespace Checkly.Api.Features.Submissions;

/// <summary>
/// Snapshot model for serializing/deserializing the frozen template tree
/// stored on each submission. Uses snapshotVersion for future schema evolution.
/// </summary>
public sealed class TemplateSnapshotModel
{
    [JsonPropertyName("snapshotVersion")]
    public int SnapshotVersion { get; set; } = 1;

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("version")]
    public int Version { get; set; }

    [JsonPropertyName("scoringLogicConfig")]
    public string? ScoringLogicConfig { get; set; }

    [JsonPropertyName("displayNoun")]
    public string? DisplayNoun { get; set; }

    [JsonPropertyName("groups")]
    public List<SnapshotGroup> Groups { get; set; } = [];
}

public sealed class SnapshotGroup
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("title")]
    public string Title { get; set; } = string.Empty;

    [JsonPropertyName("weight")]
    public decimal? Weight { get; set; }

    [JsonPropertyName("maxDeductionPoints")]
    public decimal? MaxDeductionPoints { get; set; }

    [JsonPropertyName("minusPerFault")]
    public decimal? MinusPerFault { get; set; }

    [JsonPropertyName("orderIndex")]
    public int OrderIndex { get; set; }

    [JsonPropertyName("parentId")]
    public Guid? ParentId { get; set; }

    [JsonPropertyName("metadata")]
    public string? Metadata { get; set; }

    [JsonPropertyName("criteria")]
    public List<SnapshotCriterion> Criteria { get; set; } = [];
}

public sealed class SnapshotCriterion
{
    [JsonPropertyName("id")]
    public Guid Id { get; set; }

    [JsonPropertyName("groupId")]
    public Guid GroupId { get; set; }

    [JsonPropertyName("label")]
    public string Label { get; set; } = string.Empty;

    [JsonPropertyName("inputType")]
    public string InputType { get; set; } = string.Empty;

    [JsonPropertyName("pointsWeight")]
    public decimal? PointsWeight { get; set; }

    [JsonPropertyName("isCcp")]
    public bool IsCcp { get; set; }

    [JsonPropertyName("isRisk")]
    public bool IsRisk { get; set; }

    [JsonPropertyName("minusImpact")]
    public decimal? MinusImpact { get; set; }

    [JsonPropertyName("orderIndex")]
    public int OrderIndex { get; set; }

    [JsonPropertyName("metadata")]
    public string? Metadata { get; set; }
}
