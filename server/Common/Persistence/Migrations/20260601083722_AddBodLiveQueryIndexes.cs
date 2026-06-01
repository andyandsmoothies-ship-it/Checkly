using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBodLiveQueryIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_submissions_status_completed_at",
                table: "submissions",
                columns: new[] { "status", "completed_at" },
                descending: new[] { false, true });

            migrationBuilder.CreateIndex(
                name: "IX_submissions_status_store_id_completed_at",
                table: "submissions",
                columns: new[] { "status", "store_id", "completed_at" });

            migrationBuilder.CreateIndex(
                name: "IX_submission_section_scores_created_at_store_id",
                table: "submission_section_scores",
                columns: new[] { "created_at", "store_id" });

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_status_deadline",
                table: "action_plans",
                columns: new[] { "status", "deadline" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_submissions_status_completed_at",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_status_store_id_completed_at",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submission_section_scores_created_at_store_id",
                table: "submission_section_scores");

            migrationBuilder.DropIndex(
                name: "IX_action_plans_status_deadline",
                table: "action_plans");
        }
    }
}
