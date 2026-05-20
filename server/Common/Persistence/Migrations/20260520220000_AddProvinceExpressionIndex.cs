using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddProvinceExpressionIndex : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // OBS-4: Add a PostgreSQL expression index on the JSON province field.
            // `stores.address2` is a JSON/value-object column. Province filter queries
            // (GetAnalytics.cs, ProvinceBenchmarkCalculator.cs) compile to:
            //   WHERE (address2->>'province') = @p
            // Without this index every province filter causes a full `stores` table scan.
            // EF Core cannot generate functional/expression indexes — raw SQL is required.
            migrationBuilder.Sql(@"
                CREATE INDEX IF NOT EXISTS ix_stores_province
                ON stores ((address2->>'province'))
                WHERE address2 IS NOT NULL;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql("DROP INDEX IF EXISTS ix_stores_province;");
        }
    }
}
