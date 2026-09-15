"""
Mindora Movement Engine
=======================
Deterministic Target-Reaching & Hand-to-Target Movement Analysis Engine.

Architectural Role:
- Receives normalized hand coordinates [0.0, 1.0] from a Perception Layer (e.g. MediaPipe Hands or Mobile CV).
- Manages dynamic target generation, spatial boundaries, and state transitions.
- Evaluates target reaching with debounce / cooldown protection.
- Computes real reaction times, repetitions, timeout failures, and derived accuracy.
- Produces structured events and session summaries (JSON-serializable).
- Decoupled completely from UI rendering and camera hardware.
"""

from __future__ import annotations

import json
import math
import random
import time
from dataclasses import asdict, dataclass, field
from enum import Enum
from typing import Any, Dict, List, Optional, Tuple


class EngineState(str, Enum):
    """Deterministic states for the target-reaching state machine."""
    AWAITING_REACH = "AWAITING_REACH"
    REACHED = "REACHED"
    COOLDOWN = "COOLDOWN"
    SPAWN_NEW = "SPAWN_NEW"


class ExponentialMovingAverage:
    """
    Reusable Exponential Moving Average (EMA) filter for 2D spatial coordinates.
    Formula:
        smoothed_x = alpha * current_x + (1 - alpha) * previous_x
        smoothed_y = alpha * current_y + (1 - alpha) * previous_y
    """

    def __init__(self, alpha: float = 0.7):
        if not (0.0 < alpha <= 1.0):
            raise ValueError(f"Alpha must be in (0.0, 1.0], got {alpha}")
        self.alpha = alpha
        self._smoothed_x: Optional[float] = None
        self._smoothed_y: Optional[float] = None

    @property
    def is_initialized(self) -> bool:
        return self._smoothed_x is not None and self._smoothed_y is not None

    @property
    def smoothed_x(self) -> Optional[float]:
        return self._smoothed_x

    @property
    def smoothed_y(self) -> Optional[float]:
        return self._smoothed_y

    def update(self, x: float, y: float) -> Tuple[float, float]:
        """Updates the filter with a new raw sample and returns the smoothed tuple."""
        if not self.is_initialized:
            self._smoothed_x = float(x)
            self._smoothed_y = float(y)
        else:
            self._smoothed_x = self.alpha * float(x) + (1.0 - self.alpha) * self._smoothed_x
            self._smoothed_y = self.alpha * float(y) + (1.0 - self.alpha) * self._smoothed_y
        return self._smoothed_x, self._smoothed_y

    def reset(self) -> None:
        """Resets the internal smoothing state."""
        self._smoothed_x = None
        self._smoothed_y = None


@dataclass
class Target:
    """Represents an active reach target (Star) in normalized coordinates."""
    target_id: str
    target_x: float
    target_y: float
    target_radius: float = 0.08
    appeared_at_ms: int = 0
    timeout_ms: int = 5000

    def to_dict(self) -> Dict[str, Any]:
        return {
            "targetId": self.target_id,
            "targetX": round(self.target_x, 4),
            "targetY": round(self.target_y, 4),
            "targetRadius": round(self.target_radius, 4),
            "appearedAtMs": self.appeared_at_ms,
            "timeoutMs": self.timeout_ms,
        }


@dataclass
class MovementReachEvent:
    """Structured event recorded for every target attempt (success or timeout)."""
    target_id: str
    success: bool
    failure_reason: Optional[str] = None
    reaction_time_ms: Optional[int] = None
    timestamp_ms: int = 0
    hand_x: Optional[float] = None
    hand_y: Optional[float] = None
    target_x: float = 0.0
    target_y: float = 0.0
    distance: Optional[float] = None
    target_radius: float = 0.08
    tracking_confidence: float = 0.0

    def to_dict(self) -> Dict[str, Any]:
        return {
            "targetId": self.target_id,
            "success": self.success,
            "failureReason": self.failure_reason,
            "reactionTimeMs": self.reaction_time_ms,
            "timestampMs": self.timestamp_ms,
            "handX": round(self.hand_x, 4) if self.hand_x is not None else None,
            "handY": round(self.hand_y, 4) if self.hand_y is not None else None,
            "targetX": round(self.target_x, 4),
            "targetY": round(self.target_y, 4),
            "distance": round(self.distance, 4) if self.distance is not None else None,
            "targetRadius": round(self.target_radius, 4),
            "trackingConfidence": round(self.tracking_confidence, 4),
        }

    def to_json(self, indent: Optional[int] = None) -> str:
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)


@dataclass
class MovementSessionResult:
    """Comprehensive structured session performance summary."""
    repetitions: int
    failed_attempts: int
    total_attempts: int
    accuracy_percentage: float
    average_reaction_time_ms: float
    min_reaction_time_ms: Optional[int] = None
    max_reaction_time_ms: Optional[int] = None
    events: List[MovementReachEvent] = field(default_factory=list)

    def to_dict(self) -> Dict[str, Any]:
        return {
            "repetitions": self.repetitions,
            "successfulReaches": self.repetitions,
            "failedAttempts": self.failed_attempts,
            "totalAttempts": self.total_attempts,
            "accuracyPercentage": round(self.accuracy_percentage, 2),
            "averageReactionTimeMs": round(self.average_reaction_time_ms, 2),
            "minReactionTimeMs": self.min_reaction_time_ms,
            "maxReactionTimeMs": self.max_reaction_time_ms,
            "events": [e.to_dict() for e in self.events],
        }

    def to_json(self, indent: int = 2) -> str:
        return json.dumps(self.to_dict(), indent=indent, ensure_ascii=False)


