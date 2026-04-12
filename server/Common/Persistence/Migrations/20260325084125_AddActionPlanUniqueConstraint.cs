using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddActionPlanUniqueConstraint : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_action_plans_submission_id",
                table: "action_plans");

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_submission_id_answer_id",
                table: "action_plans",
                columns: new[] { "submission_id", "answer_id" },
                unique: true,
                filter: "submission_id IS NOT NULL AND answer_id IS NOT NULL");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_action_plans_submission_id_answer_id",
                table: "action_plans");

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_submission_id",
                table: "action_plans",
                column: "submission_id");
        }
    }
}
