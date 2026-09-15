import 'movement_reach_event.dart';

/// Aggregated telemetry and performance result of a Movement session.
class MovementSessionResult {
  final int repetitions;
  final int failedAttempts;
  final int totalAttempts;
  final double accuracyPercentage;
  final double averageReactionTimeMs;
  final List<int> reactionTimesMs;
  final List<MovementReachEvent> reachEvents;

  const MovementSessionResult({
    required this.repetitions,
    required this.failedAttempts,
    required this.totalAttempts,
    required this.accuracyPercentage,
    required this.averageReactionTimeMs,
    required this.reactionTimesMs,
    required this.reachEvents,
  });

  const MovementSessionResult.empty()
      : repetitions = 0,
        failedAttempts = 0,
        totalAttempts = 0,
        accuracyPercentage = 100.0,
        averageReactionTimeMs = 0.0,
        reactionTimesMs = const [],
        reachEvents = const [];

  @override
  String toString() =>
      'MovementSessionResult(reps: $repetitions, failed: $failedAttempts, '
      'total: $totalAttempts, acc: ${accuracyPercentage.toStringAsFixed(1)}%, '
      'avgReaction: ${averageReactionTimeMs.toStringAsFixed(0)}ms)';
}
