import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:sawa/features/movement/engine/exponential_moving_average.dart';
import 'package:sawa/features/movement/engine/movement_engine.dart';
import 'package:sawa/features/movement/models/hand_tracking_result.dart';
import 'package:sawa/features/movement/models/movement_reach_event.dart';
import 'package:sawa/features/movement/models/movement_target.dart';

void main() {
  group('ExponentialMovingAverage Tests', () {
    test('Initial point sets smoothed coordinates directly', () {
      final ema = ExponentialMovingAverage(alpha: 0.7);
      expect(ema.hasValues, isFalse);

      final result = ema.update(0.5, 0.4);
      expect(ema.hasValues, isTrue);
      expect(result.x, closeTo(0.5, 0.0001));
      expect(result.y, closeTo(0.4, 0.0001));
      expect(ema.smoothedX, closeTo(0.5, 0.0001));
      expect(ema.smoothedY, closeTo(0.4, 0.0001));
    });

    test('Second point applies alpha formula: s_t = alpha * x + (1 - alpha) * s_{t-1}', () {
      final ema = ExponentialMovingAverage(alpha: 0.7);
      ema.update(0.0, 0.0);

      // Next point is (1.0, 1.0)
      // Expected = 0.7 * 1.0 + 0.3 * 0.0 = 0.7
      final result = ema.update(1.0, 1.0);
      expect(result.x, closeTo(0.7, 0.0001));
      expect(result.y, closeTo(0.7, 0.0001));

      // Next point is (1.0, 1.0) again
      // Expected = 0.7 * 1.0 + 0.3 * 0.7 = 0.7 + 0.21 = 0.91
      final result2 = ema.update(1.0, 1.0);
      expect(result2.x, closeTo(0.91, 0.0001));
      expect(result2.y, closeTo(0.91, 0.0001));
    });

    test('Reset clears smoothed values', () {
      final ema = ExponentialMovingAverage(alpha: 0.7);
      ema.update(0.5, 0.5);
      expect(ema.hasValues, isTrue);

      ema.reset();
      expect(ema.hasValues, isFalse);
      expect(ema.smoothedX, isNull);
      expect(ema.smoothedY, isNull);
    });
  });

  group('MovementEngine Core Rules & State Machine Tests', () {
    test('Zero attempts produces honest 100% accuracy', () {
      final engine = MovementEngine();
      expect(engine.totalAttempts, equals(0));
      expect(engine.accuracyPercentage, equals(100.0));
      expect(engine.repetitions, equals(0));
      expect(engine.failedAttempts, equals(0));
      expect(engine.averageReactionTimeMs, equals(0.0));
    });

    test('Initial start spawns target within bounds [0.15, 0.85]', () {
      final engine = MovementEngine(randomSeed: 42);
      engine.start(1000);

      expect(engine.state, equals(MovementEngineState.awaitingReach));
      expect(engine.currentTarget, isNotNull);

      final target = engine.currentTarget!;
      expect(target.targetX, greaterThanOrEqualTo(0.15));
      expect(target.targetX, lessThanOrEqualTo(0.85));
      expect(target.targetY, greaterThanOrEqualTo(0.15));
      expect(target.targetY, lessThanOrEqualTo(0.85));
      expect(target.targetRadius, equals(0.08));
      expect(target.appearedAtMs, equals(1000));
    });

    test('Inside target radius with confidence >= 0.5 triggers successful reach', () {
      final engine = MovementEngine(randomSeed: 100);
      engine.start(1000);
      final target = engine.currentTarget!;

      MovementReachEvent? capturedEvent;
      engine.onReach = (event) => capturedEvent = event;

      // Place hand exactly at target coordinates with 0.85 confidence
      final event = engine.processFrame(
        tracking: HandTrackingResult(
          x: target.targetX,
          y: target.targetY,
          confidence: 0.85,
          isTracked: true,
          timestampMs: 1450,
        ),
        currentTimestampMs: 1450,
      );

      expect(event, isNotNull);
      expect(capturedEvent, isNotNull);
      expect(engine.repetitions, equals(1));
      expect(engine.failedAttempts, equals(0));
      expect(engine.totalAttempts, equals(1));
      expect(engine.accuracyPercentage, equals(100.0));
      expect(engine.latestReactionTimeMs, equals(450));
      expect(engine.averageReactionTimeMs, equals(450.0));
      expect(engine.state, equals(MovementEngineState.reached));
    });

    test('Outside target radius does NOT trigger reach', () {
      final engine = MovementEngine(randomSeed: 100);
      engine.start(1000);
      final target = engine.currentTarget!;

      // Distance clearly outside radius (0.08)
      final outsideX = (target.targetX + 0.20).clamp(0.0, 1.0);
      final event = engine.processFrame(
        tracking: HandTrackingResult(
          x: outsideX,
          y: target.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 1200,
        ),
        currentTimestampMs: 1200,
      );

      expect(event, isNull);
      expect(engine.repetitions, equals(0));
      expect(engine.state, equals(MovementEngineState.awaitingReach));
    });

    test('Exact boundary distance (distance == targetRadius) triggers reach', () {
      // Use alpha = 1.0 to test exact coordinate boundary without EMA smoothing shift
      final engine = MovementEngine(
        targetRadius: 0.08,
        emaAlpha: 1.0,
        randomSeed: 123,
      );
      engine.start(1000);
      final target = engine.currentTarget!;

      // Position exactly at targetX + 0.08
      final boundaryX = target.targetX + 0.08;
      final event = engine.processFrame(
        tracking: HandTrackingResult(
          x: boundaryX,
          y: target.targetY,
          confidence: 0.75,
          isTracked: true,
          timestampMs: 1300,
        ),
        currentTimestampMs: 1300,
      );

      expect(event, isNotNull);
      expect(engine.repetitions, equals(1));
      expect(event!.distance, closeTo(0.08, 0.001));
    });

    test('Confidence below 0.5 cannot create success even if perfectly centered', () {
      final engine = MovementEngine(randomSeed: 100);
      engine.start(1000);
      final target = engine.currentTarget!;

      // Hand perfectly at target but confidence = 0.49
      final event = engine.processFrame(
        tracking: HandTrackingResult(
          x: target.targetX,
          y: target.targetY,
          confidence: 0.49,
          isTracked: true,
          timestampMs: 1200,
        ),
        currentTimestampMs: 1200,
      );

      expect(event, isNull);
      expect(engine.repetitions, equals(0));
      expect(engine.state, equals(MovementEngineState.awaitingReach));
    });

    test('Untracked hand (isTracked == false) cannot create success', () {
      final engine = MovementEngine(randomSeed: 100);
      engine.start(1000);
      final target = engine.currentTarget!;

      final event = engine.processFrame(
        tracking: HandTrackingResult(
          x: target.targetX,
          y: target.targetY,
          confidence: 0.95,
          isTracked: false, // lost tracking
          timestampMs: 1200,
        ),
        currentTimestampMs: 1200,
      );

      expect(event, isNull);
      expect(engine.repetitions, equals(0));
      expect(engine.state, equals(MovementEngineState.awaitingReach));
    });

    test('Single target produces at most one success (no duplicate success)', () {
      final engine = MovementEngine(randomSeed: 100);
      engine.start(1000);
      final target = engine.currentTarget!;

      // First frame reaches target
      final event1 = engine.processFrame(
        tracking: HandTrackingResult(
          x: target.targetX,
          y: target.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 1200,
        ),
        currentTimestampMs: 1200,
      );
      expect(event1, isNotNull);
      expect(engine.repetitions, equals(1));

      // Second frame at same position while in reached/cooldown
      final event2 = engine.processFrame(
        tracking: HandTrackingResult(
          x: target.targetX,
          y: target.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 1250,
        ),
        currentTimestampMs: 1250,
      );
      expect(event2, isNull);
      expect(engine.repetitions, equals(1)); // Still exactly 1
    });

    test('Cooldown period (500ms) prevents premature spawning then spawns new target', () {
      final engine = MovementEngine(cooldownMs: 500, randomSeed: 100);
      engine.start(1000);
      final target1 = engine.currentTarget!;

      // Reach at 1200ms -> enters reached state
      engine.processFrame(
        tracking: HandTrackingResult(
          x: target1.targetX,
          y: target1.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 1200,
        ),
        currentTimestampMs: 1200,
      );

      // Next tick at 1210ms transitions from reached to cooldown
      engine.tick(1210);
      expect(engine.state, equals(MovementEngineState.cooldown));

      // At 1500ms (diff = 290ms < 500ms), still in cooldown
      engine.tick(1500);
      expect(engine.state, equals(MovementEngineState.cooldown));

      // At 1720ms (diff = 510ms >= 500ms), new target spawns
      engine.tick(1720);
      expect(engine.state, equals(MovementEngineState.awaitingReach));
      expect(engine.currentTarget!.targetId, isNot(equals(target1.targetId)));
    });

    test('Timeout (5000ms) increments failedAttempts and spawns new target after cooldown', () {
      final engine = MovementEngine(
        targetTimeoutMs: 5000,
        cooldownMs: 500,
        randomSeed: 200,
      );
      engine.start(1000);
      final target1 = engine.currentTarget!;

      // Advance time before timeout (4999ms)
      engine.tick(5999);
      expect(engine.failedAttempts, equals(0));
      expect(engine.state, equals(MovementEngineState.awaitingReach));

      // Advance to 6000ms (elapsed 5000ms) -> timeout
      engine.tick(6000);
      expect(engine.failedAttempts, equals(1));
      expect(engine.repetitions, equals(0));
      expect(engine.totalAttempts, equals(1));
      expect(engine.accuracyPercentage, equals(0.0));
      expect(engine.state, equals(MovementEngineState.cooldown));

      // After cooldown (6500ms), spawns new target
      engine.tick(6500);
      expect(engine.state, equals(MovementEngineState.awaitingReach));
      expect(engine.currentTarget!.targetId, isNot(equals(target1.targetId)));
    });

    test('Accuracy calculates correctly across multiple hits and misses', () {
      final engine = MovementEngine(
        targetTimeoutMs: 5000,
        cooldownMs: 500,
        randomSeed: 300,
      );
      engine.start(1000);

      // 1. Hit target 1
      final t1 = engine.currentTarget!;
      engine.processFrame(
        tracking: HandTrackingResult(
          x: t1.targetX,
          y: t1.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 1400,
        ),
        currentTimestampMs: 1400,
      );
      expect(engine.repetitions, equals(1));

      // Cooldown to target 2
      engine.tick(1410); // enters cooldown
      engine.tick(1920); // spawns target 2
      expect(engine.state, equals(MovementEngineState.awaitingReach));

      // 2. Miss target 2 (timeout)
      engine.tick(1920 + 5000);
      expect(engine.failedAttempts, equals(1));

      // Cooldown to target 3
      engine.tick(1920 + 5000 + 500);

      // 3. Hit target 3
      final t3 = engine.currentTarget!;
      engine.processFrame(
        tracking: HandTrackingResult(
          x: t3.targetX,
          y: t3.targetY,
          confidence: 0.9,
          isTracked: true,
          timestampMs: 8000,
        ),
        currentTimestampMs: 8000,
      );
      expect(engine.repetitions, equals(2));

      // Total attempts = 2 hits + 1 miss = 3
      // Accuracy = 2 / 3 * 100 = 66.666...%
      expect(engine.totalAttempts, equals(3));
      expect(engine.accuracyPercentage, closeTo(66.667, 0.01));

      final result = engine.getSessionResult();
      expect(result.repetitions, equals(2));
      expect(result.failedAttempts, equals(1));
      expect(result.totalAttempts, equals(3));
      expect(result.accuracyPercentage, closeTo(66.667, 0.01));
    });

    test('Multiple targets maintain minimum separation of >= 0.20', () {
      final engine = MovementEngine(minTargetSeparation: 0.20, randomSeed: 999);
      engine.start(1000);

      MovementTarget previous = engine.currentTarget!;
      for (int i = 0; i < 15; i++) {
        // Hit previous target
        engine.processFrame(
          tracking: HandTrackingResult(
            x: previous.targetX,
            y: previous.targetY,
            confidence: 0.9,
            isTracked: true,
            timestampMs: 2000 + i * 1000,
          ),
          currentTimestampMs: 2000 + i * 1000,
        );
        engine.tick(2000 + i * 1000 + 10);
        engine.tick(2000 + i * 1000 + 600); // triggers spawn

        final current = engine.currentTarget!;
        final dx = current.targetX - previous.targetX;
        final dy = current.targetY - previous.targetY;
        final dist = sqrt(dx * dx + dy * dy);

        expect(dist, greaterThanOrEqualTo(0.20 - 0.001),
            reason: 'Target $i should have separation >= 0.20 from previous');

        previous = current;
      }
    });
  });
}
