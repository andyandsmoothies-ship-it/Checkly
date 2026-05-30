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
        var logFile = Path.Combine(logDir, "db_inspection.txt");

        using var writer = new StreamWriter(logFile, false, Encoding.UTF8);

        await writer.WriteLineAsync("=== TEMPLATES ===");
        using (var cmd = new NpgsqlCommand("SELECT id, title, type, scoring_logic_config FROM templates ORDER BY title", conn))
        using (var reader = await cmd.ExecuteReaderAsync()) {
            while (await reader.ReadAsync()) {
                var id = reader.GetGuid(0);
                var title = reader.GetString(1);
                var type = reader.IsDBNull(2) ? "NULL" : reader.GetString(2);
                var scoringConfig = reader.IsDBNull(3) ? "NULL" : reader.GetString(3);
                await writer.WriteLineAsync($"Template ID: {id} | Title: {title} | Type: {type} | ScoringConfig: {scoringConfig}");
            }
        }

        await writer.WriteLineAsync("\n=== SUBMISSIONS ===");
        using (var cmd = new NpgsqlCommand("SELECT id, template_id, total_score, section_scores, review_status, created_at FROM submissions ORDER BY created_at DESC", conn))
        using (var reader = await cmd.ExecuteReaderAsync()) {
            while (await reader.ReadAsync()) {
                var id = reader.GetGuid(0);
                var templateId = reader.IsDBNull(1) ? Guid.Empty : reader.GetGuid(1);
                var score = reader.IsDBNull(2) ? -1 : reader.GetDecimal(2);
                var sectionScores = reader.IsDBNull(3) ? "NULL" : reader.GetString(3);
                var status = reader.IsDBNull(4) ? "NULL" : reader.GetString(4);
                var createdAt = reader.GetDateTime(5);
                await writer.WriteLineAsync($"Submission ID: {id} | Template: {templateId} | Score: {score} | SectionScores: {sectionScores} | Status: {status} | CreatedAt: {createdAt}");
            }
        }

        await writer.WriteLineAsync("\n=== ANSWERS ===");
        using (var cmd = new NpgsqlCommand(@"
            SELECT a.id, a.submission_id, a.criteria_id, a.value, a.numeric_value, a.repeated_faults, c.label, c.points_weight
            FROM answers a
            JOIN criteria c ON a.criteria_id = c.id
            ORDER BY a.submission_id", conn))
        using (var reader = await cmd.ExecuteReaderAsync()) {
            while (await reader.ReadAsync()) {
                var id = reader.GetGuid(0);
                var subId = reader.GetGuid(1);
                var critId = reader.GetGuid(2);
                var val = reader.IsDBNull(3) ? "NULL" : reader.GetString(3);
                var numVal = reader.IsDBNull(4) ? -1 : reader.GetInt32(4);
                var repFaults = reader.IsDBNull(5) ? -1 : reader.GetInt32(5);
                var label = reader.IsDBNull(6) ? "NULL" : reader.GetString(6);
                var ptsWeight = reader.IsDBNull(7) ? -1 : reader.GetDecimal(7);
                await writer.WriteLineAsync($"Answer ID: {id} | Sub: {subId} | Crit: {critId} ({label}) | Val: {val} | NumVal: {numVal} | RepFaults: {repFaults} | Weight: {ptsWeight}");
            }
        }

        await writer.WriteLineAsync("\n=== CRITERIA DETAILS ===");
        using (var cmd = new NpgsqlCommand(@"
            SELECT c.id, c.group_id, c.label, c.points_weight, c.minus_impact, c.is_ccp, c.input_type
            FROM criteria c", conn))
        using (var reader = await cmd.ExecuteReaderAsync()) {
            while (await reader.ReadAsync()) {
                var id = reader.GetGuid(0);
                var groupId = reader.GetGuid(1);
                var label = reader.GetString(2);
                var weight = reader.IsDBNull(3) ? -1 : reader.GetDecimal(3);
                var minus = reader.IsDBNull(4) ? -1 : reader.GetDecimal(4);
                var isCcp = reader.IsDBNull(5) ? "false" : reader.GetBoolean(5).ToString();
                var inputType = reader.IsDBNull(6) ? "NULL" : reader.GetString(6);
                await writer.WriteLineAsync($"Crit ID: {id} | Group: {groupId} | Label: {label} | Weight: {weight} | Minus: {minus} | CCP: {isCcp} | Type: {inputType}");
            }
        }

        Console.WriteLine($"Inspection complete. Output saved to {logFile}");
    }
}

