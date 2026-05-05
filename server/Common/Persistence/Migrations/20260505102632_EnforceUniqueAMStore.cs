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

            // Clean up existing duplicates before applying unique constraint
            migrationBuilder.Sql(@"
                DELETE FROM profile_store_assignments
                WHERE (profile_id, store_id) NOT IN (
                    SELECT profile_id, store_id
                    FROM (
                        SELECT profile_id, store_id,
                        ROW_NUMBER() OVER(PARTITION BY store_id ORDER BY created_at DESC) as rn
                        FROM profile_store_assignments
                    ) t
                    WHERE t.rn = 1
                );
            ");

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
