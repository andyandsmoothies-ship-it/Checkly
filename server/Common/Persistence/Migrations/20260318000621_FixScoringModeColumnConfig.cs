using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class FixScoringModeColumnConfig : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "ScoringMode",
                table: "submissions",
                newName: "scoring_mode");

            migrationBuilder.AlterColumn<string>(
                name: "scoring_mode",
                table: "submissions",
                type: "text",
                nullable: false,
                defaultValue: "penalty",
                oldClrType: typeof(string),
                oldType: "text");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.RenameColumn(
                name: "scoring_mode",
                table: "submissions",
                newName: "ScoringMode");

            migrationBuilder.AlterColumn<string>(
                name: "ScoringMode",
                table: "submissions",
                type: "text",
                nullable: false,
                oldClrType: typeof(string),
                oldType: "text",
                oldDefaultValue: "penalty");
        }
    }
}
