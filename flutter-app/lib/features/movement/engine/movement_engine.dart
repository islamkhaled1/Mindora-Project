import 'dart:math';
import '../models/hand_tracking_result.dart';
import '../models/movement_reach_event.dart';
import '../models/movement_session_result.dart';
import '../models/movement_target.dart';
import 'exponential_moving_average.dart';

/// States of the deterministic Movement State Machine.
enum MovementEngineState {
  awaitingReach,
  reached,
  cooldown,
  spawnNew,
}

/// Callback signatures for Movement Engine events.
typedef OnReachCallback = void Function(MovementReachEvent event);
typedef OnTargetSpawnedCallback = void Function(MovementTarget target);
typedef OnTargetExpiredCallback = void Function(MovementTarget target);
typedef OnStateChangedCallback = void Function(MovementEngineState state);

/// Deterministic Dart port of the Mindora Movement AI Engine.
///
/// Features:
/// - EMA coordinate smoothing (alpha = 0.7)
/// - Bounded target generation [0.15, 0.85] with >= 0.20 separation
/// - Distance-based reach detection (radius = 0.08)
/// - Confidence gating (>= 0.5)
/// - Single-reach-per-target guarantee (debounce)
/// - Timeout handling (5000ms) with failure tracking
/// - Cooldown transition (500ms)
/// - Derived honest accuracy calculation
/// - Real reaction time tracking
class MovementEngine {
  final double targetRadius;
  final int targetTimeoutMs;
  final int cooldownMs;
  final double minTargetSeparation;
  final double minConfidence;
  final Random _random;
  final ExponentialMovingAverage _ema;

  MovementEngineState _state = MovementEngineState.spawnNew;
  MovementTarget? _currentTarget;
  int _targetCounter = 0;
  int _cooldownEnteredAtMs = 0;

  int _repetitions = 0;
  int _failedAttempts = 0;
  final List<int> _reactionTimesMs = [];
  final List<MovementReachEvent> _reachEvents = [];

  // Callbacks
  OnReachCallback? onReach;
  OnTargetSpawnedCallback? onTargetSpawned;
  OnTargetExpiredCallback? onTargetExpired;
  OnStateChangedCallback? onStateChanged;

  MovementEngine({
    this.targetRadius = 0.08,
    this.targetTimeoutMs = 5000,
    this.cooldownMs = 500,
    this.minTargetSeparation = 0.20,
    this.minConfidence = 0.5,
    double emaAlpha = 0.85, // raised from 0.7: more responsive at 20 FPS (50ms interval)
    int? randomSeed,
  })  : _random = Random(randomSeed),
        _ema = ExponentialMovingAverage(alpha: emaAlpha);

  // --- Getters ---

  MovementEngineState get state => _state;
  MovementTarget? get currentTarget => _currentTarget;
  int get repetitions => _repetitions;
  int get failedAttempts => _failedAttempts;
  int get totalAttempts => _repetitions + _failedAttempts;
  List<int> get reactionTimesMs => List.unmodifiable(_reactionTimesMs);
  List<MovementReachEvent> get reachEvents => List.unmodifiable(_reachEvents);

  /// Derived honest accuracy: 100% when 0 attempts, else reps / total * 100.
  double get accuracyPercentage {
    final total = totalAttempts;
    if (total == 0) return 100.0;
    return (_repetitions / total) * 100.0;
  }

  /// Average reaction time for successful reaches in milliseconds.
  double get averageReactionTimeMs {
    if (_reactionTimesMs.isEmpty) return 0.0;
    final sum = _reactionTimesMs.reduce((a, b) => a + b);
    return sum / _reactionTimesMs.length;
  }

  /// Latest reaction time or null if none recorded yet.
  int? get latestReactionTimeMs =>
      _reactionTimesMs.isNotEmpty ? _reactionTimesMs.last : null;

  /// Current smoothed hand position.
  double? get smoothedHandX => _ema.smoothedX;
  double? get smoothedHandY => _ema.smoothedY;

  // --- Engine Lifecycle & Tick ---

  /// Initialize engine with the first target at [timestampMs].
  void start(int timestampMs) {
    _resetMetrics();
    _spawnNewTarget(timestampMs);
  }

