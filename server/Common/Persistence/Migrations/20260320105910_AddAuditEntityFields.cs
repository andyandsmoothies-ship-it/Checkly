using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAuditEntityFields : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "entity_id",
                table: "system_logs",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "entity_type",
                table: "system_logs",
                type: "text",
                nullable: true);

            migrationBuilder.CreateIndex(
                name: "IX_system_logs_entity_type_entity_id",
                table: "system_logs",
                columns: new[] { "entity_type", "entity_id" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropIndex(
                name: "IX_system_logs_entity_type_entity_id",
                table: "system_logs");

            migrationBuilder.DropColumn(
                name: "entity_id",
                table: "system_logs");

            migrationBuilder.DropColumn(
                name: "entity_type",
                table: "system_logs");
        }
    }
}
