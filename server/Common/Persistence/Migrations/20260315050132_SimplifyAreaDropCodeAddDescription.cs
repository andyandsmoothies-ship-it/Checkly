using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SimplifyAreaDropCodeAddDescription : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_areas_code",
                table: "areas");

            migrationBuilder.DropColumn(
                name: "code",
                table: "areas");

            migrationBuilder.AddColumn<string>(
                name: "description",
                table: "areas",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "description",
                table: "areas");

            migrationBuilder.AddColumn<string>(
                name: "code",
                table: "areas",
                type: "text",
                nullable: false,
                defaultValue: "");

            migrationBuilder.CreateIndex(
                name: "IX_areas_code",
                table: "areas",
                column: "code",
                unique: true);
        }
    }
}
