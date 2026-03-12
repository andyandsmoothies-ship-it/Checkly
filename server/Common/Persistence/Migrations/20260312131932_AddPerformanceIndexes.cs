using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPerformanceIndexes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_profiles_AspNetUsers_id",
                table: "profiles");

            migrationBuilder.DropIndex(
                name: "IX_action_plans_store_id",
                table: "action_plans");

            migrationBuilder.AddColumn<uint>(
                name: "xmin",
                table: "templates",
                type: "xid",
                rowVersion: true,
                nullable: false,
                defaultValue: 0u);

            migrationBuilder.AddColumn<string>(
                name: "idempotency_key",
                table: "submissions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "minus_impact",
                table: "criteria",
                type: "numeric",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "repeated_faults",
                table: "answers",
                type: "integer",
                nullable: false,
                defaultValue: 0);

            migrationBuilder.CreateTable(
                name: "system_logs",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    user_id = table.Column<Guid>(type: "uuid", nullable: true),
                    action = table.Column<string>(type: "text", nullable: false),
                    category = table.Column<string>(type: "text", nullable: false),
                    message = table.Column<string>(type: "text", nullable: true),
                    path = table.Column<string>(type: "text", nullable: true),
                    level = table.Column<string>(type: "text", nullable: false, defaultValue: "info"),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_system_logs", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_submissions_auditor_id",
                table: "submissions",
                column: "auditor_id");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_created_at",
                table: "submissions",
                column: "created_at",
                descending: new bool[0]);

            migrationBuilder.CreateIndex(
                name: "IX_submissions_idempotency_key",
                table: "submissions",
                column: "idempotency_key",
                unique: true,
                filter: "idempotency_key IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_submissions_status_review_status",
                table: "submissions",
                columns: new[] { "status", "review_status" });

            migrationBuilder.CreateIndex(
                name: "IX_stores_area_code",
                table: "stores",
                column: "area_code");

            migrationBuilder.CreateIndex(
                name: "IX_stores_is_active",
                table: "stores",
                column: "is_active",
                filter: "is_active = true");

            migrationBuilder.CreateIndex(
                name: "IX_notifications_user_id_created_at",
                table: "notifications",
                columns: new[] { "user_id", "created_at" });

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_deadline",
                table: "action_plans",
                column: "deadline");

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_store_id_status",
                table: "action_plans",
                columns: new[] { "store_id", "status" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "system_logs");

            migrationBuilder.DropIndex(
                name: "IX_submissions_auditor_id",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_created_at",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_idempotency_key",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_status_review_status",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_stores_area_code",
                table: "stores");

            migrationBuilder.DropIndex(
                name: "IX_stores_is_active",
                table: "stores");

            migrationBuilder.DropIndex(
                name: "IX_notifications_user_id_created_at",
                table: "notifications");

            migrationBuilder.DropIndex(
                name: "IX_action_plans_deadline",
                table: "action_plans");

            migrationBuilder.DropIndex(
                name: "IX_action_plans_store_id_status",
                table: "action_plans");

            migrationBuilder.DropColumn(
                name: "xmin",
                table: "templates");

            migrationBuilder.DropColumn(
                name: "idempotency_key",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "minus_impact",
                table: "criteria");

            migrationBuilder.DropColumn(
                name: "repeated_faults",
                table: "answers");

            migrationBuilder.CreateIndex(
                name: "IX_action_plans_store_id",
                table: "action_plans",
                column: "store_id");

            migrationBuilder.AddForeignKey(
                name: "FK_profiles_AspNetUsers_id",
                table: "profiles",
                column: "id",
                principalTable: "AspNetUsers",
                principalColumn: "Id",
                onDelete: ReferentialAction.Cascade);
        }
    }
}
