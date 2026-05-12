using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class BridgeProgramToSubmission : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "program_evidence");

            migrationBuilder.AddColumn<Guid>(
                name: "program_assignment_id",
                table: "submissions",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_submissions_program_assignment_id",
                table: "submissions",
                column: "program_assignment_id",
                filter: "program_assignment_id IS NOT NULL");

            migrationBuilder.AddForeignKey(
                name: "FK_submissions_program_assignments_program_assignment_id",
                table: "submissions",
                column: "program_assignment_id",
                principalTable: "program_assignments",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_submissions_program_assignments_program_assignment_id",
                table: "submissions");

            migrationBuilder.DropIndex(
                name: "IX_submissions_program_assignment_id",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "program_assignment_id",
                table: "submissions");

            migrationBuilder.CreateTable(
                name: "program_evidence",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    assignment_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    criteria_id = table.Column<Guid>(type: "uuid", nullable: true),
                    criteria_label = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    photo_local_key = table.Column<string>(type: "text", nullable: true),
                    value = table.Column<string>(type: "text", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_program_evidence", x => x.id);
                    table.ForeignKey(
                        name: "FK_program_evidence_program_assignments_assignment_id",
                        column: x => x.assignment_id,
                        principalTable: "program_assignments",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_program_evidence_assignment_id",
                table: "program_evidence",
                column: "assignment_id");
        }
    }
}
