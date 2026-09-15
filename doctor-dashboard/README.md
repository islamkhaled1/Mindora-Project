# 🦷 Mindora Doctor Dashboard

![Live](https://img.shields.io/badge/Dashboard-Live-brightgreen) ![Platform](https://img.shields.io/badge/React-19-blue) ![Vercel](https://img.shields.io/badge/Vercel-Deployed-black)

> **Live Production URL:** https://doctor-dashboard-kappa-dun.vercel.app  
> **Backend API:** https://sawa-app.runasp.net  
> **Deployed on:** Vercel (auto-deploy from GitHub `main`)

A React + TypeScript web dashboard for licensed therapists and doctors to manage patient connections, monitor children's therapy progress, and review AI-analyzed session performance — all in real-time from a clean, responsive clinical interface.

---

## 🎯 What This Does

The Doctor Dashboard gives healthcare professionals a dedicated clinical workspace to:

- **Register & authenticate** as a licensed doctor with email verification (OTP flow)
- **Receive connection requests** from parents who want to link their child to a doctor
- **Accept or reject** connection requests with full parent/child context
- **View connected children** with their profile data and therapy history
- **Review AI-analyzed session performance** — scores, difficulty adjustments, fatigue detection, domain trends
- **Manage account** — change password, profile settings
- **Reset forgotten password** via secure email token flow

---

## 🏗️ Architecture

```
doctor-dashboard/
├── src/
│   ├── App.tsx                      ← Router, auth guard, page layout
│   ├── api/                         ← Typed API client (fetch-based)
│   ├── pages/
│   │   ├── LoginPage.tsx            ← Doctor login with JWT
│   │   ├── RegisterPage.tsx         ← Doctor registration (specialization, license, etc.)
│   │   ├── VerifyEmailPage.tsx      ← OTP email verification
│   │   ├── VerifyOtpPage.tsx        ← OTP input (pinput-style)
│   │   ├── ForgotPasswordPage.tsx   ← Request password reset email
│   │   ├── ResetPasswordPage.tsx    ← Set new password via secure token
│   │   ├── ChangePasswordPage.tsx   ← Authenticated password change
│   │   ├── DashboardOverviewPage.tsx ← Home overview after login
│   │   ├── ConnectionRequestsPage.tsx ← Pending / accepted / rejected requests
│   │   ├── ChildrenDirectoryPage.tsx ← All connected children
│   │   └── ChildDetailPage.tsx      ← Individual child profile + sessions
│   ├── components/                  ← Shared UI components
│   ├── services/                    ← Auth service, storage helpers
│   ├── types/                       ← TypeScript interfaces matching backend DTOs
│   └── utils/                       ← Date formatting, validators
├── index.html
├── vite.config.ts                   ← Vite build config
├── vercel.json                      ← SPA routing config for Vercel
└── .env.example                     ← Required environment variables
```

---

## 📡 Backend Integration

All API calls target the production backend at `https://sawa-app.runasp.net`:

| Feature | Endpoint |
|---------|----------|
| Doctor login | `POST /api/auth/login` |
| Doctor register | `POST /api/auth/register` |
| Email verification | `POST /api/auth/verify-email` |
| Resend OTP | `POST /api/auth/resend-otp` |
| Forgot password | `POST /api/auth/forgot-password` |
| Reset password | `POST /api/auth/reset-password` |
| Change password | `POST /api/auth/change-password` |
| Connection requests | `GET /api/doctor/connection-requests` |
| Accept request | `POST /api/doctor/connection-requests/{id}/accept` |
| Reject request | `POST /api/doctor/connection-requests/{id}/reject` |
| Connected children | `GET /api/doctor/children` |
| Child details | `GET /api/children/{id}` |
| Child progress | `GET /api/children/{id}/progress` |

JWT token is stored in `localStorage` and attached to every authenticated request via `Authorization: Bearer <token>`.

---

## 🔐 Auth Flow

```
Register → Email OTP Verification → Login → JWT stored → Dashboard
                                              ↓
                              Protected routes via auth guard in App.tsx
```

Password reset flow:
```
Forgot Password (email) → Backend sends reset link → ResetPasswordPage → New password set
```

---

## ⚙️ Tech Stack

| Technology | Purpose |
|-----------|---------|
| React 19 | UI framework |
| TypeScript 6 | Type safety across all components and API calls |
| React Router v7 | Client-side routing + auth guards |
| Vite 8 | Build tool + dev server |
| Tailwind CSS v4 | Utility-first styling |
| Lucide React | Icon library |
| QRCode React | QR code display for doctor connection codes |
| Vercel | Hosting + CI/CD |

---

## 🚀 Running Locally

```bash
# 1. Install dependencies
cd doctor-dashboard
npm install

# 2. Configure environment
cp .env.example .env
# Set VITE_API_BASE_URL=https://sawa-app.runasp.net

# 3. Start dev server
npm run dev
# → http://localhost:5173
```

### Build for Production

```bash
npm run build
# Output: dist/
```

---

## 🌐 Deployment (Vercel)

The dashboard is deployed to Vercel with automatic deploys on every push to `main`:

1. **Build command:** `npm run build`
2. **Output directory:** `dist`
3. **Environment variable:** `VITE_API_BASE_URL=https://sawa-app.runasp.net`
4. **SPA routing:** `vercel.json` rewrites all routes to `index.html`

```json
// vercel.json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

**Live URL:** https://doctor-dashboard-kappa-dun.vercel.app

---

## 🔒 Security Notes

- JWT stored in `localStorage` (scoped to production origin)
- CORS configured on backend to allow the exact Vercel production origin
- No secrets or API keys committed to source — environment variable only
- `.env` is in `.gitignore`

---

## 📋 Doctor Registration Fields

When a doctor registers, they provide:
- Full name, email, password
- Medical specialization (e.g., "طب أطفال", "علاج طبيعي")
- Years of experience
- License/certificate number
- Phone number
- Profile photo (optional)

All validated on both client and server (FluentValidation).

---

## 🩻 Connection Request Workflow

```
Parent (Flutter App)
    → Scans doctor QR code or enters connection code
        → Backend creates pending ConnectionRequest
            → Doctor sees it in ConnectionRequestsPage
                → Accepts → Child linked to doctor account
                → Rejects → Request closed
```

Once connected, the doctor has full read access to:
- The child's profile (name, age, diagnosis details)
- All completed therapy sessions and their AI analysis
- Domain-specific progress trends (Movement, Attention, Speech)
- Parent sentiment ratings per session
