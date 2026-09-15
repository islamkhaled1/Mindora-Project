/// Child-related enums matching ASP.NET Core Mindora.Domain.Enums.
///
/// Integer values match the backend enum values exactly.

/// Child gender specified during profile intake.
enum ChildGender {
  boy(1, 'ولد'),
  girl(2, 'بنت'),
  other(3, 'آخر');

  final int value;
  final String arabicLabel;

  const ChildGender(this.value, this.arabicLabel);

  static ChildGender? fromString(String? val) {
    if (val == null) return null;
    final normalized = val.trim().toLowerCase();
    if (normalized == 'male' || normalized == 'boy' || normalized == 'ولد') {
      return ChildGender.boy;
    }
    if (normalized == 'female' || normalized == 'girl' || normalized == 'بنت') {
      return ChildGender.girl;
    }
    if (normalized == 'other' || normalized == 'آخر') {
      return ChildGender.other;
    }
    return null;
  }
}

/// Baseline developmental support tier selected during child intake.
enum SupportLevelTier {
  mild(1, 'بسيط'),
  moderate(2, 'متوسط'),
  high(3, 'عالي');

  final int value;
  final String arabicLabel;

  const SupportLevelTier(this.value, this.arabicLabel);

  /// Explicit mapping from user input to known backend SupportLevel enum.
  /// Returns null if the value is unrecognized (no silent fallback).
  static SupportLevelTier? fromUserInput(String? input) {
    if (input == null) return null;
    final trimmed = input.trim().toLowerCase();
    if (trimmed.isEmpty) return null;

    // Mild tier keywords
    if (trimmed == 'بسيط' ||
        trimmed == 'خفيف' ||
        trimmed == 'منخفض' ||
        trimmed == 'دعم بسيط' ||
        trimmed == 'دعم خفيف' ||
        trimmed == '1' ||
        trimmed == 'mild' ||
        trimmed == 'low') {
      return SupportLevelTier.mild;
    }

    // Moderate tier keywords
    if (trimmed == 'متوسط' ||
        trimmed == 'دعم متوسط' ||
        trimmed == '2' ||
        trimmed == 'moderate' ||
        trimmed == 'medium') {
      return SupportLevelTier.moderate;
    }

    // High tier keywords
    if (trimmed == 'عالي' ||
        trimmed == 'شديد' ||
        trimmed == 'كبير' ||
        trimmed == 'مكثف' ||
        trimmed == 'دعم عالي' ||
        trimmed == 'دعم شديد' ||
        trimmed == 'دعم كبير' ||
        trimmed == '3' ||
        trimmed == 'high' ||
        trimmed == 'severe') {
      return SupportLevelTier.high;
    }

    // Unrecognized value: return null so caller can raise validation error
    return null;
  }
}

/// Sensory status evaluation (hearing or vision) from child onboarding.
enum SensoryStatusTier {
  normal(1, 'طبيعي'),
  hasDifficulty(2, 'يعاني من صعوبة');

  final int value;
  final String arabicLabel;

  const SensoryStatusTier(this.value, this.arabicLabel);

  static SensoryStatusTier? fromString(String? val) {
    if (val == null) return null;
    final normalized = val.trim().toLowerCase();
    if (normalized == 'normal' || normalized == 'طبيعي') {
      return SensoryStatusTier.normal;
    }
    if (normalized == 'difficulty' ||
        normalized == 'hasdifficulty' ||
        normalized == 'يعاني من صعوبة') {
      return SensoryStatusTier.hasDifficulty;
    }
    return null;
  }
}

/// Child's preferred interaction style (Games vs Stories).
enum PreferredActivityStyle {
  games(1, 'الألعاب واللعب'),
  stories(2, 'القصص والتعلم');

  final int value;
  final String arabicLabel;

  const PreferredActivityStyle(this.value, this.arabicLabel);

  /// Explicit semantic mapping from Flutter MultiSelect values:
  /// - 'games' (الألعاب واللعب) -> Games (1)
  /// - 'learning' (القصص والتعلم) -> Stories (2)
  static PreferredActivityStyle? fromSelectedValues(List<String> values) {
    if (values.isEmpty) return null;

    final hasGames = values.contains('games');
    final hasStories = values.contains('learning');

    if (hasGames && !hasStories) {
      return PreferredActivityStyle.games;
    }
    if (hasStories && !hasGames) {
      return PreferredActivityStyle.stories;
    }
    // If both are selected, default to games as primary interaction style
    if (hasGames && hasStories) {
      return PreferredActivityStyle.games;
    }
    return null;
  }
}

/// Baseline and target difficulty tiers for rehabilitation activities.
enum DifficultyTier {
  beginner(1, 'مبتدئ'),
  intermediate(2, 'متوسط'),
  advanced(3, 'متقدم');

  final int value;
  final String arabicLabel;

  const DifficultyTier(this.value, this.arabicLabel);
}
