using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddGlobalRisksDomain : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "global_risks",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    label = table.Column<string>(type: "character varying(200)", maxLength: 200, nullable: false),
                    description = table.Column<string>(type: "text", nullable: true),
                    is_active = table.Column<bool>(type: "boolean", nullable: false, defaultValue: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_global_risks", x => x.id);
                });

            migrationBuilder.CreateTable(
                name: "submission_risks",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    submission_id = table.Column<Guid>(type: "uuid", nullable: false),
                    global_risk_id = table.Column<Guid>(type: "uuid", nullable: false),
                    triggered_by_id = table.Column<Guid>(type: "uuid", nullable: true),
                    note = table.Column<string>(type: "text", nullable: true),
                    triggered_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_submission_risks", x => x.id);
                    table.ForeignKey(
                        name: "FK_submission_risks_global_risks_global_risk_id",
                        column: x => x.global_risk_id,
                        principalTable: "global_risks",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                    table.ForeignKey(
                        name: "FK_submission_risks_submissions_submission_id",
                        column: x => x.submission_id,
                        principalTable: "submissions",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_global_risks_is_active",
                table: "global_risks",
                column: "is_active",
                filter: "is_active = true");

            migrationBuilder.CreateIndex(
                name: "IX_global_risks_updated_at",
                table: "global_risks",
                column: "updated_at");

            migrationBuilder.CreateIndex(
                name: "IX_submission_risks_global_risk_id",
                table: "submission_risks",
                column: "global_risk_id");

            migrationBuilder.CreateIndex(
                name: "IX_submission_risks_submission_id",
                table: "submission_risks",
                column: "submission_id");

            migrationBuilder.CreateIndex(
                name: "IX_submission_risks_submission_id_global_risk_id",
                table: "submission_risks",
                columns: new[] { "submission_id", "global_risk_id" },
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "submission_risks");

            migrationBuilder.DropTable(
                name: "global_risks");
        }
    }
}
