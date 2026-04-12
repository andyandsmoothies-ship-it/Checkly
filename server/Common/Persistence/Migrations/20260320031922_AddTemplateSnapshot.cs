using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddTemplateSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "template_snapshot",
                table: "submissions",
                type: "jsonb",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "template_version",
                table: "submissions",
                type: "integer",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "template_snapshot",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "template_version",
                table: "submissions");
        }
    }
}
