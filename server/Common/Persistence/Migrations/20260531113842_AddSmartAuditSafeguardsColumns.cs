using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSmartAuditSafeguardsColumns : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "geofence_mode",
                table: "templates",
                type: "text",
                nullable: false,
                defaultValue: "none");

            migrationBuilder.AddColumn<int>(
                name: "geofence_radius_meters",
                table: "templates",
                type: "integer",
                nullable: false,
                defaultValue: 100);

            migrationBuilder.AddColumn<int>(
                name: "distance_meters_off",
                table: "submissions",
                type: "integer",
                nullable: true);

            migrationBuilder.AddColumn<bool>(
                name: "is_geofence_bypassed",
                table: "submissions",
                type: "boolean",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "geofence_mode",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "geofence_radius_meters",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "distance_meters_off",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "is_geofence_bypassed",
                table: "submissions");
        }
    }
}
