using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace Mindora.Infrastructure.Migrations
{
    /// <inheritdoc />
    public partial class AddP0UiAuditFieldsAndBaselineAssessment : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ParentNotes",
                table: "Sessions",
                type: "nvarchar(1000)",
                maxLength: 1000,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "ParentRating",
                table: "Sessions",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "ReferralCode",
                table: "DoctorProfiles",
                type: "nvarchar(50)",
                maxLength: 50,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "AvatarUrl",
                table: "Children",
                type: "nvarchar(500)",
                maxLength: 500,
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "Diagnosis",
                table: "Children",
                type: "nvarchar(200)",
                maxLength: 200,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "FocusDurationMinutes",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "Gender",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "HearingStatus",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "PreferredActivityType",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<string>(
                name: "PreferredPracticeTime",
                table: "Children",
                type: "nvarchar(100)",
                maxLength: 100,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "SupportLevel",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "VisionStatus",
                table: "Children",
                type: "int",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "BaselineAssessments",
                columns: table => new
                {
                    Id = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    ChildId = table.Column<Guid>(type: "uniqueidentifier", nullable: false),
                    OverallScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    CognitiveScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    CommunicationScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    MotorScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    EmotionalScore = table.Column<decimal>(type: "decimal(5,2)", precision: 5, scale: 2, nullable: false),
                    CompletedAtUtc = table.Column<DateTime>(type: "datetime2", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_BaselineAssessments", x => x.Id);
                    table.ForeignKey(
                        name: "FK_BaselineAssessments_Children_ChildId",
                        column: x => x.ChildId,
                        principalTable: "Children",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.Cascade);
                });

            migrationBuilder.CreateIndex(
                name: "IX_DoctorProfiles_ReferralCode",
                table: "DoctorProfiles",
                column: "ReferralCode",
                unique: true);

            migrationBuilder.CreateIndex(
                name: "IX_BaselineAssessments_ChildId",
                table: "BaselineAssessments",
                column: "ChildId");

            migrationBuilder.CreateIndex(
                name: "IX_BaselineAssessments_ChildId_CompletedAtUtc",
                table: "BaselineAssessments",
                columns: new[] { "ChildId", "CompletedAtUtc" });
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropTable(
                name: "BaselineAssessments");

            migrationBuilder.DropIndex(
                name: "IX_DoctorProfiles_ReferralCode",
                table: "DoctorProfiles");

            migrationBuilder.DropColumn(
                name: "ParentNotes",
                table: "Sessions");

            migrationBuilder.DropColumn(
                name: "ParentRating",
                table: "Sessions");

            migrationBuilder.DropColumn(
                name: "ReferralCode",
                table: "DoctorProfiles");

            migrationBuilder.DropColumn(
                name: "AvatarUrl",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Diagnosis",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "FocusDurationMinutes",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "Gender",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "HearingStatus",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "PreferredActivityType",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "PreferredPracticeTime",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "SupportLevel",
                table: "Children");

            migrationBuilder.DropColumn(
                name: "VisionStatus",
                table: "Children");
        }
    }
}
