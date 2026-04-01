using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddVoidAuditStatus : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "void_reason",
                table: "submissions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<DateTimeOffset>(
                name: "voided_at",
                table: "submissions",
                type: "timestamp with time zone",
                nullable: true);

            migrationBuilder.Sql("ALTER TABLE submissions DROP CONSTRAINT IF EXISTS status_check;");
            migrationBuilder.Sql("ALTER TABLE submissions ADD CONSTRAINT status_check CHECK (status IN ('scheduled', 'draft', 'completed', 'pending_approval', 'approved', 'rejected', 'voided'));");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "void_reason",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "voided_at",
                table: "submissions");

            migrationBuilder.Sql("ALTER TABLE submissions DROP CONSTRAINT IF EXISTS status_check;");
            migrationBuilder.Sql("ALTER TABLE submissions ADD CONSTRAINT status_check CHECK (status IN ('scheduled', 'draft', 'completed', 'pending_approval', 'approved', 'rejected'));");
        }
    }
}
