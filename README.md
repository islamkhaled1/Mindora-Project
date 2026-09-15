# 🌟 Mindora — AI-Powered Rehabilitation Platform for Children with Down Syndrome

> *"The App adapts to the child, not the child adapting to the App."*

**Mindora** is a full-stack AI-powered rehabilitation and developmental support platform purpose-built for children with Down syndrome. It connects children, parents, and licensed therapists in a unified ecosystem powered by real-time computer vision, Gemini AI, and clinical session analytics.

---

## 🎥 Live Deployments

| Component | URL |
|-----------|-----|
| 📱 Flutter App (Android APK) | [⬇️ Download from MediaFire](https://www.mediafire.com/file/j4fd7xcmoqoveez/Sawa_App.apk/file) |
| 🌐 Doctor Dashboard | https://doctor-dashboard-kappa-dun.vercel.app |
| ⚙️ Backend API | https://sawa-app.runasp.net |
| 🏥 API Health | https://sawa-app.runasp.net/health |

---

## 🧩 Platform Overview

Mindora addresses three core developmental domains for children with Down syndrome:

| Domain | Exercise | Technology |
|--------|----------|-----------|
| 🏃 **Movement** | اتبع الحركة — Hand-tracking target game | MediaPipe Hands (on-device, real-time) |
| 🧠 **Attention** | اسمع وابحث — Audio-visual matching rounds | Custom attention engine + TTS |
| 🗣️ **Speech** | قولها معايا — Articulation practice | MFCC + scikit-learn classifier |

---

## 🏗️ System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    MINDORA PLATFORM                          │
├─────────────────┬──────────────┬────────────────────────────┤
│  Flutter App    │   Backend    │    Doctor Dashboard        │
│  (Android/iOS)  │  ASP.NET 10  │    React 19 + TypeScript   │
│                 │  MSSQL       │    Vercel                  │
│  Parent Mode    │  JWT + Identity    Live at Vercel URL     │
│  Child Mode     │  Gemini AI   │                            │
│  MediaPipe AI   │  Brevo SMTP  │                            │
└────────┬────────┴──────┬───────┴────────────────────────────┘
         │               │
         └───────────────┘
              REST API
         https://sawa-app.runasp.net
```

---

## 📁 Monorepo Structure

```
Mindora Project/
├── backend/               ← ASP.NET Core 10 Web API (Clean Architecture)
│   ├── src/
│   │   ├── Mindora.Domain/        ← Entities, value objects (zero dependencies)
│   │   ├── Mindora.Application/   ← CQRS handlers, use cases, FluentValidation
│   │   ├── Mindora.Infrastructure/← EF Core, Identity, JWT, Gemini, Brevo SMTP
│   │   └── Mindora.Api/           ← REST controllers, middleware, DI
│   └── tests/                     ← Unit + Integration tests
│
├── flutter-app/           ← Flutter mobile app (Android + iOS)
│   └── lib/
│       ├── core/          ← API client, services, models, auth state
│       ├── features/      ← movement/ (MediaPipe engine, Dart port)
│       ├── screens/       ← 42 production screens
│       └── widgets/       ← Design system components
│
├── doctor-dashboard/      ← React + TypeScript SPA (Vite + Tailwind CSS v4)
│   └── src/
│       ├── pages/         ← 11 pages (auth, connections, children, progress)
│       ├── api/           ← Typed fetch-based API client
│       └── components/    ← Shared UI components
│
├── ai/                    ← Python AI/ML models & inference
│   ├── movement_engine.py ← Deterministic state machine (ported to Dart)
│   ├── computervision.py  ← MediaPipe desktop demo
│   ├── chatbot.py         ← LLaMA 3.1 Arabic advisory chatbot
│   ├── live_speech.py     ← MFCC speech recognition
│   └── speech_model.pkl   ← Pre-trained sklearn classifier
│
└── docs/                  ← Architecture, API, and process documentation
```

---

## 🌟 Key Technical Highlights

### 1. On-Device AI (Zero Latency Movement Tracking)
The `MovementEngine` algorithm was developed in Python (`ai/movement_engine.py`) then **ported to Dart** and runs entirely on the child's device with no internet required during exercises. MediaPipe Hands detects 21 hand landmarks at 30+ FPS, feeding a 4-state deterministic machine that tracks accuracy, reaction time, and repetition count in real time.

### 2. Gemini AI Session Analysis
After every therapy session, the backend automatically calls **Google Gemini** with the child's raw metrics and receives structured JSON:
- `overallPerformanceScore` — displayed on the results screen
- `recommendedDifficultyAdjustment` — Increase / Maintain / Decrease
- `supportiveObservations` — personalized Arabic feedback
- `fatigueObserved` — boolean flag for parent awareness

A deterministic fallback engine ensures zero downtime if Gemini is unavailable.

### 3. Full Clinical Session Lifecycle
```
Start Session → Live Exercise → Submit Metrics → AI Analysis → 
Encouragement → Results → Parent Rating → Doctor Review
```

Every step is persisted to SQL Server and visible to the connected doctor on the web dashboard.

### 4. Brevo SMTP Transactional Email
All email verification, OTP delivery, and password reset links are handled via Brevo SMTP with HTML-templated emails in Arabic.

### 5. Production-Ready Security
- JWT Bearer + ASP.NET Core Identity
- Role-based auth: Parent / Doctor / Admin
- Encrypted token storage (Android Keystore via `flutter_secure_storage`)
- Zero secrets in source code (all via environment variables)
- RFC 7807 Problem Details for consistent API error responses

---

## 🚀 Quick Start

### Backend
```powershell
cd backend/src/Mindora.Api
dotnet user-secrets set "Jwt:SecretKey" "YourDevSecretKey_AtLeast32Characters!"
dotnet run
# → http://localhost:5222
```

### Flutter App
```bash
cd flutter-app
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5222
```

### Doctor Dashboard
```bash
cd doctor-dashboard
npm install
npm run dev
# → http://localhost:5173
```

### AI Module
```bash
cd ai
pip install -r requirements.txt
python computervision.py    # Movement demo (requires webcam)
python chatbot.py           # Arabic chatbot
python live_speech.py       # Speech recognition (requires mic)
```

---

## 👥 Team & Domains

| Domain | Component |
|--------|-----------|
| Backend & Architecture | ASP.NET Core API + Clean Architecture |
| Mobile Development | Flutter (Dart) — Child & Parent experience |
| Web Development | React + TypeScript — Doctor Dashboard |
| AI / ML Engineering | Python — MediaPipe, Speech, LLM Chatbot |

---

## 🏥 Clinical Impact

Mindora is not a generic app — it is purpose-built for Down syndrome rehabilitation:

- **Adaptive difficulty** — AI adjusts exercise challenge based on real performance, not fixed schedules
- **Positive reinforcement** — Encouragement screens, celebration animations, supportive AI observations
- **Clinician oversight** — Doctors review AI-analyzed reports, not raw data — saving clinical time
- **Parent empowerment** — Arabic-language AI advisor guides parents between sessions
- **Zero technical barrier** — Children interact through movement and sound, no reading required

---

## 📊 Production Statistics

| Metric | Value |
|--------|-------|
| Backend uptime | MonsterASP.NET (24/7) |
| API endpoints | 25+ REST endpoints |
| Flutter screens | 42 production screens |
| Doctor Dashboard pages | 11 pages |
| APK size | 112 MB (release, signed) |
| AI models | MediaPipe (7.8MB), Speech classifier (436KB) |
| Test coverage | Unit + Integration tests (backend + Flutter) |
