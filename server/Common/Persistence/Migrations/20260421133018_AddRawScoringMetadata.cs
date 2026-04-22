using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRawScoringMetadata : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<bool>(
                name: "is_weighted",
                table: "submissions",
                type: "boolean",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "raw_earned_points",
                table: "submissions",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "raw_max_points",
                table: "submissions",
                type: "numeric",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "is_weighted",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "raw_earned_points",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "raw_max_points",
                table: "submissions");
        }
    }
}