class MovementEngine:
    """
    Deterministic Target-Reaching Movement Engine.

    Guarantees:
    - Pure mathematical evaluation independent from OpenCV / MediaPipe.
    - Strict boundary enforcement within normalized coordinates [min_x, max_x], [min_y, max_y].
    - Debounced reach transitions preventing multi-count artifact on continuous contact.
    - Real reaction time logging with millisecond timestamps.
    - Zero-attempt safe accuracy computation (defaulting to 100.0%).
    """

    def __init__(
        self,
        min_x: float = 0.15,
        max_x: float = 0.85,
        min_y: float = 0.15,
        max_y: float = 0.85,
        target_radius: float = 0.08,
        min_spawn_distance: float = 0.20,
        timeout_ms: int = 5000,
        cooldown_ms: int = 500,
        min_tracking_confidence: float = 0.5,
        ema_alpha: float = 0.7,
        seed: Optional[int] = None,
    ):
        if min_x >= max_x or min_y >= max_y:
            raise ValueError("Invalid target bounds: min must be strictly less than max.")
        if target_radius <= 0.0:
            raise ValueError(f"target_radius must be positive, got {target_radius}")

        self.min_x = min_x
        self.max_x = max_x
        self.min_y = min_y
        self.max_y = max_y
        self.target_radius = target_radius
        self.min_spawn_distance = min_spawn_distance
        self.timeout_ms = timeout_ms
        self.cooldown_ms = cooldown_ms
        self.min_tracking_confidence = min_tracking_confidence

        self._rng = random.Random(seed)
        self.ema_filter = ExponentialMovingAverage(alpha=ema_alpha)

        # State tracking
        self.state = EngineState.SPAWN_NEW
        self.current_target: Optional[Target] = None
        self.previous_target: Optional[Target] = None
        self.target_counter = 0

        self.repetitions = 0
        self.failed_attempts = 0
        self.reaction_times: List[int] = []
        self.events: List[MovementReachEvent] = []

        # Internal state timestamps
        self._state_transition_time_ms: int = 0

    @staticmethod
    def calculate_distance(x1: float, y1: float, x2: float, y2: float) -> float:
        """Computes Euclidean distance between two 2D points."""
        return math.hypot(x1 - x2, y1 - y2)

    @staticmethod
    def calculate_accuracy(repetitions: int, failed_attempts: int) -> float:
        """
        Calculates accuracy percentage.
        Formula:
            totalAttempts = repetitions + failedAttempts
            if totalAttempts == 0: accuracy = 100.0
            else: accuracy = (repetitions / totalAttempts) * 100.0
        """
        total = repetitions + failed_attempts
        if total == 0:
            return 100.0
        return (float(repetitions) / float(total)) * 100.0

    def start(self, start_time_ms: Optional[int] = None) -> Target:
        """Initializes the engine and spawns the first target."""
        self.reset()
        now_ms = int(time.time() * 1000) if start_time_ms is None else start_time_ms
        return self.spawn_next_target(now_ms)

    def reset(self) -> None:
        """Resets engine state and metrics for a clean new session."""
        self.state = EngineState.SPAWN_NEW
        self.current_target = None
        self.previous_target = None
        self.target_counter = 0
        self.repetitions = 0
        self.failed_attempts = 0
        self.reaction_times.clear()
        self.events.clear()
        self._state_transition_time_ms = 0
        self.ema_filter.reset()

    def spawn_next_target(self, timestamp_ms: int) -> Target:
        """
        Generates a new target within safe bounds, ensuring it does not spawn
        too close to the previous target position.
        """
        self.target_counter += 1
        target_id = f"star-{self.target_counter:02d}"

        # Generate candidates and pick one with sufficient distance from previous target
        best_x = self._rng.uniform(self.min_x, self.max_x)
        best_y = self._rng.uniform(self.min_y, self.max_y)

        if self.current_target is not None:
            self.previous_target = self.current_target
            prev_x, prev_y = self.previous_target.target_x, self.previous_target.target_y

            # Attempt to find position satisfying min_spawn_distance
            for _ in range(30):
                cand_x = self._rng.uniform(self.min_x, self.max_x)
                cand_y = self._rng.uniform(self.min_y, self.max_y)
                if self.calculate_distance(cand_x, cand_y, prev_x, prev_y) >= self.min_spawn_distance:
                    best_x, best_y = cand_x, cand_y
                    break

        new_target = Target(
            target_id=target_id,
            target_x=best_x,
            target_y=best_y,
            target_radius=self.target_radius,
            appeared_at_ms=timestamp_ms,
            timeout_ms=self.timeout_ms,
        )

        self.current_target = new_target
        self.state = EngineState.AWAITING_REACH
        self._state_transition_time_ms = timestamp_ms
        return new_target

    def process_frame(
        self,
        hand_x: Optional[float],
        hand_y: Optional[float],
        tracking_confidence: float = 0.0,
        timestamp_ms: Optional[int] = None,
    ) -> Tuple[EngineState, Optional[MovementReachEvent]]:
        """
        Processes a single observation tick.

        Parameters:
            hand_x: Raw normalized X coordinate [0.0, 1.0] or None if hand lost.
            hand_y: Raw normalized Y coordinate [0.0, 1.0] or None if hand lost.
            tracking_confidence: Confidence score from detector in [0.0, 1.0].
            timestamp_ms: Monotonic or wall-clock millisecond timestamp (defaults to current time).

        Returns:
            Tuple of (current EngineState, optional MovementReachEvent produced in this tick).
        """
        now_ms = int(time.time() * 1000) if timestamp_ms is None else timestamp_ms
        event_produced: Optional[MovementReachEvent] = None

        # 1. State: SPAWN_NEW
        if self.state == EngineState.SPAWN_NEW or self.current_target is None:
            self.spawn_next_target(now_ms)
            return self.state, None

        # Apply EMA smoothing if valid coordinates provided
        smoothed_x: Optional[float] = None
        smoothed_y: Optional[float] = None
        if hand_x is not None and hand_y is not None:
            smoothed_x, smoothed_y = self.ema_filter.update(hand_x, hand_y)
        else:
            self.ema_filter.reset()

        # 2. State: REACHED or COOLDOWN
        if self.state in (EngineState.REACHED, EngineState.COOLDOWN):
            elapsed_cooldown = now_ms - self._state_transition_time_ms
            if elapsed_cooldown >= self.cooldown_ms:
                self.spawn_next_target(now_ms)
                return self.state, None
            else:
                self.state = EngineState.COOLDOWN
                return self.state, None

        # 3. State: AWAITING_REACH
        if self.state == EngineState.AWAITING_REACH:
            target = self.current_target
            assert target is not None

            # Check for timeout first
            elapsed_time = now_ms - target.appeared_at_ms
            if elapsed_time > target.timeout_ms:
                self.failed_attempts += 1
                event_produced = MovementReachEvent(
                    target_id=target.target_id,
                    success=False,
                    failure_reason="timeout",
                    reaction_time_ms=None,
                    timestamp_ms=now_ms,
                    hand_x=smoothed_x,
                    hand_y=smoothed_y,
                    target_x=target.target_x,
                    target_y=target.target_y,
                    distance=self.calculate_distance(smoothed_x, smoothed_y, target.target_x, target.target_y)
                    if (smoothed_x is not None and smoothed_y is not None) else None,
                    target_radius=target.target_radius,
                    tracking_confidence=tracking_confidence,
                )
                self.events.append(event_produced)

                # Transition to COOLDOWN before next spawn
                self.state = EngineState.COOLDOWN
                self._state_transition_time_ms = now_ms
                return self.state, event_produced

            # Check for valid hand reach
            has_valid_hand = (
                smoothed_x is not None
                and smoothed_y is not None
                and tracking_confidence >= self.min_tracking_confidence
            )

            if has_valid_hand:
                dist = self.calculate_distance(smoothed_x, smoothed_y, target.target_x, target.target_y)

                # Condition: distance <= targetRadius
                if dist <= target.target_radius:
                    reaction_time = max(0, now_ms - target.appeared_at_ms)
                    self.repetitions += 1
                    self.reaction_times.append(reaction_time)

                    event_produced = MovementReachEvent(
                        target_id=target.target_id,
                        success=True,
                        failure_reason=None,
                        reaction_time_ms=reaction_time,
                        timestamp_ms=now_ms,
                        hand_x=smoothed_x,
                        hand_y=smoothed_y,
                        target_x=target.target_x,
                        target_y=target.target_y,
                        distance=dist,
                        target_radius=target.target_radius,
                        tracking_confidence=tracking_confidence,
                    )
                    self.events.append(event_produced)

                    # Transition to REACHED state (guarantees exactly ONE count)
                    self.state = EngineState.REACHED
                    self._state_transition_time_ms = now_ms
                    return self.state, event_produced

        return self.state, None

    def get_session_result(self) -> MovementSessionResult:
        """Computes and returns the complete session summary metrics."""
        total = self.repetitions + self.failed_attempts
        acc = self.calculate_accuracy(self.repetitions, self.failed_attempts)

        if self.reaction_times:
            avg_rt = sum(self.reaction_times) / len(self.reaction_times)
            min_rt = min(self.reaction_times)
            max_rt = max(self.reaction_times)
        else:
            avg_rt = 0.0
            min_rt = None
            max_rt = None

        return MovementSessionResult(
            repetitions=self.repetitions,
            failed_attempts=self.failed_attempts,
            total_attempts=total,
            accuracy_percentage=acc,
            average_reaction_time_ms=avg_rt,
            min_reaction_time_ms=min_rt,
            max_reaction_time_ms=max_rt,
            events=list(self.events),
        )
