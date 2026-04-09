using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    /// <summary>
    /// Data-only migration: seeds the admin:manage_roles capability for the admin role.
    /// BOOTSTRAP SAFETY GATE: Without this row, RequireCapability("admin:manage_roles") on
    /// the Admin Roles API endpoints will 403 every admin on first request after deploy.
    /// Uses ON CONFLICT DO NOTHING — idempotent, safe to re-run.
    /// </summary>
    public partial class SeedAdminManageRolesCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES (gen_random_uuid(), 'admin', 'admin:manage_roles', now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM role_capabilities
                WHERE role = 'admin' AND capability = 'admin:manage_roles';
                """);
        }
    }
}
