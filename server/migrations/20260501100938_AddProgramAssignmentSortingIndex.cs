using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.migrations
{
    /// <inheritdoc />
    public partial class AddProgramAssignmentSortingIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_program_assignments_program_id_created_at",
                table: "program_assignments",
                columns: new[] { "program_id", "created_at" },
                descending: new[] { false, true });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_program_assignments_program_id_created_at",
                table: "program_assignments");
        }
    }
}
