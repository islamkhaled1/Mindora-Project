"""
Mindora Movement Computer Vision Demo
======================================
Interactive Desktop Demo for Target-Reaching & Hand-to-Target Movement Tracking.

Architecture Separation:
1. Perception Layer: MediaPipe Hands landmark extraction & normalization.
2. Movement Engine: Pure deterministic state machine & telemetry engine (MovementEngine).
3. Presentation Layer: Visual target rendering, hand cursor, and live HUD overlay.
"""

from __future__ import annotations

import argparse
import math
import os
import sys
import time
from typing import Any, Optional, Tuple

import cv2
import mediapipe as mp
import numpy as np

# Ensure parent directory is in path so ai package can be resolved
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))
try:
    from ai.movement_engine import EngineState, MovementEngine, MovementReachEvent, MovementSessionResult
except ModuleNotFoundError:
    from movement_engine import EngineState, MovementEngine, MovementReachEvent, MovementSessionResult


class HandLandmarkExtractor:
    """
    Perception Layer:
    Extracts normalized coordinates [0.0, 1.0] from camera frames using MediaPipe.
    Primary Point: Landmark 8 (Index Finger Tip)
    Fallback Point: Landmark 9 (Middle MCP / Palm Center)
    """

    def __init__(self, model_path: Optional[str] = None):
        self._legacy_hands = None
        self._landmarker = None

        # 1. Try legacy solutions if present
        if hasattr(mp, "solutions") and hasattr(mp.solutions, "hands"):
            self._legacy_hands = mp.solutions.hands.Hands(
                max_num_hands=1,
                min_detection_confidence=0.7,
                min_tracking_confidence=0.7,
            )
        else:
            # 2. Modern MediaPipe Tasks API
            try:
                from mediapipe.tasks.python import BaseOptions, vision
                if model_path is None:
                    model_path = os.path.join(os.path.dirname(__file__), "hand_landmarker.task")
                if os.path.exists(model_path):
                    options = vision.HandLandmarkerOptions(
                        base_options=BaseOptions(model_asset_path=model_path),
                        running_mode=vision.RunningMode.IMAGE,
                        num_hands=1,
                        min_hand_detection_confidence=0.5,
                        min_hand_presence_confidence=0.5,
                        min_tracking_confidence=0.5,
                    )
                    self._landmarker = vision.HandLandmarker.create_from_options(options)
            except Exception as e:
                print(f"[WARN] Could not initialize MediaPipe HandLandmarker: {e}")

    def extract_reach_point(self, frame_rgb: np.ndarray) -> Tuple[Optional[float], Optional[float], float, Any]:
        """
        Processes RGB frame and returns:
            (normalized_x, normalized_y, confidence, landmarks)
        Coordinates are normalized to [0.0, 1.0] and mirrored horizontally for natural mirror interaction.
        """
        if self._legacy_hands is not None:
            results = self._legacy_hands.process(frame_rgb)
            if not results.multi_hand_landmarks:
                return None, None, 0.0, None

            hand_landmarks = results.multi_hand_landmarks[0]
            index_tip = hand_landmarks.landmark[8]
            norm_x = index_tip.x
            norm_y = index_tip.y
            confidence = getattr(index_tip, "presence", 0.9) if hasattr(index_tip, "presence") else 0.9

            if norm_x < 0.0 or norm_x > 1.0 or norm_y < 0.0 or norm_y > 1.0:
                palm = hand_landmarks.landmark[9]
                norm_x = palm.x
                norm_y = palm.y
                confidence = 0.6

            return 1.0 - norm_x, norm_y, confidence, hand_landmarks

        if self._landmarker is not None:
            mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=frame_rgb)
            res = self._landmarker.detect(mp_image)
            if not res.hand_landmarks:
                return None, None, 0.0, None

            hand_landmarks = res.hand_landmarks[0]
            index_tip = hand_landmarks[8]
            norm_x = index_tip.x
            norm_y = index_tip.y
            confidence = getattr(index_tip, "presence", 0.9) if hasattr(index_tip, "presence") else 0.9

            if norm_x < 0.0 or norm_x > 1.0 or norm_y < 0.0 or norm_y > 1.0:
                palm = hand_landmarks[9]
                norm_x = palm.x
                norm_y = palm.y
                confidence = 0.6

            return 1.0 - norm_x, norm_y, confidence, hand_landmarks

        return None, None, 0.0, None

    def close(self):
        if self._legacy_hands is not None:
            self._legacy_hands.close()
        if self._landmarker is not None:
            try:
                self._landmarker.close()
            except Exception:
                pass


