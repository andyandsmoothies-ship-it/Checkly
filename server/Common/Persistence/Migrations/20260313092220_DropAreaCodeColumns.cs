using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class DropAreaCodeColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_stores_area_code",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "area_code",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "area_code",
                table: "profiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "area_code",
                table: "stores",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "area_code",
                table: "profiles",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_stores_area_code",
                table: "stores",
                column: "area_code");
        }
    }
}
