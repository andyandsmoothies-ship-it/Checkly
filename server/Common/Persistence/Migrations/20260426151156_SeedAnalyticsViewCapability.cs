using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedAnalyticsViewCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Seed analytics:view capability
            migrationBuilder.Sql(@"
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES 
                    (gen_random_uuid(), 'store_manager', 'analytics:view', now()),
                    (gen_random_uuid(), 'area_manager', 'analytics:view', now()),
                    (gen_random_uuid(), 'admin', 'analytics:view',    now())
                ON CONFLICT (role, capability) DO NOTHING;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM role_capabilities WHERE capability = 'analytics:view';");
        }
    }
}
