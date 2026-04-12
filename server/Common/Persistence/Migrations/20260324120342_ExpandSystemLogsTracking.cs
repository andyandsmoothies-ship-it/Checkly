using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class ExpandSystemLogsTracking : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "trace_id",
                table: "system_logs",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "user_email",
                table: "system_logs",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "trace_id",
                table: "system_logs");

            migrationBuilder.DropColumn(
                name: "user_email",
                table: "system_logs");
        }
    }
}
