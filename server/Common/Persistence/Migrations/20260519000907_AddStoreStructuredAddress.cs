using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class AddStoreStructuredAddress : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "address_district",
                table: "stores",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "address_province",
                table: "stores",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "address_street",
                table: "stores",
                type: "text",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "address_ward",
                table: "stores",
                type: "text",
                nullable: true);

            // SL-1 Backfill: Populate address_province from the store's current Area.Name.
            // TC-SL1-03: Stores previously assigned to an Area inherit Province = Area.Name.
            migrationBuilder.Sql("""
                UPDATE stores
                SET address_province = a.name
                FROM areas a
                WHERE stores.area_id = a.id;
                """);

            // TC-SL1-09: Stores with no Area (area_id IS NULL) fall back to 'Uncategorized'.
            migrationBuilder.Sql("""
                UPDATE stores
                SET address_province = 'Uncategorized'
                WHERE address_province IS NULL;
                """);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "address_district",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "address_province",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "address_street",
                table: "stores");

            migrationBuilder.DropColumn(
                name: "address_ward",
                table: "stores");
        }
    }
}
