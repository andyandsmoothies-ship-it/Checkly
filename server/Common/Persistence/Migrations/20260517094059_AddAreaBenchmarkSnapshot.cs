using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAreaBenchmarkSnapshot : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "area_benchmark_snapshots",
                columns: table => new
                {
                    area_id = table.Column<Guid>(type: "uuid", nullable: false),
                    category_avgs = table.Column<string>(type: "jsonb", nullable: false),
                    overall_avg = table.Column<decimal>(type: "numeric", nullable: false),
                    std_deviation = table.Column<decimal>(type: "numeric", nullable: false),
                    total_audits = table.Column<int>(type: "integer", nullable: false),
                    last_calc_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_area_benchmark_snapshots", x => x.area_id);
                    table.ForeignKey(
                        name: "FK_area_benchmark_snapshots_areas_area_id",
                        column: x => x.area_id,
                        principalTable: "areas",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "area_benchmark_snapshots");
        }
    }
}
