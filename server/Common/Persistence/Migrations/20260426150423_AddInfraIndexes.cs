using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddInfraIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_user_device_tokens_user_id",
                table: "user_device_tokens",
                column: "user_id");

            migrationBuilder.CreateIndex(
                name: "IX_areas_updated_at",
                table: "areas",
                column: "updated_at");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_user_device_tokens_user_id",
                table: "user_device_tokens");

            migrationBuilder.DropIndex(
                name: "IX_areas_updated_at",
                table: "areas");
        }
    }
}
