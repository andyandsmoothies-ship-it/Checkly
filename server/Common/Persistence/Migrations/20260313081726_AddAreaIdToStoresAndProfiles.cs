using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddAreaIdToStoresAndProfiles : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
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

            migrationBuilder.CreateIndex(
                name: "IX_stores_area_id",
                table: "stores",
                column: "area_id");

            migrationBuilder.CreateIndex(
                name: "IX_profiles_area_id",
                table: "profiles",
                column: "area_id");

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

            // Backfill area_id from area_code (case-insensitive)
            migrationBuilder.Sql("""
                UPDATE stores SET area_id = a.id
                FROM areas a
                WHERE LOWER(stores.area_code) = a.code
                  AND stores.area_code IS NOT NULL;

                UPDATE profiles SET area_id = a.id
                FROM areas a
                WHERE LOWER(profiles.area_code) = a.code
                  AND profiles.area_code IS NOT NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_profiles_areas_area_id",
                table: "profiles");

            migrationBuilder.DropForeignKey(
                name: "FK_stores_areas_area_id",
                table: "stores");

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
    }
}
