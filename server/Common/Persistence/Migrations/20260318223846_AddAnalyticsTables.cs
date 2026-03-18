using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAnalyticsTables : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "store_analytics_snapshot",
                columns: table => new
                {
                    store_id = table.Column<Guid>(type: "uuid", nullable: false),
                    avg_score_30d = table.Column<decimal>(type: "numeric", nullable: false),
                    total_audits_30d = table.Column<int>(type: "integer", nullable: false),
                    open_action_plans = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    overdue_action_plans = table.Column<int>(type: "integer", nullable: false, defaultValue: 0),
                    last_audit_score = table.Column<decimal>(type: "numeric", nullable: true),
                    last_audit_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: true),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_store_analytics_snapshot", x => x.store_id);
                    table.ForeignKey(
                        name: "FK_store_analytics_snapshot_stores_store_id",
                        column: x => x.store_id,
                        principalTable: "stores",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateTable(
                name: "submission_section_scores",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    submission_id = table.Column<Guid>(type: "uuid", nullable: false),
                    store_id = table.Column<Guid>(type: "uuid", nullable: true),
                    template_id = table.Column<Guid>(type: "uuid", nullable: true),
                    section_title = table.Column<string>(type: "text", nullable: false),
                    score = table.Column<decimal>(type: "numeric", nullable: false),
                    max_score = table.Column<decimal>(type: "numeric", nullable: false),
                    ratio = table.Column<decimal>(type: "numeric", nullable: true),
                    is_ccp_failed = table.Column<bool>(type: "boolean", nullable: false, defaultValue: false),
                    weight = table.Column<decimal>(type: "numeric", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_submission_section_scores", x => x.id);
                    table.ForeignKey(
                        name: "FK_submission_section_scores_submissions_submission_id",
                        column: x => x.submission_id,
                        principalTable: "submissions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_submission_section_scores_store_id_section_title",
                table: "submission_section_scores",
                columns: new[] { "store_id", "section_title" });

            migrationBuilder.CreateIndex(
                name: "IX_submission_section_scores_submission_id",
                table: "submission_section_scores",
                column: "submission_id");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "store_analytics_snapshot");

            migrationBuilder.DropTable(
                name: "submission_section_scores");
        }
    }
}
