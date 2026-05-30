using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class DropAreaTable : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_profiles_areas_area_id",
                table: "profiles");

            migrationBuilder.DropForeignKey(
                name: "FK_stores_areas_area_id",
                table: "stores");

            migrationBuilder.DropTable(
                name: "areas");

            migrationBuilder.DropIndex(
                name: "IX_stores_area_id",
                table: "stores");

            migrationBuilder.DropIndex(
                name: "IX_profiles_area_id",
                table: "profiles");

            migrationBuilder.DropColumn(
                name: "area_id",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "area_id",
                table: "profiles");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "area_id",
                table: "stores",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "area_id",
                table: "profiles",
                type: "uuid",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "areas",
                columns: table => new
                {
                    id = table.Column<Guid>(type: "uuid", nullable: false, defaultValueSql: "gen_random_uuid()"),
                    code = table.Column<string>(type: "text", nullable: true),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()"),
                    description = table.Column<string>(type: "text", nullable: true),
                    name = table.Column<string>(type: "text", nullable: false),
                    updated_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_areas", x => x.id);
                });

            migrationBuilder.CreateIndex(
                name: "IX_stores_area_id",
                table: "stores",
                column: "area_id");

            migrationBuilder.CreateIndex(
                name: "IX_profiles_area_id",
                table: "profiles",
                column: "area_id");

            migrationBuilder.CreateIndex(
                name: "IX_areas_updated_at",
                table: "areas",
                column: "updated_at");

            migrationBuilder.AddForeignKey(
                name: "FK_profiles_areas_area_id",
                table: "profiles",
                column: "area_id",
                principalTable: "areas",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_stores_areas_area_id",
                table: "stores",
                column: "area_id",
                principalTable: "areas",
                principalColumn: "id",
                onDelete: ReferentialAction.SetNull);
        }
    }
}
