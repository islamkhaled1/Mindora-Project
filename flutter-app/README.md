# 📱 Mindora Flutter App — SAWA

> **Package:** `com.example.sawa`  
> **Version:** 1.0.0  
> **Platform:** Android (iOS-ready)  
> **Production API:** https://sawa-app.runasp.net  
> **Download APK:** [app-release.apk](build/app/outputs/flutter-apk/app-release.apk) — 112 MB

A production-grade Flutter mobile application built for children with Down syndrome and their parents. The app delivers three AI-powered therapy domains — **Movement**, **Attention**, and **Speech** — with real-time MediaPipe computer vision, Gemini AI chat, and a full clinical session tracking system.

---

## 🎯 What This App Does

### For the Child 🧒
- **اتبع الحركة (Movement)** — Real-time hand-tracking game powered by on-device MediaPipe AI. The child moves their hand to reach color-coded targets on screen. The engine measures accuracy, reaction time, and repetition count with millisecond precision.
- **اسمع وابحث (Attention)** — Multi-round audio + visual attention training. The child hears a target word/sound and must identify the matching shape or image from a set of options.
- **قولها معايا (Speech)** — Interactive speech articulation practice (AI analysis module in development).

### For the Parent 👨‍👩‍👧
- Full child profile management with custom avatar and health data
- Daily session launcher with activity instructions
- Real-time session results with AI-analyzed performance score, difficulty adjustment recommendations, and supportive observations
- Parent sentiment rating after each session
- Progress dashboard with historical performance trends
- Connect with licensed doctors via QR code or connection code
- AI Advisory Chat (Gemini) for personalized therapy guidance in Arabic
- Google Sign-In support

---

## 🏗️ Architecture

```
flutter-app/lib/
├── main.dart                        ← App entry point, ScreenUtil init, route
├── core/
│   ├── config/                      ← API config, environment (dart-define)
│   ├── constants/api_endpoints.dart ← Centralized endpoint registry
│   ├── models/                      ← Strongly-typed DTOs (session, activity, child, progress)
│   ├── network/api_client.dart      ← Dio HTTP client with JWT interceptor
│   ├── services/                    ← Auth, Children, Session, Activity services
│   ├── state/auth_state.dart        ← Global auth state (ChangeNotifier)
│   ├── storage/secure_storage.dart  ← JWT + child ID in flutter_secure_storage
│   ├── attention/                   ← Attention engine + audio service
│   └── errors/api_exception.dart    ← Typed API error handling
│
├── features/
│   └── movement/
│       ├── engine/movement_engine.dart         ← Dart port of Python MovementEngine
│       ├── services/hand_tracker_service.dart  ← MediaPipe camera integration
│       ├── widgets/interactive_target_arena.dart ← Live game UI widget
│       └── models/movement_session_result.dart
│
├── screens/                         ← 42 production screens
│   ├── splash.dart / onboarding_screen.dart
│   ├── log_in_screen.dart / sign_up_screen.dart
│   ├── verify_email_screen.dart / otp_verification_screen.dart
│   ├── home_screen.dart             ← Main nav hub (5 tabs)
│   ├── practise_screen.dart         ← Exercise selection (تمارين اليوم)
│   ├── session_execution_screen.dart ← Live session runner (all domains)
│   ├── session_encouragement_screen.dart
│   ├── session_result_screen.dart   ← AI results + domain badges
│   ├── parent_observation_screen.dart ← Post-session parent rating
│   ├── attention_screen.dart        ← Multi-round attention game
│   ├── movement_screen.dart         ← Movement exercise entry
│   ├── ai_chat_screen.dart          ← Gemini AI parent advisory chat
│   ├── progress_screen.dart         ← Historical trends + domain analytics
│   ├── profile_screen.dart / settings_screen.dart
│   ├── scan_qr_screen.dart          ← Doctor connection via QR
│   └── ... 28 more screens
│
└── widgets/                         ← Reusable design system components
```

---

## 🤖 On-Device AI: MediaPipe Movement Tracking

The movement exercise runs **entirely on-device** with zero server calls during gameplay:

```
Camera Frame
    ↓
HandTrackerService (MediaPipe via camera plugin)
    ↓
HandTrackingResult { x, y, confidence, landmark8, landmark9 }
    ↓
MovementEngine (Dart state machine)
    ↓
InteractiveTargetArena (Flutter widget, 60 FPS)
    ↓
MovementSessionResult { accuracy%, reps, avgReactionMs }
```

| Metric | Description |
|--------|-------------|
| `accuracyPercentage` | `successful_hits / total_attempts × 100` |
| `repetitions` | Confirmed successful target reaches |
| `averageReactionTimeMs` | Mean time from target spawn → reach |
| `failedAttempts` | Targets that expired before being reached |

---

## 🌐 Backend Integration

All API calls go through a centralized **Dio** client with:
- JWT Bearer token auto-attached via interceptor
- Structured error parsing (`ApiException`)
- Production base URL injected via `--dart-define=API_BASE_URL=https://sawa-app.runasp.net`

```dart
// Zero hardcoded URLs - fully configurable at build time
const String _baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://10.0.2.2:5222',
);
```

---

## 📊 Session Flow

```
PractiseScreen
    → PractiseInstructionMovement/Attention/Speech
        → SessionExecutionScreen (live exercise)
            → SessionEncouragementScreen (أحسنت يا بطل!)
                → SessionResultScreen (AI score + domain badges)
                    → ParentObservationScreen (parent rating)
                        → HomeScreen
```

After every session:
1. Metrics sent to backend → Gemini AI analysis triggered
2. `overallPerformanceScore` displayed on result screen (real accuracy, not hardcoded)
3. Parent rates session difficulty (easy / medium / hard)
4. All data saved to MSSQL via the backend for the Doctor Dashboard to review

---

## 📦 Key Dependencies

| Package | Purpose |
|---------|---------|
| `dio` | HTTP client + JWT interceptor |
| `flutter_secure_storage` | Encrypted token storage |
| `flutter_screenutil` | Responsive scaling (all screens) |
| `camera` | Live camera feed for MediaPipe |
| `mobile_scanner` | QR code scanning for doctor connection |
| `google_sign_in` | Google OAuth2 sign-in |
| `audioplayers` | Attention exercise audio playback |
| `permission_handler` | Camera + microphone permissions |
| `pinput` | OTP input field (email verification) |

---

## 🔐 Security

- JWT stored in `flutter_secure_storage` (Android Keystore / iOS Keychain)
- Zero API keys or secrets in source code
- All keys injected via `--dart-define` at build time
- `flutter analyze` passes with **0 errors**

---

## 🏃 Building

### Development (emulator)
```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5222
```

### Production APK
```bash
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://sawa-app.runasp.net
```

APK output: `build/app/outputs/flutter-apk/app-release.apk`

### Verify build
```bash
# Confirm release (not debug)
apksigner verify --verbose app-release.apk

# Confirm production API embedded
strings libapp.so | grep sawa-app.runasp.net
```

---

## 📱 Supported Devices

- Android 6.0+ (API 23+)
- Tested on: Huawei nova 5T (Android 10, API 29)
- Camera required for Movement exercise
- Microphone required for Speech exercise (coming soon)
