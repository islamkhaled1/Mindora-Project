using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Mindora.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddDoctorGender : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "Gender",
                table: "DoctorProfiles",
                type: "int",
                nullable: true);

            migrationBuilder.Sql(@"
                UPDATE DoctorProfiles
                SET Gender = 2
                WHERE UserId IN (SELECT Id FROM AspNetUsers WHERE Email = 'dr.sara@mindora.com');
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "Gender",
                table: "DoctorProfiles");
        }
    }
}