  /// Process incoming tracking data and advance state machine.
  /// Returns a [MovementReachEvent] if a reach was triggered on this tick.
  MovementReachEvent? processFrame({
    required HandTrackingResult tracking,
    required int currentTimestampMs,
  }) {
    // 1. Smooth coordinates if tracked, else reset EMA
    double? handX;
    double? handY;

    if (tracking.isTracked) {
      final smoothed = _ema.update(tracking.x, tracking.y);
      handX = smoothed.x;
      handY = smoothed.y;
    } else {
      _ema.reset();
    }

    // 2. State Machine Dispatch
    switch (_state) {
      case MovementEngineState.spawnNew:
        _spawnNewTarget(currentTimestampMs);
        return null;

      case MovementEngineState.cooldown:
        if ((currentTimestampMs - _cooldownEnteredAtMs) >= cooldownMs) {
          _spawnNewTarget(currentTimestampMs);
        }
        return null;

      case MovementEngineState.reached:
        // Transition from reached to cooldown
        _cooldownEnteredAtMs = currentTimestampMs;
        _setState(MovementEngineState.cooldown);
        return null;

      case MovementEngineState.awaitingReach:
        final target = _currentTarget;
        if (target == null) {
          _spawnNewTarget(currentTimestampMs);
          return null;
        }

        // Check for target timeout
        if (target.isExpired(currentTimestampMs)) {
          _failedAttempts++;
          onTargetExpired?.call(target);
          _cooldownEnteredAtMs = currentTimestampMs;
          _setState(MovementEngineState.cooldown);
          return null;
        }

        // If not tracked or below confidence threshold, cannot reach
        if (!tracking.isTracked ||
            handX == null ||
            handY == null ||
            tracking.confidence < minConfidence) {
          return null;
        }

        // Calculate Euclidean distance in normalized coordinate space
        final dx = handX - target.targetX;
        final dy = handY - target.targetY;
        double minDistance = sqrt(dx * dx + dy * dy);

        // Also check Landmark 9 (Palm Center - optimal for motor therapy reaches)
        if (tracking.landmark9X != null && tracking.landmark9Y != null) {
          final d9x = tracking.landmark9X! - target.targetX;
          final d9y = tracking.landmark9Y! - target.targetY;
          final dist9 = sqrt(d9x * d9x + d9y * d9y);
          if (dist9 < minDistance) minDistance = dist9;
        }

        // Also check Landmark 8 (Index Fingertip)
        if (tracking.landmark8X != null && tracking.landmark8Y != null) {
          final d8x = tracking.landmark8X! - target.targetX;
          final d8y = tracking.landmark8Y! - target.targetY;
          final dist8 = sqrt(d8x * d8x + d8y * d8y);
          if (dist8 < minDistance) minDistance = dist8;
        }

        final distance = minDistance;

        // Check reach success
        if (distance <= target.targetRadius) {
          final reactionTime = max(0, currentTimestampMs - target.appearedAtMs);
          final event = MovementReachEvent(
            targetId: target.targetId,
            handX: handX,
            handY: handY,
            targetX: target.targetX,
            targetY: target.targetY,
            distance: distance,
            confidence: tracking.confidence,
            reactionTimeMs: reactionTime,
            timestampMs: currentTimestampMs,
          );

          _repetitions++;
          _reactionTimesMs.add(reactionTime);
          _reachEvents.add(event);

          _setState(MovementEngineState.reached);
          onReach?.call(event);

          return event;
        }

        return null;
    }
  }

  /// Advance state if no frame arrived (e.g. timeout / cooldown timers).
  void tick(int currentTimestampMs) {
    processFrame(
      tracking: HandTrackingResult.untracked(timestampMs: currentTimestampMs),
      currentTimestampMs: currentTimestampMs,
    );
  }

  /// Generate summary result for the entire session.
  MovementSessionResult getSessionResult() {
    return MovementSessionResult(
      repetitions: _repetitions,
      failedAttempts: _failedAttempts,
      totalAttempts: totalAttempts,
      accuracyPercentage: accuracyPercentage,
      averageReactionTimeMs: averageReactionTimeMs,
      reactionTimesMs: List.unmodifiable(_reactionTimesMs),
      reachEvents: List.unmodifiable(_reachEvents),
    );
  }

  // --- Target Generation ---

  void _spawnNewTarget(int timestampMs) {
    _targetCounter++;
    double newX;
    double newY;

    // Retry loop to ensure minimum separation from previous target
    int attempts = 0;
    do {
      newX = 0.15 + _random.nextDouble() * (0.85 - 0.15);
      newY = 0.15 + _random.nextDouble() * (0.85 - 0.15);
      attempts++;
    } while (_currentTarget != null &&
        _calculateDistance(newX, newY, _currentTarget!.targetX, _currentTarget!.targetY) <
            minTargetSeparation &&
        attempts < 20);

    _currentTarget = MovementTarget(
      targetId: _targetCounter,
      targetX: newX,
      targetY: newY,
      targetRadius: targetRadius,
      appearedAtMs: timestampMs,
      timeoutMs: targetTimeoutMs,
    );

    _setState(MovementEngineState.awaitingReach);
    onTargetSpawned?.call(_currentTarget!);
  }

  double _calculateDistance(double x1, double y1, double x2, double y2) {
    final dx = x1 - x2;
    final dy = y1 - y2;
    return sqrt(dx * dx + dy * dy);
  }

  void _setState(MovementEngineState newState) {
    if (_state != newState) {
      _state = newState;
      onStateChanged?.call(_state);
    }
  }

  void _resetMetrics() {
    _repetitions = 0;
    _failedAttempts = 0;
    _reactionTimesMs.clear;
    _reachEvents.clear;
    _currentTarget = null;
    _targetCounter = 0;
    _cooldownEnteredAtMs = 0;
    _ema.reset();
    _setState(MovementEngineState.spawnNew);
  }
}
