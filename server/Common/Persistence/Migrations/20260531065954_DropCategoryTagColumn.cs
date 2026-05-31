using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class DropCategoryTagColumn : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "category_tag",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "category_tag",
                table: "submissions");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "category_tag",
                table: "templates",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "category_tag",
                table: "submissions",
                type: "text",
                nullable: true);
        }
    }
}
