import 'dart:async';
import 'package:flutter/services.dart';

/// Dart-side client for the SAWA Performance Benchmark.
///
/// Communicates with the native [PerformanceBenchmark] Kotlin object via
/// the same [MethodChannel] used by [HandTrackerService].
///
/// Usage:
///   final client = BenchmarkClient();
///   await client.start();
///   // ... let the app run the movement activity for ≥500 frames ...
///   final result = await client.stop();
///   print(result.summary());
///
/// This class is intentionally standalone — it requires no changes to
/// HandTrackerService and does not affect any production behavior.
class BenchmarkClient {
  static const MethodChannel _channel = MethodChannel('mindora/hand_tracking');

  /// Enable benchmark mode on the native side and reset all counters.
  Future<bool> start() async {
    try {
      final ok = await _channel.invokeMethod<bool>('benchmarkStart') ?? false;
      if (ok) {
        // ignore: avoid_print
        print('[BenchmarkClient] Benchmark STARTED. Run the movement activity for ≥500 frames, then call stop().');
      }
      return ok;
    } catch (e) {
      // ignore: avoid_print
      print('[BenchmarkClient] benchmarkStart failed: $e');
      return false;
    }
  }

  /// Disable benchmark mode, trigger logcat report, and return results.
  Future<BenchmarkResult?> stop() async {
    try {
      final raw = await _channel.invokeMethod<Map<dynamic, dynamic>>('benchmarkStop');
      if (raw == null) return null;
      return BenchmarkResult._fromMap(Map<String, dynamic>.from(raw));
    } catch (e) {
      // ignore: avoid_print
      print('[BenchmarkClient] benchmarkStop failed: $e');
      return null;
    }
  }

  /// Reset counters without stopping.
  Future<bool> reset() async {
    try {
      return await _channel.invokeMethod<bool>('benchmarkReset') ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// Typed holder for benchmark results returned from the native layer.
class BenchmarkResult {
  final int sampleCount;
  final double avgLatencyMs;
  final double medianLatencyMs;
  final double p95LatencyMs;
  final int minLatencyMs;
  final int maxLatencyMs;
  final int samplesOver100ms;
  final double avgFps;
  final double medianFps;
  final double p5Fps;
  final int acceptedFrames;
  final int droppedFrames;
  final int totalAttempts;
  final double infOnlyAvgMs;
  final double infOnlyP95Ms;

  const BenchmarkResult({
    required this.sampleCount,
    required this.avgLatencyMs,
    required this.medianLatencyMs,
    required this.p95LatencyMs,
    required this.minLatencyMs,
    required this.maxLatencyMs,
    required this.samplesOver100ms,
    required this.avgFps,
    required this.medianFps,
    required this.p5Fps,
    required this.acceptedFrames,
    required this.droppedFrames,
    required this.totalAttempts,
    required this.infOnlyAvgMs,
    required this.infOnlyP95Ms,
  });

  factory BenchmarkResult._fromMap(Map<String, dynamic> m) {
    return BenchmarkResult(
      sampleCount:       (m['sampleCount']      as num?)?.toInt()    ?? 0,
      avgLatencyMs:      (m['avgLatencyMs']     as num?)?.toDouble() ?? 0.0,
      medianLatencyMs:   (m['medianLatencyMs']  as num?)?.toDouble() ?? 0.0,
      p95LatencyMs:      (m['p95LatencyMs']     as num?)?.toDouble() ?? 0.0,
      minLatencyMs:      (m['minLatencyMs']     as num?)?.toInt()    ?? 0,
      maxLatencyMs:      (m['maxLatencyMs']     as num?)?.toInt()    ?? 0,
      samplesOver100ms:  (m['samplesOver100ms'] as num?)?.toInt()    ?? 0,
      avgFps:            (m['avgFps']           as num?)?.toDouble() ?? 0.0,
      medianFps:         (m['medianFps']        as num?)?.toDouble() ?? 0.0,
      p5Fps:             (m['p5Fps']            as num?)?.toDouble() ?? 0.0,
      acceptedFrames:    (m['acceptedFrames']   as num?)?.toInt()    ?? 0,
      droppedFrames:     (m['droppedFrames']    as num?)?.toInt()    ?? 0,
      totalAttempts:     (m['totalAttempts']    as num?)?.toInt()    ?? 0,
      infOnlyAvgMs:      (m['infOnlyAvgMs']     as num?)?.toDouble() ?? 0.0,
      infOnlyP95Ms:      (m['infOnlyP95Ms']     as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Human-readable summary for quick inspection in the Flutter console.
  String summary() {
    final over100Pct = sampleCount > 0
        ? (samplesOver100ms * 100.0 / sampleCount).toStringAsFixed(1)
        : 'N/A';

    final fpsStatus = (avgFps >= 15 && medianFps >= 15)
        ? (p5Fps >= 10 ? 'VERIFIED' : 'PARTIALLY VERIFIED')
        : 'NOT VERIFIED';

    final latStatus = (medianLatencyMs < 100 && p95LatencyMs < 100)
        ? 'VERIFIED'
        : (medianLatencyMs < 100 ? 'PARTIALLY VERIFIED (p95 = ${p95LatencyMs.toInt()}ms)' : 'NOT VERIFIED');

    return '''
╔══════════════════════════════════════════════════════════════╗
║         SAWA PERFORMANCE BENCHMARK RESULT                    ║
╠══════════════════════════════════════════════════════════════╣
║ LATENCY  (on-device processing: YUV decode + MediaPipe)      ║
║  Samples         : $sampleCount
║  Average         : ${avgLatencyMs.toInt()} ms
║  Median          : ${medianLatencyMs.toInt()} ms
║  p95             : ${p95LatencyMs.toInt()} ms
║  Min             : $minLatencyMs ms
║  Max             : $maxLatencyMs ms
║  > 100 ms        : $samplesOver100ms frames ($over100Pct%)
╠══════════════════════════════════════════════════════════════╣
║ MEDIAPIPE INFERENCE ONLY (detect() call)                     ║
║  Average         : ${infOnlyAvgMs.toInt()} ms
║  p95             : ${infOnlyP95Ms.toInt()} ms
╠══════════════════════════════════════════════════════════════╣
║ THROUGHPUT                                                   ║
║  Accepted Frames : $acceptedFrames
║  Dropped Frames  : $droppedFrames
║  Total Attempts  : $totalAttempts
║  Avg FPS         : ${avgFps.toStringAsFixed(1)}
║  Median FPS      : ${medianFps.toStringAsFixed(1)}
║  p5 FPS (worst)  : ${p5Fps.toStringAsFixed(1)}
╠══════════════════════════════════════════════════════════════╣
║ CLAIM ASSESSMENT                                             ║
║  "≥15 FPS"       : $fpsStatus
║  "<100 ms"       : $latStatus
╚══════════════════════════════════════════════════════════════╝''';
  }
}
