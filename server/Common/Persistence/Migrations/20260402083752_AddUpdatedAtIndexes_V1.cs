using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddUpdatedAtIndexes_V1 : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateIndex(
                name: "IX_templates_updated_at",
                table: "templates",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_updated_at",
                table: "submissions",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_stores_updated_at",
                table: "stores",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_groups_updated_at",
                table: "groups",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_criteria_updated_at",
                table: "criteria",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_answers_updated_at",
                table: "answers",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_updated_at",
                table: "action_plans",
                column: "updated_at");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_templates_updated_at",
                table: "templates");

            migrationBuilder.DropIndex(
                name: "IX_submissions_updated_at",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_stores_updated_at",
                table: "stores");

            migrationBuilder.DropIndex(
                name: "IX_groups_updated_at",
                table: "groups");

            migrationBuilder.DropIndex(
                name: "IX_criteria_updated_at",
                table: "criteria");

            migrationBuilder.DropIndex(
                name: "IX_answers_updated_at",
                table: "answers");

            migrationBuilder.DropIndex(
                name: "IX_action_plans_updated_at",
                table: "action_plans");
        }
    }
}