class MovementVisualizer:
    """
    Presentation Layer:
    Renders visual stars/targets, hand cursors, hit animations, and live telemetry HUD.
    """

    @staticmethod
    def draw_star(image: np.ndarray, center: Tuple[int, int], radius: int, color: Tuple[int, int, int], filled: bool = True):
        """Draws a 5-pointed star polygon centered at the specified pixel coordinate."""
        cx, cy = center
        points = []
        inner_radius = radius * 0.45
        for i in range(10):
            r = radius if i % 2 == 0 else inner_radius
            angle = i * (math.pi / 5) - (math.pi / 2)
            px = int(cx + r * math.cos(angle))
            py = int(cy + r * math.sin(angle))
            points.append([px, py])
        pts = np.array(points, np.int32).reshape((-1, 1, 2))
        if filled:
            cv2.fillPoly(image, [pts], color)
        cv2.polylines(image, [pts], isClosed=True, color=(255, 255, 255), thickness=2)

    @staticmethod
    def render_overlay(
        image: np.ndarray,
        engine: MovementEngine,
        hand_px: Optional[Tuple[int, int]],
        last_event: Optional[MovementReachEvent],
    ):
        h, w, _ = image.shape
        target = engine.current_target

        # 1. Render Active Target / Star
        if target is not None:
            tx = int(target.target_x * w)
            ty = int(target.target_y * h)
            tr = int(target.target_radius * min(w, h))

            now_ms = int(time.time() * 1000)
            elapsed_target = now_ms - target.appeared_at_ms
            time_left_pct = max(0.0, 1.0 - (elapsed_target / target.timeout_ms))

            if engine.state == EngineState.REACHED:
                # Success green ring & star
                cv2.circle(image, (tx, ty), tr + 12, (0, 255, 0), 4)
                MovementVisualizer.draw_star(image, (tx, ty), tr, (0, 230, 0), filled=True)
                cv2.putText(image, "REACHED!", (tx - 55, ty - tr - 15), cv2.FONT_HERSHEY_SIMPLEX, 0.8, (0, 255, 0), 2)
            elif engine.state == EngineState.COOLDOWN:
                # Cooldown feedback
                MovementVisualizer.draw_star(image, (tx, ty), tr, (180, 180, 180), filled=False)
            else:
                # Active target: glowing gold star with timeout ring
                # Outer timeout progress circle
                cv2.circle(image, (tx, ty), tr + 6, (60, 60, 60), 2)
                end_angle = int(360 * time_left_pct)
                cv2.ellipse(image, (tx, ty), (tr + 6, tr + 6), -90, 0, end_angle, (0, 215, 255), 3)

                # Gold star
                MovementVisualizer.draw_star(image, (tx, ty), tr, (0, 215, 255), filled=True)

        # 2. Render Tracked Hand Reach Point
        if hand_px is not None:
            hx, hy = hand_px
            # Hand cursor with outer ring
            cv2.circle(image, (hx, hy), 12, (255, 0, 180), cv2.FILLED)
            cv2.circle(image, (hx, hy), 18, (255, 255, 255), 2)
            cv2.putText(image, "Hand", (hx + 18, hy + 5), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (255, 255, 255), 1)

        # 3. Render Top HUD Banner
        hud_bg = image[0:95, 0:w]
        overlay = hud_bg.copy()
        cv2.rectangle(overlay, (0, 0), (w, 95), (25, 20, 35), cv2.FILLED)
        cv2.addWeighted(overlay, 0.82, hud_bg, 0.18, 0, hud_bg)

        # Metrics values
        res = engine.get_session_result()
        last_rt = f"{last_event.reaction_time_ms} ms" if (last_event and last_event.reaction_time_ms) else "--"

        # Col 1: Repetitions
        cv2.putText(image, "REPETITIONS", (25, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (180, 180, 200), 1)
        cv2.putText(image, str(res.repetitions), (25, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.1, (0, 255, 120), 2)

        # Col 2: Failed Attempts
        cv2.putText(image, "FAILED", (190, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (180, 180, 200), 1)
        cv2.putText(image, str(res.failed_attempts), (190, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.1, (0, 100, 255), 2)

        # Col 3: Accuracy
        cv2.putText(image, "ACCURACY", (330, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (180, 180, 200), 1)
        cv2.putText(image, f"{res.accuracy_percentage:.1f}%", (330, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.1, (255, 215, 0), 2)

        # Col 4: Reaction Time
        cv2.putText(image, "REACTION TIME", (500, 30), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (180, 180, 200), 1)
        cv2.putText(image, last_rt, (500, 75), cv2.FONT_HERSHEY_SIMPLEX, 1.0, (255, 255, 255), 2)

        # Col 5: State & Instructions
        state_str = engine.state.value
        cv2.putText(image, f"STATE: {state_str}", (w - 240, 40), cv2.FONT_HERSHEY_SIMPLEX, 0.6, (200, 200, 255), 1)
        cv2.putText(image, "Press 'Q' to Finish", (w - 240, 75), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (160, 160, 160), 1)


def run_movement_cv(simulate: bool = False, max_sim_frames: int = 250):
    """
    Main entry point for running the Movement Computer Vision experience.
    Supports physical webcam execution and simulated benchmark mode.
    """
    print("=" * 60)
    print("MINDORA AI — MOVEMENT REHABILITATION DEMO")
    print("Task: Target-Reaching / Star Contact Detection")
    print("=" * 60)

    engine = MovementEngine(
        min_x=0.15,
        max_x=0.85,
        min_y=0.15,
        max_y=0.85,
        target_radius=0.08,
        min_spawn_distance=0.22,
        timeout_ms=5000,
        cooldown_ms=500,
        min_tracking_confidence=0.5,
        ema_alpha=0.7,
    )
    engine.start()

    extractor = HandLandmarkExtractor()
    last_event: Optional[MovementReachEvent] = None

    cap = None
    if not simulate:
        cap = cv2.VideoCapture(0)
        if not cap.isOpened():
            print("[WARN] Webcam index 0 could not be opened. Falling back to synthetic simulation mode.")
            simulate = True

    frame_count = 0
    sim_hand_x = 0.5
    sim_hand_y = 0.5

    try:
        while True:
            frame_count += 1
            now_ms = int(time.time() * 1000)

            if not simulate and cap is not None:
                success, frame = cap.read()
                if not success:
                    break
                # Horizontal flip for front mirror view
                frame = cv2.flip(frame, 1)
                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                hand_x, hand_y, conf, landmarks = extractor.extract_reach_point(frame_rgb)
            else:
                # Simulation mode: generate synthetic frame and simulated hand approaching active target
                frame = np.zeros((720, 1280, 3), dtype=np.uint8)
                target = engine.current_target

                # Simulate hand gradually moving toward current target
                if target is not None:
                    sim_hand_x += (target.target_x - sim_hand_x) * 0.08
                    sim_hand_y += (target.target_y - sim_hand_y) * 0.08
                hand_x, hand_y, conf = sim_hand_x, sim_hand_y, 0.95

                if frame_count >= max_sim_frames:
                    print(f"[INFO] Simulation completed {max_sim_frames} benchmark frames.")
                    break

            # 2. Movement Engine evaluation
            state, event = engine.process_frame(
                hand_x=hand_x,
                hand_y=hand_y,
                tracking_confidence=conf,
                timestamp_ms=now_ms,
            )
            if event is not None:
                last_event = event
                if event.success:
                    print(f"[HIT] Target {event.target_id} Reached! ReactionTime: {event.reaction_time_ms} ms, Repetitions: {engine.repetitions}")
                else:
                    print(f"[MISS] Target {event.target_id} Timed Out. Failed attempts: {engine.failed_attempts}")

            # 3. Presentation Layer
            h, w, _ = frame.shape
            smoothed_x = engine.ema_filter.smoothed_x
            smoothed_y = engine.ema_filter.smoothed_y
            hand_px = (int(smoothed_x * w), int(smoothed_y * h)) if (smoothed_x is not None and smoothed_y is not None) else None

            MovementVisualizer.render_overlay(frame, engine, hand_px, last_event)

            # Show desktop window if GUI is available
            try:
                cv2.imshow("Mindora Motor Therapy - Star Reaching", frame)
                key = cv2.waitKey(1) & 0xFF
                if key in (27, ord('q'), ord('Q')):
                    print("[INFO] User terminated session.")
                    break
            except Exception:
                # Headless environment
                pass

    finally:
        if cap is not None:
            cap.release()
        try:
            cv2.destroyAllWindows()
        except Exception:
            pass
        extractor.close()

    # Final session telemetry
    result = engine.get_session_result()
    print("\n" + "=" * 60)
    print("FINAL MOVEMENT SESSION RESULT (JSON):")
    print("=" * 60)
    print(result.to_json(indent=2))
    return result


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Mindora Movement Computer Vision Demo")
    parser.add_argument("--simulate", action="store_true", help="Run in synthetic simulation mode without webcam")
    parser.add_argument("--frames", type=int, default=250, help="Number of frames in simulation mode")
    args = parser.parse_args()

    run_movement_cv(simulate=args.simulate, max_sim_frames=args.frames)