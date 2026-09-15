class ChildAvatarHelper {
  static const String defaultBoyAsset = 'assets/images/kid_image.png';
  static const String defaultGirlAsset = 'assets/images/girl_image.png';
  static const String fallbackAsset = defaultBoyAsset;

  /// Determines whether a given string is an HTTP/HTTPS remote URL.
  static bool isNetworkUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    final trimmed = url.trim().toLowerCase();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  /// Single source of truth for child avatar resolution.
  ///
  /// Priority:
  /// 1. Real child [avatarUrl] / uploaded photo → highest priority.
  /// 2. Gender-based default avatar:
  ///    - Girl ('girl', 'female', '2', 'بنت', 'أنثى') → girl_image.png
  ///    - Boy ('boy', 'male', '1', 'ولد', 'ذكر') → kid_image.png
  /// 3. Unknown / Other / null → safe fallback (kid_image.png).
  ///
  /// Strictly avoids name-based gender guessing.
  static String resolve({
    dynamic gender,
    String? avatarUrl,
  }) {
    // 1. Real uploaded avatar takes absolute priority
    if (avatarUrl != null && avatarUrl.trim().isNotEmpty) {
      return avatarUrl.trim();
    }

    // 2. Gender-driven resolution
    if (gender == null) {
      return fallbackAsset;
    }

    final raw = gender.toString().trim().toLowerCase();
    if (raw.isEmpty) {
      return fallbackAsset;
    }

    // Girl patterns
    if (raw == 'girl' ||
        raw == 'female' ||
        raw == '2' ||
        raw == 'بنت' ||
        raw == 'أنثى' ||
        raw == 'انثى') {
      return defaultGirlAsset;
    }

    // Boy patterns
    if (raw == 'boy' ||
        raw == 'male' ||
        raw == '1' ||
        raw == 'ولد' ||
        raw == 'ذكر') {
      return defaultBoyAsset;
    }

    // 3. Unknown / Other fallback
    return fallbackAsset;
  }
}
