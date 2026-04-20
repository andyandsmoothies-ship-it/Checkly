using Checkly.Api.Common.Scoring;

namespace Checkly.Api.Tests;

public class ScoringConfigParserTests
{
    [Fact]
    public void Parse_Returns_Penalty_For_Null_Input()
    {
        var (mode, progressive) = ScoringConfigParser.Parse(null);
        Assert.Equal("penalty", mode);
        Assert.False(progressive);
    }

    [Fact]
    public void Parse_Returns_Penalty_For_Malformed_Json()
    {
        var (mode, progressive) = ScoringConfigParser.Parse("{ invalid json");
        Assert.Equal("penalty", mode);
        Assert.False(progressive);
    }

    [Fact]
    public void Parse_Reads_ScoringMode_And_ProgressiveRepeat()
    {
        var json = "{\"scoringMode\":\"checklist\",\"progressiveRepeat\":true}";
        var (mode, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal("checklist", mode);
        Assert.True(progressive);
    }
}
