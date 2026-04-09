using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    /// <summary>
    /// Data-only migration: seeds the submissions:list capability for all 4 roles.
    /// Uses ON CONFLICT DO NOTHING — idempotent, safe to re-run.
    /// </summary>
    public partial class SeedSubmissionsListCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES 
                    (gen_random_uuid(), 'admin', 'submissions:list', now()),
                    (gen_random_uuid(), 'auditor', 'submissions:list', now()),
                    (gen_random_uuid(), 'store_manager', 'submissions:list', now()),
                    (gen_random_uuid(), 'area_manager', 'submissions:list', now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM role_capabilities
                WHERE capability = 'submissions:list' AND role IN ('admin', 'auditor', 'store_manager', 'area_manager');
                """);
        }
    }
}
