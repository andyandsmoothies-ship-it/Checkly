using System;
using Npgsql;

Console.WriteLine("=== QUERYING REAL DATABASE (RAW NPGSQL) ===");

var connString = "Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@";

using var conn = new NpgsqlConnection(connString);
try
{
    conn.Open();
    Console.WriteLine("Connected successfully!");

    // 1. Submissions
    using (var cmd = new NpgsqlCommand("SELECT id, status, store_name, total_score FROM submissions", conn))
    using (var reader = cmd.ExecuteReader())
    {
        Console.WriteLine("\nSubmissions:");
        while (reader.Read())
        {
            Console.WriteLine($" - ID: {reader.GetValue(0)}, Store: '{reader.GetValue(2)}', Status: '{reader.GetValue(1)}', Score: {reader.GetValue(3)}");
        }
    }

    // 2. SubmissionSectionScores
    using (var cmd = new NpgsqlCommand("SELECT submission_id, section_title, score, max_score FROM submission_section_scores", conn))
    using (var reader = cmd.ExecuteReader())
    {
        Console.WriteLine("\nSubmissionSectionScores:");
        while (reader.Read())
        {
            Console.WriteLine($" - SubmissionID: {reader.GetValue(0)}, Title: '{reader.GetValue(1)}', Score: {reader.GetValue(2)}, Max: {reader.GetValue(3)}");
        }
    }

    // 3. StoreAnalyticsSnapshots
    using (var cmd = new NpgsqlCommand("SELECT store_id, category_scores FROM store_analytics_snapshots", conn))
    using (var reader = cmd.ExecuteReader())
    {
        Console.WriteLine("\nStoreAnalyticsSnapshots:");
        while (reader.Read())
        {
            Console.WriteLine($" - StoreID: {reader.GetValue(0)}, CategoryScores: {reader.GetValue(1)}");
        }
    }
}
catch (Exception ex)
{
    Console.WriteLine("ERROR: " + ex);
}
