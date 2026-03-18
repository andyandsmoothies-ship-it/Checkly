using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddSubmissionCompositeIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_submissions_store_id",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_template_id",
                table: "submissions");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_store_id_created_at",
                table: "submissions",
                columns: new[] { "store_id", "created_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_submissions_template_id_scoring_mode",
                table: "submissions",
                columns: new[] { "template_id", "scoring_mode" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_submissions_store_id_created_at",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_template_id_scoring_mode",
                table: "submissions");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_store_id",
                table: "submissions",
                column: "store_id");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_template_id",
                table: "submissions",
                column: "template_id");
        }
    }
}
