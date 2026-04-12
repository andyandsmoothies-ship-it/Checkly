using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddIsActiveFilteredIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_templates_is_active",
                table: "templates",
                column: "is_active",
                filter: "is_active = true");

            migrationBuilder.CreateIndex(
                name: "IX_groups_is_active",
                table: "groups",
                column: "is_active",
                filter: "is_active = true");

            migrationBuilder.CreateIndex(
                name: "IX_criteria_is_active",
                table: "criteria",
                column: "is_active",
                filter: "is_active = true");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_templates_is_active",
                table: "templates");

            migrationBuilder.DropIndex(
                name: "IX_groups_is_active",
                table: "groups");

            migrationBuilder.DropIndex(
                name: "IX_criteria_is_active",
                table: "criteria");
        }
    }
}
