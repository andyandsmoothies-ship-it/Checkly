using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddScoringModeAndDisplayNoun : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. DisplayNoun on templates (nullable, no backfill needed — derived at read time)
            migrationBuilder.AddColumn<string>(
                name: "display_noun",
                table: "templates",
                type: "text",
                nullable: true);

            // 2. DisplayNoun on submissions (snapshot, nullable)
            migrationBuilder.AddColumn<string>(
                name: "display_noun",
                table: "submissions",
                type: "text",
                nullable: true);

            // 3. ScoringMode on submissions (denormalized for analytics)
            migrationBuilder.AddColumn<string>(
                name: "scoring_mode",
                table: "submissions",
                type: "text",
                nullable: false,
                defaultValue: "penalty");

            // 4. MinusPerFault on groups (IF NOT EXISTS — may already be in DB)
            migrationBuilder.Sql(
                "ALTER TABLE groups ADD COLUMN IF NOT EXISTS minus_per_fault numeric;");

            // 5. Index on scoring_mode for fast filtering
            migrationBuilder.CreateIndex(
                name: "ix_submissions_scoring_mode",
                table: "submissions",
                column: "scoring_mode");

            // 6. GIN index on section_scores jsonb for drill-down queries
            migrationBuilder.Sql(
                "CREATE INDEX IF NOT EXISTS ix_submissions_section_scores_gin ON submissions USING GIN (section_scores jsonb_path_ops);");

            // 7. Backfill existing submissions from template scoring config
            migrationBuilder.Sql(@"
                UPDATE submissions s
                SET scoring_mode = COALESCE(
                    (SELECT t.scoring_logic_config::jsonb->>'scoringMode'
                     FROM templates t WHERE t.id = s.template_id),
                    'penalty'
                );
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(
                "DROP INDEX IF EXISTS ix_submissions_section_scores_gin;");

            migrationBuilder.DropIndex(
                name: "ix_submissions_scoring_mode",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "display_noun",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "display_noun",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "scoring_mode",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "minus_per_fault",
                table: "groups");
        }
    }
}
