using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddPbacInvalidateTrigger : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // Trigger function: emits NOTIFY on channel 'pbac_invalidate' for any
            // INSERT / UPDATE / DELETE on role_capabilities.
            // FOR EACH STATEMENT fires once per batch, not once per row (thundering-herd guard).
            migrationBuilder.Sql("""
                CREATE OR REPLACE FUNCTION notify_pbac_change()
                RETURNS TRIGGER LANGUAGE plpgsql AS $$
                BEGIN
                    PERFORM pg_notify('pbac_invalidate', 'reload');
                    RETURN NEW;
                END;
                $$;

                DROP TRIGGER IF EXISTS trg_pbac_invalidate ON role_capabilities;

                CREATE TRIGGER trg_pbac_invalidate
                AFTER INSERT OR UPDATE OR DELETE ON role_capabilities
                FOR EACH STATEMENT
                EXECUTE FUNCTION notify_pbac_change();
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("""
                DROP TRIGGER IF EXISTS trg_pbac_invalidate ON role_capabilities;
                DROP FUNCTION IF EXISTS notify_pbac_change();
                """);
        }
    }
}
