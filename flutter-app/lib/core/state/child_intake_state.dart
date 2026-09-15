import '../models/child_enums.dart';
import '../models/child_requests.dart';

/// Lightweight typed state holder that persists collected child information
/// across Step 1 and Step 2 of the child onboarding flow.
class ChildIntakeState {
  // --- Step 1 Fields ---
  String? fullName;
  DateTime? birthDate;
  String? diagnosis;
  String? gender; // 'male' or 'female'
  String? supportNotes;
  String? localAvatarPath; // Preserved locally for UI; never sent as avatarUrl

  // --- Step 2 Fields ---
  String? rawSupportLevelText;
  SupportLevelTier? supportLevelTier;
  String? preferredPracticeTime;
  int? focusDurationMinutes;
  String? hearingStatus; // 'normal' or 'difficulty'
  String? visionStatus; // 'normal' or 'difficulty'
  List<String> preferredActivities = [];

  ChildIntakeState({
    this.fullName,
    this.birthDate,
    this.diagnosis,
    this.gender = 'male',
    this.supportNotes,
    this.localAvatarPath,
    this.rawSupportLevelText,
    this.supportLevelTier,
    this.preferredPracticeTime,
    this.focusDurationMinutes,
    this.hearingStatus,
    this.visionStatus,
    List<String>? preferredActivities,
  }) {
    if (preferredActivities != null) {
      this.preferredActivities = List.from(preferredActivities);
    }
  }

  /// Validates and converts collected intake state into backend CreateChildRequest.
  ///
  /// Enforces:
  /// - FullName required
  /// - DateOfBirth required & formatted as yyyy-MM-dd
  /// - SupportLevel must be an explicitly recognized enum tier (Correction 2)
  /// - PreferredActivityStyle explicitly mapped (Correction 1)
  /// - AvatarUrl is null because backend does not have an upload endpoint (Correction 3)
  CreateChildRequest toCreateChildRequest() {
    if (fullName == null || fullName!.trim().isEmpty) {
      throw StateError('اسم الطفل بالكامل مطلوب');
    }

    if (birthDate == null) {
      throw StateError('تاريخ الميلاد مطلوب');
    }

    // Format DateOnly ISO string: "yyyy-MM-dd"
    final formattedDob =
        '${birthDate!.year.toString().padLeft(4, '0')}-${birthDate!.month.toString().padLeft(2, '0')}-${birthDate!.day.toString().padLeft(2, '0')}';

    // Map gender
    final mappedGender = ChildGender.fromString(gender)?.value;

    // Map support level - strictly requires an explicitly recognized tier (Correction 2)
    if (supportLevelTier == null && rawSupportLevelText != null) {
      supportLevelTier = SupportLevelTier.fromUserInput(rawSupportLevelText);
    }

    if (supportLevelTier == null) {
      throw StateError(
        'يرجى إدخال درجة دعم صالحة (بسيط، متوسط، أو عالي)',
      );
    }

    // Map sensory statuses
    final mappedHearing = SensoryStatusTier.fromString(hearingStatus)?.value;
    final mappedVision = SensoryStatusTier.fromString(visionStatus)?.value;

    // Map preferred activity type (Correction 1)
    final mappedActivity =
        PreferredActivityStyle.fromSelectedValues(preferredActivities)?.value;

    return CreateChildRequest(
      fullName: fullName!.trim(),
      dateOfBirth: formattedDob,
      supportNotes: supportNotes,
      baselineMovementLevel: 1, // Beginner default
      baselineSpeechLevel: 1, // Beginner default
      baselineAttentionLevel: 1, // Beginner default
      gender: mappedGender,
      diagnosis: diagnosis,
      avatarUrl: null, // Per Correction 3: Do not send local paths/fake URLs
      supportLevel: supportLevelTier!.value,
      hearingStatus: mappedHearing,
      visionStatus: mappedVision,
      focusDurationMinutes: focusDurationMinutes,
      preferredPracticeTime: preferredPracticeTime,
      preferredActivityType: mappedActivity,
    );
  }
}
