# 🧠 Mindora Backend — ASP.NET Core Web API

![Live](https://img.shields.io/badge/API-Live-brightgreen) ![Platform](https://img.shields.io/badge/.NET-10-purple)

> **Production URL:** https://sawa-app.runasp.net  
> **Health Check:** https://sawa-app.runasp.net/health

A fully production-deployed, enterprise-grade REST API powering the entire Mindora platform — serving the Flutter mobile app, the Doctor Web Dashboard, and AI-driven rehabilitation session analytics.

---

## 🚀 What This Does

The Mindora backend is the **central nervous system** of the platform. It:

- Authenticates parents, doctors, and admins via **JWT Bearer tokens** with full **ASP.NET Core Identity**
- Manages child profiles, therapeutic activity catalogs, and real-time session lifecycle
- Receives raw session performance metrics from the Flutter app (repetition counts, accuracy %, reaction time) and pipes them to **Google Gemini AI** for intelligent analysis
- Delivers adaptive difficulty recommendations back to the app based on each child's actual performance
- Sends transactional emails (OTP verification, password reset) via **Brevo SMTP**
- Exposes a secure REST API that the **Doctor Dashboard** (Vercel) consumes in real-time
- Supports **Google OAuth2** sign-in for parents

---

## 🏗️ Architecture

```
Mindora.Domain           ← Pure entities, value objects, domain events (zero dependencies)
Mindora.Application      ← Use cases, CQRS handlers, DTOs, FluentValidation rules
Mindora.Infrastructure   ← EF Core, Identity, JWT, Brevo SMTP, Gemini AI, DB seeding
Mindora.Api              ← REST controllers, middleware, DI composition, RFC 7807 errors
```

### Design Patterns
- **Vertical Slice Architecture** — features grouped by intent (StartSession, CompleteSession, etc.)
- **CQRS** — separate command/query handlers per use case
- **Clean Architecture** — strict layer dependency rules
- **Repository + Unit of Work** — via EF Core `ApplicationDbContext`
- **RFC 7807 Problem Details** — standardized error responses across all endpoints

---

## 📡 API Endpoints

| Area | Method | Endpoint | Description |
|------|--------|----------|-------------|
| Auth | POST | `/api/auth/register` | Parent/Doctor registration |
| Auth | POST | `/api/auth/login` | Email + password login → JWT |
| Auth | POST | `/api/auth/verify-email` | OTP email verification |
| Auth | POST | `/api/auth/resend-otp` | Resend verification OTP |
| Auth | POST | `/api/auth/forgot-password` | Password reset email |
| Auth | POST | `/api/auth/reset-password` | Reset password with token |
| Auth | POST | `/api/auth/google` | Google OAuth2 sign-in |
| Auth | POST | `/api/auth/change-password` | Authenticated password change |
| Children | GET | `/api/children` | List parent's children |
| Children | POST | `/api/children` | Register a child |
| Children | GET | `/api/children/{id}` | Get child profile |
| Children | GET | `/api/children/{id}/progress` | AI-analyzed progress summary |
| Children | GET | `/api/children/{id}/progress/history` | Session history (paginated) |
| Activities | GET | `/api/activities` | List therapeutic activities |
| Sessions | POST | `/api/sessions` | Start a therapy session |
| Sessions | POST | `/api/sessions/{id}/complete` | Complete session + trigger AI analysis |
| Sessions | POST | `/api/sessions/{id}/feedback` | Submit parent sentiment rating |
| Sessions | POST | `/api/sessions/{id}/metrics` | Record performance metrics |
| Sessions | GET | `/api/sessions/{id}` | Get session details |
| Sessions | POST | `/api/sessions/{id}/abandon` | Abandon active session |
| AI | POST | `/api/ai/chat` | Gemini AI parent advisory chat |
| Doctor | GET | `/api/doctor/connection-requests` | View pending parent requests |
| Doctor | POST | `/api/doctor/connection-requests/{id}/accept` | Accept connection |
| Doctor | POST | `/api/doctor/connection-requests/{id}/reject` | Reject connection |
| Doctor | GET | `/api/doctor/children` | View connected children |
| Progress | GET | `/api/progress/{childId}` | Domain-level progress analytics |

---

## 🤖 AI Architecture — Two Distinct Subsystems

### 1. Advisory Chat (`POST /api/ai/chat`) — Google Gemini

The parent advisory chat calls **Google Gemini** (`gemini-3.6-flash`) directly via a typed `GeminiChatClient`. The system prompt is carefully engineered, not generic:

```
"أنت 'مساعد ميندورا الذكي' — رفيق ومرشد داعم لأولياء أمور أطفال متلازمة داون.
مهمتك تقديم إرشادات ونصائح تدريبية وتأهيلية مبسطة بأسلوب عربي ودودة ومحفزة.
ركز على التحفيز الحركي والنطق والتواصل والاستقلالية اليومية.
الردود إرشادية وليست تشخيصاً طبياً — في حال الأدوية أو حالات طارئة، وجّه لطبيب مختص."
```

Design decisions:
- **Clinically responsible** — explicitly prevents the model from acting as a medical authority
- **Domain-constrained** — scoped to motor, speech, communication, and daily independence
- **Egyptian Arabic dialect** — culturally appropriate for target users
- **Temperature 0.7** — balances creativity with factual reliability
- **Max 1024 tokens** — keeps responses focused and readable on mobile

### 2. Session Analysis — Resilient Multi-Layer Engine

Session analysis uses a **ResilientAiAnalysisService** (Decorator pattern):

```
CompleteSessionHandler
    ↓ gathers all metrics (stored + request-time)
    ↓ builds AiSessionAnalysisRequest (child age, domain, difficulty, metrics[])
    ↓ executed OUTSIDE DB transaction (critical — prevents AI timeout from killing DB write)
ResilientAiAnalysisService
    ├── ExternalAiProviderClient (configurable endpoint, 4s timeout)
    │       ↓ on success → validated scored JSON result
    └── MockAiAnalysisService (deterministic fallback, always succeeds)
            ↓ multi-dimensional heuristic analysis
```

The **deterministic heuristic engine** (`MockAiAnalysisService`) is NOT a stub — it implements real clinical logic:

| Signal | Analysis |
|--------|----------|
| `AccuracyPercentage` | Primary performance score |
| `SpeechClarityScore` | Combined with accuracy for speech domain |
| `ReactionTimeMs > 3000ms` + low score | Fatigue flag → score reduction + gentler pacing |
| `RepetitionCount` | Converted to score for movement domain |
| `AttentionDurationSeconds` | Converted to score for attention domain |

Outputs per session:
- `overallPerformanceScore` — domain-aware weighted score (0–100)
- `recommendedDifficultyAdjustment` — `Increase` / `Maintain` / `Decrease`
- `fatigueObserved` — boolean, triggers pacing parameter changes
- `supportiveObservations` — non-medical, encouraging text matched to domain and performance tier
- `adaptiveParametersJson` — `targetPacingSeconds`, `visualCueLevel`, `repetitionTarget`

### Key Engineering Decisions

- **AI executes OUTSIDE database transaction** — prevents AI timeout (4–30s) from holding DB locks or rolling back session completion
- **Idempotency** — if session already `Completed`, returns existing result without re-invoking AI (safe for retries)
- **IDOR Protection** — parent can only analyze their own child's sessions; doctor only if actively assigned
- **Score boundary validation** — external AI scores are validated `[0, 100]` before trust; invalid payloads trigger fallback
- **Zero demo downtime** — if Gemini/external AI is down, the heuristic engine produces a valid, meaningful result

---

## 🛡️ Security

- **JWT Bearer** authentication with configurable secret (minimum 32 chars)
- **Role-based authorization** (`Parent`, `Doctor`, `Admin`)
- **Zero hardcoded secrets** — all keys via environment variables or .NET User Secrets
- **FluentValidation** on all request DTOs
- **HTTPS enforced** in production

---

## ⚙️ Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | ASP.NET Core 10 |
| ORM | Entity Framework Core 10 |
| Database | Microsoft SQL Server |
| Identity | ASP.NET Core Identity |
| Auth | JWT Bearer + Google OAuth2 |
| AI | Google Gemini API |
| Email | Brevo SMTP |
| Validation | FluentValidation |
| Hosting | MonsterASP.NET (IIS) |

---

## 🏃 Running Locally

### Prerequisites
- .NET 10 SDK
- SQL Server (LocalDB or full)

### Setup

```powershell
# 1. Clone and navigate
cd backend/src/Mindora.Api

# 2. Set JWT secret (minimum 32 chars)
dotnet user-secrets set "Jwt:SecretKey" "YourDevSecretKey_AtLeast32Characters!"

# 3. Set connection string
dotnet user-secrets set "ConnectionStrings:DefaultConnection" "Server=(localdb)\\mssqllocaldb;Database=MindoraDb;Trusted_Connection=True;"

# 4. Restore, migrate and run
dotnet restore ../../Mindora.sln
dotnet ef database update
dotnet run
```

The API will be available at `http://localhost:5222` with Swagger at `/swagger`.

### Running Tests

```powershell
dotnet test backend/Mindora.sln
```

---

## 🌐 Production Deployment

Deployed to **MonsterASP.NET** via IIS with:
- `appsettings.Production.json` for non-secret config
- Environment variables for all secrets (JWT, Gemini, Brevo, ConnectionString)
- Auto-migration on startup
- DB seeding on first run (default activities, test accounts)

**Production:** https://sawa-app.runasp.net
