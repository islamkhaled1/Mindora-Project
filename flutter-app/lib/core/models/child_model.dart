/// Response model strictly mapping to ASP.NET Core ChildDto.
class ChildModel {
  final String id;
  final String parentId;
  final String fullName;
  final DateTime? dateOfBirth;
  final String? supportNotes;
  final String currentMovementLevel;
  final String currentSpeechLevel;
  final String currentAttentionLevel;
  final DateTime? createdAtUtc;
  final String? gender;
  final String? diagnosis;
  final String? avatarUrl;
  final String? supportLevel;
  final String? hearingStatus;
  final String? visionStatus;
  final int? focusDurationMinutes;
  final String? preferredPracticeTime;
  final String? preferredActivityType;

  const ChildModel({
    required this.id,
    required this.parentId,
    required this.fullName,
    this.dateOfBirth,
    this.supportNotes,
    required this.currentMovementLevel,
    required this.currentSpeechLevel,
    required this.currentAttentionLevel,
    this.createdAtUtc,
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

  factory ChildModel.fromJson(Map<String, dynamic> json) {
    final rawDob = json['dateOfBirth'] ?? json['DateOfBirth'];
    DateTime? parsedDob;
    if (rawDob != null) {
      parsedDob = DateTime.tryParse(rawDob.toString());
    }

    final rawCreatedAt = json['createdAtUtc'] ?? json['CreatedAtUtc'];
    DateTime? parsedCreatedAt;
    if (rawCreatedAt != null) {
      parsedCreatedAt = DateTime.tryParse(rawCreatedAt.toString());
    }

    final rawFocus = json['focusDurationMinutes'] ?? json['FocusDurationMinutes'];
    int? parsedFocus;
    if (rawFocus != null) {
      parsedFocus = int.tryParse(rawFocus.toString());
    }

    return ChildModel(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      parentId: (json['parentId'] ?? json['ParentId'] ?? '').toString(),
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      dateOfBirth: parsedDob,
      supportNotes: json['supportNotes'] ?? json['SupportNotes'],
      currentMovementLevel: (json['currentMovementLevel'] ??
              json['CurrentMovementLevel'] ??
              'Beginner')
          .toString(),
      currentSpeechLevel: (json['currentSpeechLevel'] ??
              json['CurrentSpeechLevel'] ??
              'Beginner')
          .toString(),
      currentAttentionLevel: (json['currentAttentionLevel'] ??
              json['CurrentAttentionLevel'] ??
              'Beginner')
          .toString(),
      createdAtUtc: parsedCreatedAt,
      gender: json['gender'] ?? json['Gender'],
      diagnosis: json['diagnosis'] ?? json['Diagnosis'],
      avatarUrl: json['avatarUrl'] ?? json['AvatarUrl'],
      supportLevel: json['supportLevel'] ?? json['SupportLevel'],
      hearingStatus: json['hearingStatus'] ?? json['HearingStatus'],
      visionStatus: json['visionStatus'] ?? json['VisionStatus'],
      focusDurationMinutes: parsedFocus,
      preferredPracticeTime:
          json['preferredPracticeTime'] ?? json['PreferredPracticeTime'],
      preferredActivityType:
          json['preferredActivityType'] ?? json['PreferredActivityType'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parentId': parentId,
        'fullName': fullName,
        'dateOfBirth': dateOfBirth?.toIso8601String(),
        'supportNotes': supportNotes,
        'currentMovementLevel': currentMovementLevel,
        'currentSpeechLevel': currentSpeechLevel,
        'currentAttentionLevel': currentAttentionLevel,
        'createdAtUtc': createdAtUtc?.toIso8601String(),
        'gender': gender,
        'diagnosis': diagnosis,
        'avatarUrl': avatarUrl,
        'supportLevel': supportLevel,
        'hearingStatus': hearingStatus,
        'visionStatus': visionStatus,
        'focusDurationMinutes': focusDurationMinutes,
        'preferredPracticeTime': preferredPracticeTime,
        'preferredActivityType': preferredActivityType,
      };

  int? get age {
    if (dateOfBirth == null) return null;
    final now = DateTime.now();
    int a = now.year - dateOfBirth!.year;
    if (now.month < dateOfBirth!.month ||
        (now.month == dateOfBirth!.month && now.day < dateOfBirth!.day)) {
      a--;
    }
    return a >= 0 ? a : null;
  }
}
