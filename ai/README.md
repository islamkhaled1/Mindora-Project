# 🤖 Mindora AI — Computer Vision, Speech & Chatbot

> Standalone AI/ML models and inference services powering Mindora's three core therapy domains: **Movement**, **Speech**, and **Attention**.

---

## 🎯 What This Does

The Mindora AI module delivers three intelligent capabilities:

1. **Movement Tracking** — Real-time hand tracking via MediaPipe, driving a gamified target-reaching engine that measures motor accuracy, reaction time, and repetition counts for children with Down syndrome.
2. **Speech Recognition** — MFCC-based acoustic feature extraction + scikit-learn classifier for Arabic speech clarity scoring.
3. **AI Chatbot** — Arabic-language advisory chatbot (LLaMA 3.1 via OpenRouter) that guides parents with therapy tips and motivational support in Egyptian dialect.

---

## 🏗️ Architecture

```
ai/
├── movement_engine.py      ← Deterministic state machine: target-reaching, accuracy, reaction time
├── computervision.py       ← MediaPipe Hands perception layer + interactive desktop demo
├── chatbot.py              ← Arabic LLM chatbot (LLaMA 3.1, OpenRouter API)
├── live_speech.py          ← Live mic recording + MFCC feature extraction + sklearn prediction
├── speech_model.pkl        ← Pre-trained scikit-learn speech classifier (Arabic phonemes)
├── hand_landmarker.task    ← MediaPipe hand landmark model (7.8MB, offline-capable)
├── test_movement_engine.py ← Comprehensive unit tests for MovementEngine
└── requirements.txt        ← All Python dependencies
```

### Layered Design (Movement)

```
┌─────────────────────────────────┐
│   Presentation Layer            │  computervision.py — OpenCV window, HUD overlay
├─────────────────────────────────┤
│   Movement Engine               │  movement_engine.py — pure deterministic state machine
├─────────────────────────────────┤
│   Perception Layer              │  MediaPipe Hands → normalized [0,1] coordinates
└─────────────────────────────────┘
```

The `MovementEngine` is **completely decoupled from UI and camera** — it only receives normalized coordinates and emits structured events. This same engine is ported to **Dart** inside the Flutter app (`MovementEngine.dart`) for on-device real-time inference with zero server dependency.

---

## 🧠 Movement Engine Deep Dive

**File:** `movement_engine.py`

The engine runs a 4-state deterministic machine:

```
AWAITING_REACH → REACHED → COOLDOWN → SPAWN_NEW → AWAITING_REACH → ...
```

| Feature | Detail |
|---------|--------|
| Target generation | Random position within configurable spatial boundaries |
| Hit detection | Euclidean distance in normalized [0,1] space with configurable radius |
| Smoothing | Exponential Moving Average (EMA, α=0.7) on hand coordinates |
| Reaction time | Millisecond-precision from target spawn → successful reach |
| Accuracy | `successful_reaches / total_attempts × 100%` |
| Timeout | Targets expire after configurable TTL → counts as failed attempt |
| Debounce | Cooldown period between reaches prevents false positives |
| Output | `MovementSessionResult` — JSON-serializable structured summary |

**Cross-platform parity:** The Python `MovementEngine` and the Dart `MovementEngine` share identical algorithmic logic, ensuring consistent scoring between desktop demo and mobile production.

---

## 🎤 Speech Module

**File:** `live_speech.py` + `speech_model.pkl`

- Records 5 seconds of live audio via microphone (`sounddevice`)
- Extracts **40-dimensional MFCC features** using `librosa`
- Classifies Arabic phoneme/word using a pre-trained **scikit-learn** model
- Returns prediction label + confidence percentage

```python
# Example output
النتيجة: أحمد
نسبة الدقة (Score): 87.34%
```

---

## 💬 AI Chatbot

**File:** `chatbot.py`

- Powered by **Meta LLaMA 3.1 8B Instruct** via OpenRouter API
- System prompt configures the bot as *"مساعد ميندورا الذكي"* — a Down syndrome therapy advisor
- Responds in **Egyptian Arabic dialect** with warm, encouraging tone
- Maintains conversation history for contextual multi-turn dialogue
- Safeguards: redirects medical/emergency questions to qualified doctors

> **Note:** Production advisory chat in the Flutter app uses **Google Gemini** via the backend. This module is the research/prototype chatbot.

---

## 🖥️ Computer Vision Demo

**File:** `computervision.py`

Interactive desktop demo for testing the movement engine end-to-end:

- Live webcam feed via OpenCV
- MediaPipe Hands landmark extraction (supports both legacy `mp.solutions.hands` and new `HandLandmarker` task API)
- Real-time HUD: accuracy %, reaction time, rep count, current state
- Configurable via `--difficulty` and `--duration` flags

```bash
python computervision.py --difficulty medium --duration 60
```

---

## ⚙️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Computer Vision | MediaPipe Hands (Google) |
| Video Processing | OpenCV |
| Numerical Computing | NumPy |
| Audio Processing | librosa, sounddevice |
| ML Classifier | scikit-learn |
| LLM Chatbot | LLaMA 3.1 via OpenRouter (OpenAI-compatible API) |
| Language | Python 3.10+ |

---

## 🚀 Setup & Run

```bash
# 1. Install dependencies
pip install -r requirements.txt

# 2. Run movement demo (requires webcam)
python computervision.py

# 3. Run speech recognition (requires microphone)
python live_speech.py

# 4. Run chatbot (requires OPENROUTER_API_KEY)
export OPENROUTER_API_KEY=your_key_here
python chatbot.py

# 5. Run movement engine unit tests
python -m pytest test_movement_engine.py -v
```

---

## 📱 Flutter Integration

The `MovementEngine` is ported to Dart and runs **natively on-device** inside the Flutter app:

- `flutter-app/lib/features/movement/engine/movement_engine.dart` — Dart port of `movement_engine.py`
- `flutter-app/lib/features/movement/services/hand_tracker_service.dart` — MediaPipe via camera plugin
- `flutter-app/lib/features/movement/widgets/interactive_target_arena.dart` — Game UI widget

This means **zero network latency** during exercises — all movement AI runs entirely on the child's device.
