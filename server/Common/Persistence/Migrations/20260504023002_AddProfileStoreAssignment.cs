using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddProfileStoreAssignment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "code",
                table: "areas",
                type: "text",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "profile_store_assignments",
                columns: table => new
                {
                    profile_id = table.Column<Guid>(type: "uuid", nullable: false),
                    store_id = table.Column<Guid>(type: "uuid", nullable: false),
                    created_at = table.Column<DateTimeOffset>(type: "timestamp with time zone", nullable: false, defaultValueSql: "now()")
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_profile_store_assignments", x => new { x.profile_id, x.store_id });
                    table.ForeignKey(
                        name: "FK_profile_store_assignments_profiles_profile_id",
                        column: x => x.profile_id,
                        principalTable: "profiles",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_profile_store_assignments_stores_store_id",
                        column: x => x.store_id,
                        principalTable: "stores",
                        principalColumn: "id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_profile_store_assignments_store_id",
                table: "profile_store_assignments",
                column: "store_id");

            migrationBuilder.Sql(@"
                INSERT INTO profile_store_assignments (profile_id, store_id, created_at)
                SELECT p.id, s.id, now()
                FROM profiles p
                JOIN user_roles ur ON p.id = ur.user_id AND ur.role = 'area_manager'
                JOIN stores s ON p.area_id = s.area_id
                WHERE p.area_id IS NOT NULL
                ON CONFLICT DO NOTHING;
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "profile_store_assignments");

            migrationBuilder.DropColumn(
                name: "code",
                table: "areas");
        }
    }
}
