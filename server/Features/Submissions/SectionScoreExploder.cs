using System;
using System.Text.Json;
using System.Threading;
using System.Threading.Tasks;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;

namespace Checkly.Api.Features.Submissions;

public static class SectionScoreExploder
{
    public static Task ExplodeAsync(Guid submissionId, Guid? storeId, Guid? templateId, string? sectionScoresJson, AppDbContext db, DateTimeOffset now, CancellationToken ct = default)
    {
        if (string.IsNullOrEmpty(sectionScoresJson))
            return Task.CompletedTask;

        try
        {
            var sectionsDoc = JsonDocument.Parse(sectionScoresJson);
            foreach (var prop in sectionsDoc.RootElement.EnumerateObject())
            {
                var sectionTitle = prop.Name;
                if (prop.Value.ValueKind == JsonValueKind.Object)
                {
                    if (prop.Value.TryGetProperty("title", out var titleProp) && titleProp.ValueKind == JsonValueKind.String)
                    {
                        var tVal = titleProp.GetString();
                        if (!string.IsNullOrWhiteSpace(tVal))
                        {
                            sectionTitle = tVal;
                        }
                    }
                }

                var sectionScore = 0m;
                if (prop.Value.ValueKind == JsonValueKind.Object)
                {
                    if (prop.Value.TryGetProperty("score", out var sc))
                    {
                        if (sc.ValueKind == JsonValueKind.Number)
                        {
                            sectionScore = sc.GetDecimal();
                        }
                        else if (sc.ValueKind == JsonValueKind.String && decimal.TryParse(sc.GetString(), out var parsedScore))
                        {
                            sectionScore = parsedScore;
                        }
                    }
                }

                var sectionMax = 0m;
                if (prop.Value.ValueKind == JsonValueKind.Object)
                {
                    if (prop.Value.TryGetProperty("maxScore", out var mx))
                    {
                        if (mx.ValueKind == JsonValueKind.Number)
                        {
                            sectionMax = mx.GetDecimal();
                        }
                        else if (mx.ValueKind == JsonValueKind.String && decimal.TryParse(mx.GetString(), out var parsedMax))
                        {
                            sectionMax = parsedMax;
                        }
                    }
                    else if (prop.Value.TryGetProperty("maxPoints", out var mp))
                    {
                        if (mp.ValueKind == JsonValueKind.Number)
                        {
                            sectionMax = mp.GetDecimal();
                        }
                        else if (mp.ValueKind == JsonValueKind.String && decimal.TryParse(mp.GetString(), out var parsedMax))
                        {
                            sectionMax = parsedMax;
                        }
                    }
                }

                db.SubmissionSectionScores.Add(new SubmissionSectionScore
                {
                    Id = Guid.NewGuid(),
                    SubmissionId = submissionId,
                    StoreId = storeId,
                    TemplateId = templateId,
                    SectionTitle = sectionTitle,
                    Score = sectionScore,
                    MaxScore = sectionMax,
                    Ratio = sectionMax > 0 ? Math.Round(sectionScore / sectionMax, 4) : null,
                    IsCcpFailed = false,
                    Weight = null,
                    CreatedAt = now
                });
            }
            return db.SaveChangesAsync(ct);
        }
        catch (JsonException)
        {
            // Malformed JSON → skip section score rows silently
        }
        return Task.CompletedTask;
    }
}
