using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddDisplayNoun : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "display_noun",
                table: "templates",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "display_noun",
                table: "submissions",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "display_noun",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "display_noun",
                table: "submissions");
        }
    }
}
