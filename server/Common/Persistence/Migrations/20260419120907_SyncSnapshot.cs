using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SyncSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Idempotent guard: only rename the column if the old PascalCase name exists.
            // On fresh databases, AddSubmissionTemplateType already creates the column
            // with the correct snake_case name ("template_type"), so this is a no-op.
            migrationBuilder.Sql(@"
                DO $$
                BEGIN
                    IF EXISTS (
                        SELECT 1 FROM information_schema.columns
                        WHERE table_name = 'submissions' AND column_name = 'TemplateType'
                    ) THEN
                        ALTER TABLE submissions RENAME COLUMN ""TemplateType"" TO template_type;
                    END IF;
                END $$;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "template_type",
                table: "submissions",
                newName: "TemplateType");
        }
    }
}
