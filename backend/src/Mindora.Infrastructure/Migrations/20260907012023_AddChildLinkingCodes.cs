using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Mindora.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddChildLinkingCodes : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.CreateTable(
                name: "ChildLinkingCodes",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    CodeHash = table.Column<string>(type: "nvarchar(64)", maxLength: 64, nullable: false),
                    CreatedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    ExpiresAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false),
                    IsRedeemed = table.Column<bool>(type: "bit", nullable: false),
                    RedeemedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: true),
                    RedeemedByDoctorId = table.Column<Guid>(type: "uniqueidentifier", nullable: true)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_ChildLinkingCodes", x => x.Id);
                    table.ForeignKey(
                        name: "FK_ChildLinkingCodes_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                    table.ForeignKey(
                        name: "FK_ChildLinkingCodes_DoctorProfiles_RedeemedByDoctorId",
                        column: x => x.RedeemedByDoctorId,
                        principalTable: "DoctorProfiles",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Restrict);
                });

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkingCodes_ChildId_ExpiresAtUtc",
                table: "ChildLinkingCodes",
                columns: new[] { "ChildId", "ExpiresAtUtc" });

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkingCodes_CodeHash",
                table: "ChildLinkingCodes",
                column: "CodeHash",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_ChildLinkingCodes_RedeemedByDoctorId",
                table: "ChildLinkingCodes",
                column: "RedeemedByDoctorId");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "ChildLinkingCodes");
        }
    }
}
