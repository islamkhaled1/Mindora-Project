"""
Unit tests for Mindora Movement Engine
"""

import math
import os
import sys
import unittest

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
try:
    from ai.movement_engine import (
        EngineState,
        ExponentialMovingAverage,
        MovementEngine,
        MovementReachEvent,
        MovementSessionResult,
        Target,
    )
except ModuleNotFoundError:
    from movement_engine import (
        EngineState,
        ExponentialMovingAverage,
        MovementEngine,
        MovementReachEvent,
        MovementSessionResult,
        Target,
    )


class TestExponentialMovingAverage(unittest.TestCase):
    def test_initialization(self):
        ema = ExponentialMovingAverage(alpha=0.7)
        self.assertFalse(ema.is_initialized)
        self.assertIsNone(ema.smoothed_x)
        self.assertIsNone(ema.smoothed_y)

    def test_first_sample_sets_exact_values(self):
        ema = ExponentialMovingAverage(alpha=0.7)
        sx, sy = ema.update(0.5, 0.6)
        self.assertTrue(ema.is_initialized)
        self.assertAlmostEqual(sx, 0.5)
        self.assertAlmostEqual(sy, 0.6)

    def test_smoothing_formula(self):
        ema = ExponentialMovingAverage(alpha=0.7)
        ema.update(0.5, 0.5)
        # Next update: 0.7 * 0.8 + 0.3 * 0.5 = 0.56 + 0.15 = 0.71
        sx, sy = ema.update(0.8, 0.8)
        self.assertAlmostEqual(sx, 0.71)
        self.assertAlmostEqual(sy, 0.71)

    def test_reset(self):
        ema = ExponentialMovingAverage(alpha=0.7)
        ema.update(0.5, 0.5)
        ema.reset()
        self.assertFalse(ema.is_initialized)
        self.assertIsNone(ema.smoothed_x)


