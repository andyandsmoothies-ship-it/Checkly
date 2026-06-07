using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddManagerSnapshots : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<Guid>(
                name: "area_manager_id",
                table: "submissions",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "area_manager_name",
                table: "submissions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "store_manager_id",
                table: "submissions",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "store_manager_name",
                table: "submissions",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "area_manager_id",
                table: "action_plans",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "area_manager_name",
                table: "action_plans",
                type: "text",
                nullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "area_manager_id",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "area_manager_name",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "store_manager_id",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "store_manager_name",
                table: "submissions");

            migrationBuilder.DropColumn(
                name: "area_manager_id",
                table: "action_plans");

            migrationBuilder.DropColumn(
                name: "area_manager_name",
                table: "action_plans");
        }
    }
}
