using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Npgsql;
using Microsoft.EntityFrameworkCore;
using Checkly.Api.Common.Persistence;
using Checkly.Api.Common.Persistence.Entities;
using Checkly.Api.Features.Analytics;

class Program {
    static async Task Main() {
        var connStr = "Host=localhost;Port=5432;Database=checkly;Username=postgres;Password=Aa1234567@";
        using var conn = new NpgsqlConnection(connStr);
        await conn.OpenAsync();

        using var trans = await conn.BeginTransactionAsync();

        try {
            Console.WriteLine("Cleaning existing historical submissions, section scores, and assignments to prevent duplicate key/foreign key issues...");
            
            using (var cmd = new NpgsqlCommand("DELETE FROM action_plans", conn, trans)) {
                int count = await cmd.ExecuteNonQueryAsync();
                Console.WriteLine($"Deleted {count} action plans.");
            }

            using (var cmd = new NpgsqlCommand("DELETE FROM submission_section_scores", conn, trans)) {
                int count = await cmd.ExecuteNonQueryAsync();
                Console.WriteLine($"Deleted {count} submission section scores.");
            }

            using (var cmd = new NpgsqlCommand("DELETE FROM submissions", conn, trans)) {
                int count = await cmd.ExecuteNonQueryAsync();
                Console.WriteLine($"Deleted {count} submissions.");
            }

            using (var cmd = new NpgsqlCommand("DELETE FROM program_assignments", conn, trans)) {
                int count = await cmd.ExecuteNonQueryAsync();
                Console.WriteLine($"Deleted {count} program assignments.");
            }

            using (var cmd = new NpgsqlCommand("DELETE FROM programs", conn, trans)) {
                int count = await cmd.ExecuteNonQueryAsync();
                Console.WriteLine($"Deleted {count} programs.");
            }

            // Retrieve active stores
            var stores = new List<(Guid id, string name)>();
            using (var cmd = new NpgsqlCommand("SELECT id, name FROM stores WHERE is_active = true", conn, trans))
            using (var reader = await cmd.ExecuteReaderAsync()) {
                while (await reader.ReadAsync()) {
                    stores.Add((reader.GetGuid(0), reader.GetString(1)));
                }
            }
            Console.WriteLine($"Loaded {stores.Count} active stores.");

            // Template metadata
            Guid templateId = Guid.Parse("d1c26713-d9fe-4550-bca2-7608f969eb1d");
            string templateTitle = "Basic checklist";
            string templateType = "qc";

            // Auditor metadata (Auditor 1 and Auditor 2)
            var auditors = new List<(Guid id, string name, string email)> {
                (Guid.Parse("2630946e-8eb7-4836-ace8-33129ff7885b"), "Auditor 1", "auditor1@checkly.local"),
                (Guid.Parse("88e81a53-2ed0-40b4-90c5-95c652466bfe"), "Auditor 2", "auditor2@checkly.local")
            };

            // Admin metadata for creation
            Guid adminId = Guid.Parse("48d8d98b-1bed-4902-8969-34350923d00b");

            // Months configuration (January to May 2026)
            var months = new[] {
                new { Month = 1, Year = 2026, ProgramTitle = "New Year Compliance Drive", ProgramCategory = "Operational" },
                new { Month = 2, Year = 2026, ProgramTitle = "Lunar New Year Special", ProgramCategory = "Operational" },
                new { Month = 3, Year = 2026, ProgramTitle = "Spring Operational Audit", ProgramCategory = "Operational" },
                new { Month = 4, Year = 2026, ProgramTitle = "Quarter 2 Standards Review", ProgramCategory = "Operational" },
                new { Month = 5, Year = 2026, ProgramTitle = "Summer Readiness Check", ProgramCategory = "Operational" }
            };

            var rand = new Random(42); // Seeded for deterministic results

            int programCount = 0;
            int assignmentCount = 0;
            int submissionCount = 0;
            int scoreCount = 0;
            int apCount = 0;

            foreach (var m in months) {
                // 1. Create a ChecklyProgram for this month
                Guid programId = Guid.NewGuid();
                DateTimeOffset programCreatedAt = new DateTimeOffset(m.Year, m.Month, 1, 8, 0, 0, TimeSpan.Zero);
                DateTimeOffset programDeadline = new DateTimeOffset(m.Year, m.Month, 28, 23, 59, 59, TimeSpan.Zero);
                
                string insertProgramSql = @"
                    INSERT INTO programs (id, template_id, title, category, deadline, status, created_by, created_at, updated_at)
                    VALUES (@id, @template_id, @title, @category, @deadline, 'completed', @created_by, @created_at, @updated_at)";
                
                using (var cmd = new NpgsqlCommand(insertProgramSql, conn, trans)) {
                    cmd.Parameters.AddWithValue("id", programId);
                    cmd.Parameters.AddWithValue("template_id", templateId);
                    cmd.Parameters.AddWithValue("title", m.ProgramTitle);
                    cmd.Parameters.AddWithValue("category", m.ProgramCategory);
                    cmd.Parameters.AddWithValue("deadline", programDeadline);
                    cmd.Parameters.AddWithValue("created_by", adminId);
                    cmd.Parameters.AddWithValue("created_at", programCreatedAt);
                    cmd.Parameters.AddWithValue("updated_at", programCreatedAt);
                    await cmd.ExecuteNonQueryAsync();
                }
                programCount++;

                // 2. Loop stores to assign program assignments and create submissions
                for (int i = 0; i < stores.Count; i++) {
                    var store = stores[i];

                    // Generate a ProgramAssignment
                    Guid assignmentId = Guid.NewGuid();
                    DateTimeOffset assignmentCreatedAt = programCreatedAt.AddDays(1);
                    DateTimeOffset assignmentCompletedAt = programCreatedAt.AddDays(15);
                    DateTimeOffset assignmentVerifiedAt = programCreatedAt.AddDays(20);

                    string insertAssignmentSql = @"
                        INSERT INTO program_assignments (id, program_id, store_id, assigned_by_id, assignee_id, status, completed_at, created_at, updated_at, rejection_comment, verified_at)
                        VALUES (@id, @program_id, @store_id, @assigned_by_id, NULL, 'verified', @completed_at, @created_at, @updated_at, NULL, @verified_at)";
                    
                    using (var cmd = new NpgsqlCommand(insertAssignmentSql, conn, trans)) {
                        cmd.Parameters.AddWithValue("id", assignmentId);
                        cmd.Parameters.AddWithValue("program_id", programId);
                        cmd.Parameters.AddWithValue("store_id", store.id);
                        cmd.Parameters.AddWithValue("assigned_by_id", adminId);
                        cmd.Parameters.AddWithValue("completed_at", assignmentCompletedAt);
                        cmd.Parameters.AddWithValue("created_at", assignmentCreatedAt);
                        cmd.Parameters.AddWithValue("updated_at", assignmentVerifiedAt);
                        cmd.Parameters.AddWithValue("verified_at", assignmentVerifiedAt);
                        await cmd.ExecuteNonQueryAsync();
                    }
                    assignmentCount++;

                    // Determine submission count per store per month (2 or 3 submissions)
                    int numSubmissions = (i % 2 == 0) ? 2 : 3;

                    for (int sNum = 0; sNum < numSubmissions; sNum++) {
                        Guid submissionId = Guid.NewGuid();
                        
                        // First submission of the month is linked to the program campaign assignment
                        Guid? linkedAssignmentId = (sNum == 0) ? assignmentId : (Guid?)null;

                        // Distribute submission completed dates nicely across the month
                        int dayOfSubmission = 5 + (sNum * 8) + rand.Next(0, 3);
                        DateTimeOffset completedAt = new DateTimeOffset(m.Year, m.Month, dayOfSubmission, 10 + rand.Next(0, 5), rand.Next(0, 60), 0, TimeSpan.Zero);
                        DateTimeOffset createdAt = completedAt.AddHours(-1);
                        DateTimeOffset startedAt = completedAt.AddMinutes(-45);

                        var auditor = auditors[rand.Next(auditors.Count)];

                        // Random score between 75.0 and 98.0
                        decimal totalScore = Math.Round((decimal)(75.0 + rand.NextDouble() * 23.0), 1);

                        string insertSubmissionSql = @"
                            INSERT INTO submissions (
                                id, program_assignment_id, template_id, auditor_id, store_id, status, scoring_mode, total_score, 
                                section_scores, gps_lat, gps_lng, gps_verified_at, notes, scheduled_at, completed_at, 
                                approved_by, approved_at, created_at, updated_at, started_at, auditor_name, auditor_email, 
                                store_name, template_title, template_type, display_noun, approver_name, review_status, 
                                template_snapshot, template_version, raw_earned_points, raw_max_points, is_weighted, 
                                void_reason, voided_at
                            ) VALUES (
                                @id, @program_assignment_id, @template_id, @auditor_id, @store_id, 'completed', 'penalty', @total_score,
                                NULL, 10.7769, 106.7009, @completed_at, 'Historical compliance audit.', @created_at, @completed_at,
                                @approved_by, @completed_at, @created_at, @completed_at, @started_at, @auditor_name, @auditor_email,
                                @store_name, @template_title, @template_type, 'Audit', 'System Admin', 'approved',
                                NULL, 1, @total_score, 100.0, false,
                                NULL, NULL
                            )";

                        using (var cmd = new NpgsqlCommand(insertSubmissionSql, conn, trans)) {
                            cmd.Parameters.AddWithValue("id", submissionId);
                            cmd.Parameters.AddWithValue("program_assignment_id", linkedAssignmentId.HasValue ? (object)linkedAssignmentId.Value : DBNull.Value);
                            cmd.Parameters.AddWithValue("template_id", templateId);
                            cmd.Parameters.AddWithValue("auditor_id", auditor.id);
                            cmd.Parameters.AddWithValue("store_id", store.id);
                            cmd.Parameters.AddWithValue("total_score", totalScore);
                            cmd.Parameters.AddWithValue("completed_at", completedAt);
                            cmd.Parameters.AddWithValue("created_at", createdAt);
                            cmd.Parameters.AddWithValue("approved_by", adminId);
                            cmd.Parameters.AddWithValue("started_at", startedAt);
                            cmd.Parameters.AddWithValue("auditor_name", auditor.name);
                            cmd.Parameters.AddWithValue("auditor_email", auditor.email);
                            cmd.Parameters.AddWithValue("store_name", store.name);
                            cmd.Parameters.AddWithValue("template_title", templateTitle);
                            cmd.Parameters.AddWithValue("template_type", templateType);
                            await cmd.ExecuteNonQueryAsync();
                        }
                        submissionCount++;

                        // 3. Create Submission Section Scores (Opening Tasks, Closing Tasks, Daily Operations)
                        var sections = new[] { "Opening Tasks", "Closing Tasks", "Daily Operations" };
                        foreach (var sec in sections) {
                            Guid secScoreId = Guid.NewGuid();
                            
                            // Section score fluctuates slightly around the total score
                            decimal secScoreVal = totalScore + (decimal)(rand.NextDouble() * 8.0 - 4.0);
                            if (secScoreVal > 100m) secScoreVal = 100m;
                            if (secScoreVal < 50m) secScoreVal = 50m;
                            secScoreVal = Math.Round(secScoreVal, 1);

                            string insertSecSql = @"
                                INSERT INTO submission_section_scores (id, submission_id, store_id, template_id, section_title, score, max_score, ratio, is_ccp_failed, weight, created_at)
                                VALUES (@id, @submission_id, @store_id, @template_id, @section_title, @score, 100.0, @ratio, false, 1.0, @created_at)";

                            using (var cmd = new NpgsqlCommand(insertSecSql, conn, trans)) {
                                cmd.Parameters.AddWithValue("id", secScoreId);
                                cmd.Parameters.AddWithValue("submission_id", submissionId);
                                cmd.Parameters.AddWithValue("store_id", store.id);
                                cmd.Parameters.AddWithValue("template_id", templateId);
                                cmd.Parameters.AddWithValue("section_title", sec);
                                cmd.Parameters.AddWithValue("score", secScoreVal);
                                cmd.Parameters.AddWithValue("ratio", secScoreVal / 100m);
                                cmd.Parameters.AddWithValue("created_at", completedAt);
                                await cmd.ExecuteNonQueryAsync();
                            }
                            scoreCount++;
                        }

                        // 4. Create an Action Plan if score < 85% to populate the Action Plan lists/KPIs realistically
                        if (totalScore < 85m && rand.NextDouble() > 0.3) {
                            Guid apId = Guid.NewGuid();
                            string criteria = "Required sanitization checklists not fully updated.";
                            string sectionName = "Daily Operations";
                            string description = "Update store cleaning logs daily and verify sanitization logs.";
                            string status = "open";
                            DateTimeOffset apDeadline = completedAt.AddDays(30);

                            string insertApSql = @"
                                INSERT INTO action_plans (
                                    id, answer_id, submission_id, store_id, store_manager_id, criteria_label, group_title, 
                                    plan_description, evidence_photo_url, evidence_note, status, deadline, closed_at, 
                                    verified_by, verified_at, created_at, updated_at, root_cause, correction_plan, 
                                    store_name, store_manager_name, verifier_name, evidence_submitted_at, 
                                    evidence_submitted_by_name
                                ) VALUES (
                                    @id, NULL, @submission_id, @store_id, NULL, @criteria_label, @group_title,
                                    @plan_description, NULL, NULL, @status, @deadline, NULL,
                                    NULL, NULL, @created_at, @created_at, NULL, NULL,
                                    @store_name, NULL, NULL, NULL, NULL
                                )";

                            using (var cmd = new NpgsqlCommand(insertApSql, conn, trans)) {
                                cmd.Parameters.AddWithValue("id", apId);
                                cmd.Parameters.AddWithValue("submission_id", submissionId);
                                cmd.Parameters.AddWithValue("store_id", store.id);
                                cmd.Parameters.AddWithValue("criteria_label", criteria);
                                cmd.Parameters.AddWithValue("group_title", sectionName);
                                cmd.Parameters.AddWithValue("plan_description", description);
                                cmd.Parameters.AddWithValue("status", status);
                                cmd.Parameters.AddWithValue("deadline", apDeadline);
                                cmd.Parameters.AddWithValue("created_at", completedAt);
                                cmd.Parameters.AddWithValue("store_name", store.name);
                                await cmd.ExecuteNonQueryAsync();
                            }
                            apCount++;
                        }
                    }
                }
            }

            await trans.CommitAsync();

            // Seeding the BOD Report Snapshot so the global board doesn't show old data
            Console.WriteLine("Calculating real BOD Report Snapshot from seeded database records using BodReportCalculator...");
            
            var dbOptions = new DbContextOptionsBuilder<AppDbContext>()
                .UseNpgsql(connStr)
                .Options;

            using (var dbContext = new AppDbContext(dbOptions))
            {
                var calculator = new BodReportCalculator();
                var snapshotDate = new DateOnly(2026, 5, 25);
                
                // Let's first delete any existing snapshot for this date using DbContext
                var existingSnapshots = dbContext.BodReportSnapshots.Where(x => x.Date == snapshotDate).ToList();
                if (existingSnapshots.Any())
                {
                    dbContext.BodReportSnapshots.RemoveRange(existingSnapshots);
                    await dbContext.SaveChangesAsync();
                }

                // Compute real daily report
                Console.WriteLine("Computing report payload dynamically...");
                string realPayload = await calculator.ComputeDailyReportAsync(dbContext, snapshotDate, System.Threading.CancellationToken.None);
                
                // Insert calculated snapshot
                var snapshot = new BodReportSnapshot
                {
                    Id = Guid.NewGuid(),
                    Date = snapshotDate,
                    ComputedAt = DateTimeOffset.UtcNow,
                    Status = "Complete",
                    Payload = realPayload
                };
                
                dbContext.BodReportSnapshots.Add(snapshot);
                await dbContext.SaveChangesAsync();
                
                Console.WriteLine("BOD Report Snapshot computed and saved successfully!");
                
                // Also write the computed payload back to snapshot_payload.json so the static file stays up-to-date
                string jsonPath = "snapshot_payload.json";
                if (!Directory.Exists("dbquery") && File.Exists(Path.Combine("..", "dbquery", "snapshot_payload.json")))
                {
                    jsonPath = Path.Combine("..", "dbquery", "snapshot_payload.json");
                }
                await File.WriteAllTextAsync(jsonPath, realPayload);
                Console.WriteLine($"Updated {jsonPath} with latest calculated payload!");
            }

            Console.WriteLine("\n--- DATABASE BACKFILL COMPLETED SUCCESSFULLY ---");
            Console.WriteLine($"Inserted Checkly Programs (Compliance Campaigns): {programCount}");
            Console.WriteLine($"Inserted Program Assignments (Campaign Tasks): {assignmentCount}");
            Console.WriteLine($"Inserted Submissions (Completed Audits): {submissionCount}");
            Console.WriteLine($"Inserted Submission Section Scores: {scoreCount}");
            Console.WriteLine($"Inserted Action Plans: {apCount}");
            Console.WriteLine("-----------------------------------------------");
        }
        catch (Exception ex) {
            await trans.RollbackAsync();
            Console.WriteLine($"ERROR: Backfill transaction rolled back. Details: {ex}");
        }
    }
}