class TestMovementEngine(unittest.TestCase):
    def setUp(self):
        self.engine = MovementEngine(
            min_x=0.15,
            max_x=0.85,
            min_y=0.15,
            max_y=0.85,
            target_radius=0.08,
            min_spawn_distance=0.20,
            timeout_ms=5000,
            cooldown_ms=500,
            min_tracking_confidence=0.5,
            ema_alpha=1.0,  # Alpha=1.0 simplifies deterministic coordinate testing
            seed=42,
        )

    def test_distance_calculation(self):
        d = MovementEngine.calculate_distance(0.0, 0.0, 3.0, 4.0)
        self.assertAlmostEqual(d, 5.0)

        d_same = MovementEngine.calculate_distance(0.5, 0.5, 0.5, 0.5)
        self.assertAlmostEqual(d_same, 0.0)

    def test_point_inside_target(self):
        target = self.engine.start(start_time_ms=1000)
        # Place hand directly at target center with confidence 0.9
        state, event = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.9,
            timestamp_ms=1500,
        )
        self.assertEqual(state, EngineState.REACHED)
        self.assertIsNotNone(event)
        self.assertTrue(event.success)
        self.assertEqual(event.reaction_time_ms, 500)
        self.assertEqual(self.engine.repetitions, 1)

    def test_point_outside_target(self):
        target = self.engine.start(start_time_ms=1000)
        # Place hand far away outside target radius
        far_x = min(0.85, target.target_x + 0.3)
        state, event = self.engine.process_frame(
            hand_x=far_x,
            hand_y=target.target_y,
            tracking_confidence=0.9,
            timestamp_ms=1500,
        )
        self.assertEqual(state, EngineState.AWAITING_REACH)
        self.assertIsNone(event)
        self.assertEqual(self.engine.repetitions, 0)

    def test_boundary_exactly_equal_to_radius(self):
        target = self.engine.start(start_time_ms=1000)
        # Boundary: distance == target_radius
        edge_x = target.target_x + target.target_radius
        edge_y = target.target_y
        state, event = self.engine.process_frame(
            hand_x=edge_x,
            hand_y=edge_y,
            tracking_confidence=0.8,
            timestamp_ms=1400,
        )
        self.assertEqual(state, EngineState.REACHED)
        self.assertIsNotNone(event)
        self.assertTrue(event.success)
        self.assertAlmostEqual(event.distance, target.target_radius)

    def test_confidence_below_threshold_does_not_reach(self):
        target = self.engine.start(start_time_ms=1000)
        # Hand directly at target center, but confidence 0.49 (< 0.5)
        state, event = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.49,
            timestamp_ms=1500,
        )
        self.assertEqual(state, EngineState.AWAITING_REACH)
        self.assertIsNone(event)
        self.assertEqual(self.engine.repetitions, 0)

    def test_invalid_no_hand_tracking_cannot_reach(self):
        self.engine.start(start_time_ms=1000)
        state, event = self.engine.process_frame(
            hand_x=None,
            hand_y=None,
            tracking_confidence=0.0,
            timestamp_ms=1500,
        )
        self.assertEqual(state, EngineState.AWAITING_REACH)
        self.assertIsNone(event)
        self.assertEqual(self.engine.repetitions, 0)

    def test_no_duplicate_success_while_hand_remains_inside_target(self):
        target = self.engine.start(start_time_ms=1000)
        # Tick 1: hand reaches target
        state1, event1 = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.95,
            timestamp_ms=1200,
        )
        self.assertEqual(state1, EngineState.REACHED)
        self.assertIsNotNone(event1)
        self.assertEqual(self.engine.repetitions, 1)

        # Tick 2: hand stays at same spot 50ms later (in REACHED / transitioning to COOLDOWN)
        state2, event2 = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.95,
            timestamp_ms=1250,
        )
        self.assertEqual(state2, EngineState.COOLDOWN)
        self.assertIsNone(event2)
        self.assertEqual(self.engine.repetitions, 1)

        # Tick 3: hand still inside at 1400ms (still within 500ms cooldown)
        state3, event3 = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.95,
            timestamp_ms=1400,
        )
        self.assertEqual(state3, EngineState.COOLDOWN)
        self.assertIsNone(event3)
        self.assertEqual(self.engine.repetitions, 1)  # Must remain exactly 1

    def test_cooldown_spawns_new_target_after_duration(self):
        target1 = self.engine.start(start_time_ms=1000)
        # Reach at 1200ms
        self.engine.process_frame(target1.target_x, target1.target_y, 0.9, 1200)

        # Cooldown expires at 1200 + 500 = 1700ms
        # Tick at 1699ms -> still in COOLDOWN
        state_pre, _ = self.engine.process_frame(None, None, 0.0, 1699)
        self.assertEqual(state_pre, EngineState.COOLDOWN)

        # Tick at 1701ms -> cooldown expired, transitions to AWAITING_REACH with new target
        state_post, _ = self.engine.process_frame(None, None, 0.0, 1701)
        self.assertEqual(state_post, EngineState.AWAITING_REACH)
        self.assertIsNotNone(self.engine.current_target)
        self.assertNotEqual(self.engine.current_target.target_id, target1.target_id)

    def test_timeout_failure(self):
        target = self.engine.start(start_time_ms=1000)
        # Timeout is 5000ms. At 6001ms, timeout triggers
        state, event = self.engine.process_frame(
            hand_x=None,
            hand_y=None,
            tracking_confidence=0.0,
            timestamp_ms=6001,
        )
        self.assertEqual(state, EngineState.COOLDOWN)
        self.assertIsNotNone(event)
        self.assertFalse(event.success)
        self.assertEqual(event.failure_reason, "timeout")
        self.assertIsNone(event.reaction_time_ms)
        self.assertEqual(self.engine.failed_attempts, 1)
        self.assertEqual(self.engine.repetitions, 0)

    def test_reaction_time_calculation(self):
        target = self.engine.start(start_time_ms=2000)
        # Reached at 3450ms -> reaction time = 1450ms
        _, event = self.engine.process_frame(
            hand_x=target.target_x,
            hand_y=target.target_y,
            tracking_confidence=0.85,
            timestamp_ms=3450,
        )
        self.assertIsNotNone(event)
        self.assertEqual(event.reaction_time_ms, 1450)
        self.assertIn(1450, self.engine.reaction_times)

    def test_accuracy_calculation(self):
        # 0 attempts -> 100.0
        self.assertEqual(MovementEngine.calculate_accuracy(0, 0), 100.0)

        # 8 successes, 2 failures -> 80.0
        self.assertAlmostEqual(MovementEngine.calculate_accuracy(8, 2), 80.0)

        # 5 successes, 0 failures -> 100.0
        self.assertAlmostEqual(MovementEngine.calculate_accuracy(5, 0), 100.0)

        # 0 successes, 5 failures -> 0.0
        self.assertAlmostEqual(MovementEngine.calculate_accuracy(0, 5), 0.0)

    def test_target_generation_inside_safe_bounds(self):
        for _ in range(50):
            target = self.engine.spawn_next_target(1000)
            self.assertGreaterEqual(target.target_x, 0.15)
            self.assertLessEqual(target.target_x, 0.85)
            self.assertGreaterEqual(target.target_y, 0.15)
            self.assertLessEqual(target.target_y, 0.85)

    def test_new_target_is_not_too_close_to_previous(self):
        target1 = self.engine.start(start_time_ms=1000)
        target2 = self.engine.spawn_next_target(2000)
        dist = MovementEngine.calculate_distance(
            target1.target_x, target1.target_y, target2.target_x, target2.target_y
        )
        self.assertGreaterEqual(dist, self.engine.min_spawn_distance)

    def test_multiple_targets_session_aggregation(self):
        # Scenario: Target 1 succeeded in 1200ms, Target 2 timed out, Target 3 succeeded in 800ms
        t1 = self.engine.start(start_time_ms=1000)
        self.engine.process_frame(t1.target_x, t1.target_y, 0.9, 2200)  # Reach 1: 1200ms

        # Cooldown to next target
        self.engine.process_frame(None, None, 0.0, 2750)  # spawns t2 at 2750ms
        t2 = self.engine.current_target
        self.assertIsNotNone(t2)

        # t2 times out at 2750 + 5001 = 7751ms
        self.engine.process_frame(None, None, 0.0, 7751)

        # Cooldown to t3
        self.engine.process_frame(None, None, 0.0, 8300)  # spawns t3 at 8300ms
        t3 = self.engine.current_target
        self.assertIsNotNone(t3)

        # Reach t3 at 9100ms (800ms reaction)
        self.engine.process_frame(t3.target_x, t3.target_y, 0.9, 9100)

        result: MovementSessionResult = self.engine.get_session_result()
        self.assertEqual(result.repetitions, 2)
        self.assertEqual(result.failed_attempts, 1)
        self.assertEqual(result.total_attempts, 3)
        # Accuracy: (2 / 3) * 100 = 66.67%
        self.assertAlmostEqual(result.accuracy_percentage, 66.67, places=1)
        # Reaction times: [1200, 800] -> avg = 1000.0, min = 800, max = 1200
        self.assertEqual(result.average_reaction_time_ms, 1000.0)
        self.assertEqual(result.min_reaction_time_ms, 800)
        self.assertEqual(result.max_reaction_time_ms, 1200)
        self.assertEqual(len(result.events), 3)

        # Verify JSON serialization
        json_output = result.to_json()
        self.assertIn('"repetitions": 2', json_output)
        self.assertIn('"failedAttempts": 1', json_output)
        self.assertIn('"averageReactionTimeMs": 1000.0', json_output)


if __name__ == "__main__":
    unittest.main()
