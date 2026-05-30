using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddScoringDirectionAndCategoryTag : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_submissions_template_id_scoring_mode",
                table: "submissions");

            migrationBuilder.AddColumn<string>(
                name: "category_tag",
                table: "templates",
                type: "text",
                nullable: true);

            migrationBuilder.AlterColumn<string>(
                name: "scoring_mode",
                table: "submissions",
                type: "text",
                nullable: true,
                defaultValue: "penalty",
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "penalty");

            migrationBuilder.AddColumn<string>(
                name: "category_tag",
                table: "submissions",
                type: "text",
                nullable: true);

            // Add score_direction as nullable first
            migrationBuilder.AddColumn<string>(
                name: "score_direction",
                table: "submissions",
                type: "character varying(20)",
                maxLength: 20,
                nullable: true);

            // Backfill score_direction based on scoring_mode
            migrationBuilder.Sql(@"
                UPDATE submissions
                SET score_direction = CASE COALESCE(scoring_mode, 'penalty')
                    WHEN 'accumulation' THEN 'up'
                    WHEN 'survey'       THEN 'none'
                    ELSE 'down'
                END;
            ");

            // Backfill is_weighted (penalty -> true, others -> false)
            migrationBuilder.Sql(@"
                UPDATE submissions
                SET is_weighted = CASE WHEN COALESCE(scoring_mode, 'penalty') = 'penalty' THEN true ELSE false END
                WHERE is_weighted IS NULL;
            ");

            // Backfill category_tag to 'routine' for existing records
            migrationBuilder.Sql(@"
                UPDATE submissions
                SET category_tag = 'routine'
                WHERE category_tag IS NULL;
            ");

            migrationBuilder.Sql(@"
                UPDATE templates
                SET category_tag = 'routine'
                WHERE category_tag IS NULL;
            ");

            // Alter score_direction to be non-nullable with default 'down'
            migrationBuilder.AlterColumn<string>(
                name: "score_direction",
                table: "submissions",
                type: "character varying(20)",
                maxLength: 20,
                nullable: false,
                defaultValue: "down",
                oldClrType: typeof(string),
                oldType: "character varying(20)",
                oldMaxLength: 20,
                oldNullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_submissions_template_id_score_direction",
                table: "submissions",
                columns: new[] { "template_id", "score_direction" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_submissions_template_id_score_direction",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "category_tag",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "category_tag",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "score_direction",
                table: "submissions");

            migrationBuilder.AlterColumn<string>(
                name: "scoring_mode",
                table: "submissions",
                type: "text",
                nullable: false,
                defaultValue: "penalty",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true,
                oldDefaultValue: "penalty");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_template_id_scoring_mode",
                table: "submissions",
                columns: new[] { "template_id", "scoring_mode" });
        }
    }
}
