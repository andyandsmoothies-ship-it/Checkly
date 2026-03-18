using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddScoringModeToSubmission : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // 1. Add scoring_mode column with default
            migrationBuilder.AddColumn<string>(
                name: "scoring_mode",
                table: "submissions",
                type: "text",
                nullable: false,
                defaultValue: "penalty");

            // 2. Add minus_per_fault to groups (picked up from entity)
            migrationBuilder.AddColumn<decimal>(
                name: "minus_per_fault",
                table: "groups",
                type: "numeric",
                nullable: true);

            // 3. Index on scoring_mode for fast filtering
            migrationBuilder.CreateIndex(
                name: "ix_submissions_scoring_mode",
                table: "submissions",
                column: "scoring_mode");

            // 4. GIN index on section_scores jsonb for drill-down queries
            migrationBuilder.Sql(
                "CREATE INDEX IF NOT EXISTS ix_submissions_section_scores_gin ON submissions USING GIN (section_scores jsonb_path_ops);");

            // 5. Backfill existing submissions from template scoring config
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
                name: "scoring_mode",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "minus_per_fault",
                table: "groups");
        }
    }
}
