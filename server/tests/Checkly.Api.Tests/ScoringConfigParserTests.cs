using Checkly.Api.Common.Scoring;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringConfigParserTests
{
    [Fact]
    public void Parse_Returns_Default_For_Null_Input()
    {
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(null);
        Assert.Equal("down", direction);
        Assert.False(weighted);
        Assert.False(progressive);
    }

    [Fact]
    public void Parse_Returns_Default_For_Malformed_Json()
    {
        var (direction, weighted, progressive) = ScoringConfigParser.Parse("{ invalid json");
        Assert.Equal("down", direction);
        Assert.False(weighted);
        Assert.False(progressive);
    }

    [Fact]
    public void Parse_Reads_New_Json_Format_Correctly()
    {
        var json = "{\"scoreDirection\":\"up\",\"isWeighted\":true,\"progressiveRepeat\":true}";
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal("up", direction);
        Assert.True(weighted);
        Assert.True(progressive);
    }

    [Fact]
    public void Parse_Defaults_ScoreDirection_To_Down()
    {
        var json = "{\"isWeighted\":true}";
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal("down", direction);
        Assert.True(weighted);
        Assert.False(progressive);
    }

    [Fact]
    public void Parse_Defaults_IsWeighted_To_False()
    {
        var json = "{\"scoreDirection\":\"up\"}";
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal("up", direction);
        Assert.False(weighted);
        Assert.False(progressive);
    }

    [Theory]
    [InlineData("penalty", "down", true)]
    [InlineData("checklist", "down", false)]
    [InlineData("accumulation", "up", false)]
    [InlineData("survey", "none", false)]
    [InlineData("unknown_mode", "down", false)]
    public void Parse_Maps_Legacy_ScoringMode_Correctly(string legacyMode, string expectedDirection, bool expectedWeighted)
    {
        var json = $"{{\"scoringMode\":\"{legacyMode}\"}}";
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal(expectedDirection, direction);
        Assert.Equal(expectedWeighted, weighted);
        Assert.False(progressive);
    }

    [Theory]
    [InlineData("left")]
    [InlineData("right")]
    [InlineData("invalid")]
    [InlineData("")]
    public void Parse_Falls_Back_To_Down_For_Invalid_ScoreDirection(string invalidDirection)
    {
        var json = $"{{\"scoreDirection\":\"{invalidDirection}\",\"isWeighted\":true}}";
        var (direction, weighted, progressive) = ScoringConfigParser.Parse(json);
        Assert.Equal("down", direction);
        Assert.True(weighted);
        Assert.False(progressive);
    }
}
