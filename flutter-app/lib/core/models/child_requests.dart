/// Request model strictly mapping to ASP.NET Core CreateChildRequest DTO.
class CreateChildRequest {
  final String fullName;
  final String dateOfBirth; // ISO-8601 formatted DateOnly string: "yyyy-MM-dd"
  final String? supportNotes;
  final int baselineMovementLevel;
  final int baselineSpeechLevel;
  final int baselineAttentionLevel;
  final int? gender;
  final String? diagnosis;
  final String? avatarUrl;
  final int? supportLevel;
  final int? hearingStatus;
  final int? visionStatus;
  final int? focusDurationMinutes;
  final String? preferredPracticeTime;
  final int? preferredActivityType;

  const CreateChildRequest({
    required this.fullName,
    required this.dateOfBirth,
    this.supportNotes,
    this.baselineMovementLevel = 1, // Beginner
    this.baselineSpeechLevel = 1, // Beginner
    this.baselineAttentionLevel = 1, // Beginner
    this.gender,
    this.diagnosis,
    this.avatarUrl,
    this.supportLevel,
    this.hearingStatus,
    this.visionStatus,
    this.focusDurationMinutes,
    this.preferredPracticeTime,
    this.preferredActivityType,
  });

  Map<String, dynamic> toJson() => {
        'fullName': fullName.trim(),
        'dateOfBirth': dateOfBirth,
        if (supportNotes != null && supportNotes!.trim().isNotEmpty)
          'supportNotes': supportNotes!.trim(),
        'baselineMovementLevel': baselineMovementLevel,
        'baselineSpeechLevel': baselineSpeechLevel,
        'baselineAttentionLevel': baselineAttentionLevel,
        if (gender != null) 'gender': gender,
        if (diagnosis != null && diagnosis!.trim().isNotEmpty)
          'diagnosis': diagnosis!.trim(),
        if (avatarUrl != null && avatarUrl!.trim().isNotEmpty)
          'avatarUrl': avatarUrl!.trim(),
        if (supportLevel != null) 'supportLevel': supportLevel,
        if (hearingStatus != null) 'hearingStatus': hearingStatus,
        if (visionStatus != null) 'visionStatus': visionStatus,
        if (focusDurationMinutes != null)
          'focusDurationMinutes': focusDurationMinutes,
        if (preferredPracticeTime != null &&
            preferredPracticeTime!.trim().isNotEmpty)
          'preferredPracticeTime': preferredPracticeTime!.trim(),
        if (preferredActivityType != null)
          'preferredActivityType': preferredActivityType,
      };
}
