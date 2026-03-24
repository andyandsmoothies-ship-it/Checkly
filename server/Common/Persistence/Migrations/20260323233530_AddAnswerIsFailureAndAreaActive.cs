using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAnswerIsFailureAndAreaActive : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<decimal>(
                name: "weight",
                table: "groups",
                type: "numeric",
                nullable: true,
                oldClrType: typeof(decimal),
                oldType: "numeric",
                oldNullable: true,
                oldDefaultValue: 1.0m);

            migrationBuilder.AddColumn<bool>(
                name: "is_active",
                table: "areas",
                type: "boolean",
                nullable: false,
                defaultValue: true);

            migrationBuilder.AddColumn<bool>(
                name: "is_failure",
                table: "answers",
                type: "boolean",
                nullable: false,
                defaultValue: false);

            migrationBuilder.CreateIndex(
                name: "IX_answers_is_failure_criteria_id",
                table: "answers",
                columns: new[] { "is_failure", "criteria_id" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_answers_is_failure_criteria_id",
                table: "answers");

            migrationBuilder.DropColumn(
                name: "is_active",
                table: "areas");

            migrationBuilder.DropColumn(
                name: "is_failure",
                table: "answers");

            migrationBuilder.AlterColumn<decimal>(
                name: "weight",
                table: "groups",
                type: "numeric",
                nullable: true,
                defaultValue: 1.0m,
                oldClrType: typeof(decimal),
                oldType: "numeric",
                oldNullable: true);
        }
    }
}
