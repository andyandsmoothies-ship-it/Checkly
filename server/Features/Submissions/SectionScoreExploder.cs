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
                var sectionScore = prop.Value.TryGetProperty("score", out var sc) ? sc.GetDecimal() : 0m;
                var sectionMax = prop.Value.TryGetProperty("maxScore", out var mx) ? mx.GetDecimal() : 0m;

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
