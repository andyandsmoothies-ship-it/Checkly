using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    /// <summary>
    /// Data-only migration: seeds 4 new capabilities for PBAC Phase 2 (Backend Enforcement).
    ///
    /// Seed matrix:
    ///   submissions:create  → admin, auditor
    ///   submissions:review  → admin, area_manager
    ///   action_plans:write  → admin, store_manager
    ///   action_plans:verify → admin, auditor, area_manager
    ///
    /// Uses ON CONFLICT (role, capability) DO NOTHING — idempotent, safe to re-run.
    /// NOTE: submissions:void remains a hardcoded admin check by explicit design decision.
    /// </summary>
    public partial class SeedPbacCompleteCapabilities : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                INSERT INTO role_capabilities (id, role, capability, created_at)
                VALUES
                    (gen_random_uuid(), 'admin',         'submissions:create',  now()),
                    (gen_random_uuid(), 'auditor',       'submissions:create',  now()),
                    (gen_random_uuid(), 'area_manager',  'submissions:create',  now()),
                    (gen_random_uuid(), 'admin',         'submissions:review',  now()),
                    (gen_random_uuid(), 'area_manager',  'submissions:review',  now()),
                    (gen_random_uuid(), 'admin',         'action_plans:write',  now()),
                    (gen_random_uuid(), 'auditor',       'action_plans:write',  now()),
                    (gen_random_uuid(), 'store_manager', 'action_plans:write',  now()),
                    (gen_random_uuid(), 'admin',         'action_plans:verify', now()),
                    (gen_random_uuid(), 'auditor',       'action_plans:verify', now()),
                    (gen_random_uuid(), 'area_manager',  'action_plans:verify', now())
                ON CONFLICT (role, capability) DO NOTHING;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DELETE FROM role_capabilities
                WHERE (role, capability) IN (
                    ('admin',         'submissions:create'),
                    ('auditor',       'submissions:create'),
                    ('area_manager',  'submissions:create'),
                    ('admin',         'submissions:review'),
                    ('area_manager',  'submissions:review'),
                    ('admin',         'action_plans:write'),
                    ('auditor',       'action_plans:write'),
                    ('store_manager', 'action_plans:write'),
                    ('admin',         'action_plans:verify'),
                    ('auditor',       'action_plans:verify'),
                    ('area_manager',  'action_plans:verify')
                );
                """);
        }
    }
}
