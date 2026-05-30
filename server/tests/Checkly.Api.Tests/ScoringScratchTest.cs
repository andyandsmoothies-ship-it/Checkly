using System;
using System.IO;
using System.Text;
using Npgsql;
using Xunit;

namespace Checkly.Api.Tests;

public class ScoringScratchTest
{
    [Fact]
    public void InspectTaskforceTemplates()
    {
        var logDir = @"c:\Users\HP\Documents\GitHub\Checkly\.agents\logs";
        if (!Directory.Exists(logDir))
        {
            Directory.CreateDirectory(logDir);
        }
        var logFile = Path.Combine(logDir, "db_inspection.txt");
        using var writer = new StreamWriter(logFile, false, Encoding.UTF8);

        var dbs = new[] { "checkly", "checkly_test" };
        foreach (var db in dbs)
        {
            writer.WriteLine($"==================== DATABASE: {db} ====================");
            try
            {
                var connStr = $"Host=localhost;Port=5432;Database={db};Username=postgres;Password=Aa1234567@";
                using var conn = new NpgsqlConnection(connStr);
                conn.Open();

                writer.WriteLine("--- templates ---");
                using (var cmd = new NpgsqlCommand("SELECT id, title, type, scoring_logic_config FROM templates WHERE title ILIKE '%task%' OR type ILIKE '%task%'", conn))
                using (var reader = cmd.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var id = reader.GetGuid(0);
                        var title = reader.GetString(1);
                        var type = reader.IsDBNull(2) ? "NULL" : reader.GetString(2);
                        var config = reader.IsDBNull(3) ? "NULL" : reader.GetString(3);
                        writer.WriteLine($"Template ID: {id} | Title: {title} | Type: {type} | Config: {config}");

                        // For each template, print groups and criteria
                        using var conn2 = new NpgsqlConnection(connStr);
                        conn2.Open();
                        using var cmd2 = new NpgsqlCommand("SELECT id, title, weight, parent_id, max_deduction_points FROM groups WHERE template_id = @tid ORDER BY parent_id NULLS FIRST, title", conn2);
                        cmd2.Parameters.AddWithValue("tid", id);
                        using var reader2 = cmd2.ExecuteReader();
                        writer.WriteLine("  -- Groups --");
                        while (reader2.Read())
                        {
                            var gid = reader2.GetGuid(0);
                            var gtitle = reader2.IsDBNull(1) ? "NULL" : reader2.GetString(1);
                            var gweight = reader2.IsDBNull(2) ? "NULL" : reader2.GetDecimal(2).ToString();
                            var gpid = reader2.IsDBNull(3) ? "NULL" : reader2.GetGuid(3).ToString();
                            var gmax = reader2.IsDBNull(4) ? "NULL" : reader2.GetDecimal(4).ToString();
                            writer.WriteLine($"    Group ID: {gid} | Title: {gtitle} | Weight: {gweight} | Parent: {gpid} | MaxDeduction: {gmax}");

                            using var conn3 = new NpgsqlConnection(connStr);
                            conn3.Open();
                            using var cmd3 = new NpgsqlCommand("SELECT id, label, input_type, points_weight, minus_impact, max_deduction_points, is_ccp, is_risk FROM criteria WHERE group_id = @gid ORDER BY label", conn3);
                            cmd3.Parameters.AddWithValue("gid", gid);
                            using var reader3 = cmd3.ExecuteReader();
                            writer.WriteLine("      -- Criteria --");
                            while (reader3.Read())
                            {
                                var cid = reader3.GetGuid(0);
                                var clabel = reader3.IsDBNull(1) ? "NULL" : reader3.GetString(1);
                                var ctype = reader3.IsDBNull(2) ? "NULL" : reader3.GetString(2);
                                var cpw = reader3.IsDBNull(3) ? "NULL" : reader3.GetDecimal(3).ToString();
                                var cmi = reader3.IsDBNull(4) ? "NULL" : reader3.GetDecimal(4).ToString();
                                var cmax = reader3.IsDBNull(5) ? "NULL" : reader3.GetDecimal(5).ToString();
                                var cisccp = reader3.GetBoolean(6);
                                var cisrisk = reader3.GetBoolean(7);
                                writer.WriteLine($"        Crit ID: {cid} | Label: {clabel} | Type: {ctype} | PtsWeight: {cpw} | MinusImp: {cmi} | MaxDeduction: {cmax} | CCP: {cisccp} | Risk: {cisrisk}");
                            }
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                writer.WriteLine($"Error: {ex.Message}");
            }
            writer.WriteLine();
        }

        Assert.True(true);
    }
}
