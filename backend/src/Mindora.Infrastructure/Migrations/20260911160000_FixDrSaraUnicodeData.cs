using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Mindora.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class FixDrSaraUnicodeData : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"
                IF EXISTS (SELECT 1 FROM AspNetUsers WHERE Email = 'dr.sara@mindora.com')
                BEGIN
                    UPDATE AspNetUsers 
                    SET FullName = N'د. سارة أحمد' 
                    WHERE Email = 'dr.sara@mindora.com';

                    UPDATE DoctorProfiles 
                    SET Specialization = N'استشاري علاج سلوكي وتخاطب للأطفال', 
                        ClinicName = N'مركز الأمل لتأهيل الأطفال' 
                    WHERE UserId IN (SELECT Id FROM AspNetUsers WHERE Email = 'dr.sara@mindora.com');
                END
            ");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            // Data-only Unicode fix; no structural rollback needed.
        }
    }
}
