using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Checkly.Api.Common.Persistence.Migrations
{
    /// <inheritdoc />
    public partial class MakeStoreAddressProvinceRequired : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // SAFETY: Backfill NULL address_province rows BEFORE setting NOT NULL.
            // Without this, the AlterColumn will fail on any existing store rows
            // that have no province set.
            migrationBuilder.Sql(
                "UPDATE stores SET address_province = 'Unknown' WHERE address_province IS NULL");

            migrationBuilder.AlterColumn<string>(
                name: "address_province",
                table: "stores",
                type: "text",
                nullable: false,
                defaultValue: "",
                oldClrType: typeof(string),
                oldType: "text",
                oldNullable: true);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AlterColumn<string>(
                name: "address_province",
                table: "stores",
                type: "text",
                nullable: true,
                oldClrType: typeof(string),
                oldType: "text");
        }
    }
}
