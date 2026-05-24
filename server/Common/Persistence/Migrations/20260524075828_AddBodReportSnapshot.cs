using System;
using Microsoft.EntityFrameworkCore.Migrations;
using Npgsql.EntityFrameworkCore.PostgreSQL.Metadata;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddBodReportSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "bod_report_snapshots",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    date = table.Column<DateOnly>(type: "date", nullable: false),
                    computed_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    status = table.Column<string>(type: "character varying(20)", maxLength: 20, nullable: false),
                    payload = table.Column<string>(type: "jsonb", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_bod_report_snapshots", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_submissions_auditor_id_status_created_at",
                table: "submissions",
                columns: new[] { "auditor_id", "status", "created_at" });

            migrationBuilder.CreateIndex(
                name: "IX_bod_report_snapshots_date",
                table: "bod_report_snapshots",
                column: "date",
                unique: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "bod_report_snapshots");

            migrationBuilder.DropIndex(
                name: "IX_submissions_auditor_id_status_created_at",
                table: "submissions");
        }
    }
}
