using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class EnforceUniqueAMStore : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_profile_store_assignments_store_id",
                table: "profile_store_assignments");

            migrationBuilder.CreateIndex(
                name: "IX_profile_store_assignments_store_id",
                table: "profile_store_assignments",
                column: "store_id",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_profile_store_assignments_store_id",
                table: "profile_store_assignments");

            migrationBuilder.CreateIndex(
                name: "IX_profile_store_assignments_store_id",
                table: "profile_store_assignments",
                column: "store_id");
        }
    }
}
