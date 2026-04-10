using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedAnalyticsAreaCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Seed analytics:area capability for area_manager role.
            // This is the capability pre-declared in AppCapabilities.AnalyticsArea (Slice 1).
            // ON CONFLICT DO NOTHING ensures idempotency: safe to re-run.
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES
                    (gen_random_uuid(), 'area_manager', 'analytics:area', now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);

            // Ensure all 11 AppCapabilities are seeded for the admin role.
            // Protects against missing rows from future DB wipes or partial migrations.
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES
                    (gen_random_uuid(), 'admin', 'templates:create',  now()),
                    (gen_random_uuid(), 'admin', 'templates:update',  now()),
                    (gen_random_uuid(), 'admin', 'templates:delete',  now()),
                    (gen_random_uuid(), 'admin', 'stores:write',      now()),
                    (gen_random_uuid(), 'admin', 'areas:write',       now()),
                    (gen_random_uuid(), 'admin', 'users:manage',      now()),
                    (gen_random_uuid(), 'admin', 'analytics:admin',   now()),
                    (gen_random_uuid(), 'admin', 'analytics:area',    now()),
                    (gen_random_uuid(), 'admin', 'submissions:list',  now()),
                    (gen_random_uuid(), 'admin', 'admin:manage_roles',now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {

        }
    }
}
