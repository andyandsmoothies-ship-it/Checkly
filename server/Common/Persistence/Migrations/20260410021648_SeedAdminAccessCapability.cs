using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    /// <summary>
    /// Data-only migration: seeds the admin:access capability for the admin role.
    /// UI SIGNAL ONLY: This capability is never applied to C# route guards.
    /// It exists solely so the Flutter router can evaluate PolicyManager().can('admin:access')
    /// to show/hide the Admin Console button.
    /// Without this row, every admin is silently redirected to /home on the mobile app.
    /// Uses ON CONFLICT DO NOTHING — idempotent, safe to re-run.
    /// </summary>
    public partial class SeedAdminAccessCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES (gen_random_uuid(), 'admin', 'admin:access', now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM role_capabilities
                WHERE role = 'admin' AND capability = 'admin:access';
                """);
        }
    }
}
