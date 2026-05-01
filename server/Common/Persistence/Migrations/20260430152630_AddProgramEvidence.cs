using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddProgramEvidence : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "program_evidence",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    assignment_id = table.Column<Guid>(type: "uuid", nullable: false),
                    criteria_id = table.Column<Guid>(type: "uuid", nullable: true),
                    criteria_label = table.Column<string>(type: "character varying(500)", maxLength: 500, nullable: false),
                    value = table.Column<string>(type: "text", nullable: false),
                    photo_local_key = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
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

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "program_evidence");
        }
    }
}
