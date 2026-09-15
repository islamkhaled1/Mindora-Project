import 'dart:io' show Platform, File;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Environment and API configuration for the Sawa Flutter application.
///
/// Automatically resolves platform-specific localhost URLs for local ASP.NET Core
/// development (default port 5222 matching launchSettings.json):
/// - Android Emulator: 10.0.2.2:5222
/// - iOS Simulator / Web / Desktop: localhost:5222
/// - Physical Device: Configurable via custom override or compile-time variable
class EnvConfig {
  EnvConfig._();

  /// Default port configured in ASP.NET Core launchSettings.json (HTTP profile).
  static const int defaultPort = 5222;

  /// Compile-time override passed via `--dart-define=API_BASE_URL=https://...`
  static const String _compileTimeBaseUrl = String.fromEnvironment('API_BASE_URL');

  /// Runtime override for physical devices or custom backend instances.
  static String? _runtimeBaseUrlOverride;

  /// Sets a custom base URL at runtime (e.g. for testing on a physical device with a LAN IP).
  /// Example: `EnvConfig.overrideBaseUrl('http://192.168.1.10:5222');`
  static void overrideBaseUrl(String? customUrl) {
    if (customUrl != null && customUrl.trim().isNotEmpty) {
      _runtimeBaseUrlOverride = _normalizeUrl(customUrl.trim());
    } else {
      _runtimeBaseUrlOverride = null;
    }
  }

  /// Resolves the current base URL depending on runtime override, compile-time define,
  /// or platform defaults.
  static String get baseUrl {
    if (_runtimeBaseUrlOverride != null && _runtimeBaseUrlOverride!.isNotEmpty) {
      return _runtimeBaseUrlOverride!;
    }

    if (_compileTimeBaseUrl.isNotEmpty) {
      return _normalizeUrl(_compileTimeBaseUrl);
    }

    // Default local development endpoints
    if (kIsWeb) {
      return 'http://localhost:$defaultPort';
    }

    try {
      if (Platform.isAndroid) {
        // Check if running on an emulator or physical device.
        // On physical devices, 127.0.0.1 routes over `adb reverse tcp:5222 tcp:5222` to the host PC.
        final isEmulator = File('/dev/socket/qemud').existsSync() ||
            File('/sys/qemu_trace').existsSync() ||
            File('/system/bin/qemu-props').existsSync();
        if (isEmulator) {
          return 'http://10.0.2.2:$defaultPort';
        }
        return 'http://127.0.0.1:$defaultPort';
      }
    } catch (_) {
      // Fallback for platforms where dart:io Platform is unsupported
      return 'http://localhost:$defaultPort';
    }

    // iOS Simulator, macOS, Windows, Linux
    return 'http://localhost:$defaultPort';
  }

  /// Connection timeout duration (15 seconds).
  static const Duration connectTimeout = Duration(seconds: 15);

  /// Receive timeout duration (15 seconds).
  static const Duration receiveTimeout = Duration(seconds: 15);

  /// Send timeout duration (15 seconds).
  static const Duration sendTimeout = Duration(seconds: 15);

  /// Removes trailing slashes for consistent endpoint concatenation.
  static String _normalizeUrl(String url) {
    return url.endsWith('/') ? url.substring(0, url.length - 1) : url;
  }
}
