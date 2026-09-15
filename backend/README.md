# 🧠 Mindora Backend — ASP.NET Core Web API

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

## 🤖 Gemini AI Integration

After each therapy session, the backend automatically:
1. Receives raw metrics (accuracy %, reps, reaction time ms)
2. Constructs a structured prompt for **Google Gemini**
3. Receives JSON analysis: `overallPerformanceScore`, `recommendedDifficultyAdjustment`, `supportiveObservations`, `fatigueObserved`
4. Persists the analysis result and returns it to the Flutter app

If Gemini is unavailable, a **deterministic fallback engine** computes the analysis locally — ensuring zero downtime.

---

## 📧 Email Service (Brevo SMTP)

- OTP codes for email verification (6-digit, 15-min expiry)
- Password reset links with secure tokens
- HTML-templated emails

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
