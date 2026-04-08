using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddRoleCapabilities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "role_capabilities",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    role = table.Column<string>(type: "character varying(50)", maxLength: 50, nullable: false),
                    capability = table.Column<string>(type: "character varying(100)", maxLength: 100, nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_role_capabilities", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_role_capabilities_role",
                table: "role_capabilities",
                column: "role");

            migrationBuilder.CreateIndex(
                name: "UX_role_capabilities_role_capability",
                table: "role_capabilities",
                columns: new[] { "role", "capability" },
                unique: true);

            // Seed: admin capabilities for PBAC Slice 1.
            // Remaining roles (auditor, store_manager, area_manager) have no capabilities by default.
            migrationBuilder.InsertData(
                table: "role_capabilities",
                columns: new[] { "id", "role", "capability", "created_at" },
                values: new object[,]
                {
                    { Guid.NewGuid(), "admin", "templates:create",  DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "templates:update",  DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "templates:delete",  DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "stores:write",      DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "areas:write",       DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "users:manage",      DateTimeOffset.UtcNow },
                    { Guid.NewGuid(), "admin", "analytics:admin",   DateTimeOffset.UtcNow },
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "role_capabilities");
        }
    }
}
