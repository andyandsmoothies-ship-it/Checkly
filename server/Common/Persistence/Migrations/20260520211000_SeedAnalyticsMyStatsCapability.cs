using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class SeedAnalyticsMyStatsCapability : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // OBS-5: Seed analytics:my_stats capability.
            // Only auditors should access personal submission stats via GET /api/analytics/my-stats.
            migrationBuilder.Sql(@"
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES
                    (gen_random_uuid(), 'auditor', 'analytics:my_stats', now())
                ON CONFLICT (role, capability) DO NOTHING;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DELETE FROM role_capabilities WHERE capability = 'analytics:my_stats';");
        }
    }
}
