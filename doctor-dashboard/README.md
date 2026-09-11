# Mindora Project

Mindora is an AI-assisted rehabilitation, developmental support, and progress-tracking platform designed specifically for children with Down syndrome. The platform empowers children, supports parents in everyday routines, and gives healthcare professionals actionable clinical insights.

## Core Philosophy

> *"The App adapts to the child, not the child adapting to the App."*

Mindora emphasizes individualized adaptation, dynamic difficulty scaling, and positive reinforcement to match each child's developmental pace and sensory preferences.

## Three Focus Areas

1. **Movement**: Fine and gross motor coordination, balance exercises, posture guidance, and physical activity routines.
2. **Speech**: Articulation practice, phonological awareness, vocabulary building, and conversational exercises.
3. **Attention**: Visual and auditory focus training, cognitive engagement tasks, and sustained task attention exercises.

---

## Monorepo Repository Structure

```text
Mindora Project/
├── backend/                  # ASP.NET Core Web API, Domain, Application, Infrastructure & Tests
│   ├── Mindora.sln
│   ├── Mindora.slnx
│   ├── src/
│   │   ├── Mindora.Domain/
│   │   ├── Mindora.Application/
│   │   ├── Mindora.Infrastructure/
│   │   └── Mindora.Api/
│   └── tests/
│       ├── Mindora.UnitTests/
│       └── Mindora.IntegrationTests/
│
├── doctor-dashboard/         # React.js web dashboard for therapists, doctors, and clinicians
├── flutter-app/              # Flutter mobile application for Child and Parent experiences
├── ai/                       # Standalone AI/ML models, Python inference services, and training pipelines
├── docs/                     # Project-level architecture, API, and process documentation
│   ├── architecture/
│   ├── api/
│   └── project/
├── .gitignore                # Unified monorepo ignore rules
└── README.md                 # Project root documentation
```

---

## Technology Direction

- **Backend**:
  - ASP.NET Core Web API
  - .NET 10
  - Entity Framework Core 10
  - Microsoft SQL Server
  - ASP.NET Core Identity
  - JWT Bearer Authentication
  - FluentValidation
- **Mobile App**:
  - Flutter (Dart) for cross-platform iOS and Android experiences (Child interactive mode & Parent monitoring mode)
- **Doctor Web Dashboard**:
  - React.js consuming the ASP.NET Core Web API
- **AI / Machine Learning**:
  - Dedicated AI/model implementations (computer vision, acoustic speech analysis, attention tracking) integrated through backend contracts

---

## Backend Architecture

The backend is built upon clean, enterprise architectural patterns:

- **Modular Monolith**: Enforces logical boundary separation between functional capabilities while maintaining deployment simplicity.
- **Vertical Slice Architecture**: Features are organized cohesively by intent, grouping commands, queries, validators, and handlers.
- **Clean Layer Separation**:
  - `Mindora.Domain`: Pure domain entities, value objects, domain events, and business rules (zero external dependencies).
  - `Mindora.Application`: Use cases, CQRS requests/handlers, DTOs, interfaces, and FluentValidation rules.
  - `Mindora.Infrastructure`: EF Core DbContext, migrations, ASP.NET Core Identity, JWT token generation, external AI integration, and database seeding.
  - `Mindora.Api`: REST controllers, middleware, global RFC 7807 exception handling, and dependency injection composition.

---

## Local Development & Secret Configuration

To ensure zero-secret repository hygiene, production and development JWT secrets are not committed to source control.

The backend looks for the configuration key:
- Configuration path: `Jwt:SecretKey`
- Environment variable format: `Jwt__SecretKey`

### Setting up Your Local Secret

Configure a local development key (minimum 32 characters) using **.NET User Secrets** (recommended):

```powershell
cd backend/src/Mindora.Api
dotnet user-secrets set "Jwt:SecretKey" "YourDevelopmentSecretKeyWithAtLeast32Chars!"
```

Alternatively, set an environment variable in your terminal session:

```powershell
# PowerShell
$env:Jwt__SecretKey = "YourDevelopmentSecretKeyWithAtLeast32Chars!"

# Bash / Linux / macOS
export Jwt__SecretKey="YourDevelopmentSecretKeyWithAtLeast32Chars!"
```

---

## Team Development & Git Workflow

To maintain a clean and reliable codebase across teams:

- **Feature Branching**: Each team member works on an isolated branch following area naming conventions:
  - `feature/backend-<feature-name>`
  - `feature/flutter-<feature-name>`
  - `feature/dashboard-<feature-name>`
  - `feature/ai-<feature-name>`
- **Logical Commits**: Make concise, meaningful, atomic commits for completed changes.
- **Pre-Push Validation**: Always build and test code locally before pushing to the remote.
- **Pull Requests (PRs)**: All merges into `main` require a reviewed Pull Request.
- **Main Branch Protection**: Avoid committing directly or pushing unfinished work to `main`.

---

## Verification & Build Commands

Ensure the .NET 10 SDK is installed, then execute:

```powershell
# Restore backend packages
dotnet restore backend/Mindora.sln

# Build the complete solution
dotnet build backend/Mindora.sln

# Run all unit and integration test suites
dotnet test backend/Mindora.sln
```
