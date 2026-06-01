using System;
using System.IO;
using System.Text;
using System.Threading.Tasks;
using Npgsql;

class Program {
    static async Task Main() {
        var connStr = "Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@";
        using var conn = new NpgsqlConnection(connStr);
        await conn.OpenAsync();

        var logDir = @"c:\Users\HP\Documents\GitHub\Checkly\.agents\logs";
        if (!Directory.Exists(logDir)) {
            Directory.CreateDirectory(logDir);
        }
        var logFile = Path.Combine(logDir, "db_schema.txt");
        using var writer = new StreamWriter(logFile, false, Encoding.UTF8);

        await writer.WriteLineAsync("=== TABLES ===");
        using (var cmd = new NpgsqlCommand("SELECT table_name FROM information_schema.tables WHERE table_schema = 'public' ORDER BY table_name", conn))
        using (var reader = await cmd.ExecuteReaderAsync()) {
            while (await reader.ReadAsync()) {
                var tableName = reader.GetString(0);
                await writer.WriteLineAsync($"- Table: {tableName}");
            }
        }

        await writer.WriteLineAsync("\n=== COLUMNS FOR KEY TABLES ===");
        string[] tables = { "AspNetUsers", "profile_store_assignments", "stores", "submissions", "action_plans", "submission_section_scores" };
        foreach (var t in tables) {
            await writer.WriteLineAsync($"\nTable: {t}");
            using (var cmd = new NpgsqlCommand($"SELECT column_name, data_type FROM information_schema.columns WHERE table_name = '{t}' ORDER BY ordinal_position", conn))
            using (var reader = await cmd.ExecuteReaderAsync()) {
                while (await reader.ReadAsync()) {
                    var colName = reader.GetString(0);
                    var dataType = reader.GetString(1);
                    await writer.WriteLineAsync($"  * Column: {colName} ({dataType})");
                }
            }
        }

        Console.WriteLine($"Inspection complete. Output saved to {logFile}");
    }
}

