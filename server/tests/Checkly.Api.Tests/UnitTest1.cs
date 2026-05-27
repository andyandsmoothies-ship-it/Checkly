using System;
using System.IO;
using System.Linq;
using System.Text.Json;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Microsoft.EntityFrameworkCore;
using Xunit;

namespace Checkly.Api.Tests;

public class UnitTest1
{
    [Fact]
    public void TestDatabaseData()
    {
        var logDir = @"c:\Users\HP\Documents\GitHub\Checkly\.agents\logs";
        if (!Directory.Exists(logDir))
        {
            Directory.CreateDirectory(logDir);
        }
        var logPath = Path.Combine(logDir, "debug_db_out.txt");

        using var sw = new StreamWriter(logPath, false);
        sw.WriteLine("=== Checkly Database Diagnostic ===");
        sw.WriteLine($"Run Date: {DateTimeOffset.UtcNow}");

        try
        {
            var connStr = "Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@";
            var optionsBuilder = new DbContextOptionsBuilder<AppDbContext>();
            optionsBuilder.UseNpgsql(connStr);

            using var db = new AppDbContext(optionsBuilder.Options);

            sw.WriteLine("\n--- Submissions ---");
            var submissions = db.Submissions.AsNoTracking().ToList();
            sw.WriteLine($"Total Submissions: {submissions.Count}");
            foreach (var sub in submissions)
            {
                sw.WriteLine($"Id: {sub.Id}, StoreName: {sub.StoreName}, Status: {sub.Status}, CompletedAt: {sub.CompletedAt}, SectionScores: {sub.SectionScores}");
            }

            sw.WriteLine("\n--- Submission Section Scores ---");
            var scores = db.SubmissionSectionScores.AsNoTracking().ToList();
            sw.WriteLine($"Total Scores: {scores.Count}");
            foreach (var score in scores)
            {
                sw.WriteLine($"Id: {score.Id}, SubmissionId: {score.SubmissionId}, StoreId: {score.StoreId}, SectionTitle: '{score.SectionTitle}', Score: {score.Score}, MaxScore: {score.MaxScore}, Ratio: {score.Ratio}");
            }

            sw.WriteLine("\n--- Distinct Section Titles ---");
            var distinctTitles = db.SubmissionSectionScores.Select(s => s.SectionTitle).Distinct().ToList();
            foreach (var title in distinctTitles)
            {
                sw.WriteLine($"Distinct Title: '{title}'");
            }
        }
        catch (Exception ex)
        {
            sw.WriteLine($"ERROR: {ex.Message}");
            sw.WriteLine(ex.StackTrace);
        }

        sw.Flush();
    }
}
