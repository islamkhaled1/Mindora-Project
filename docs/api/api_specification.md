# Mindora API Specification & Integration Contract

## 1. Overview & Architecture

This document defines the complete integration contract for the Mindora .NET 10 Web API. It serves as the primary technical specification for frontend integration across:
1. **Flutter Child App** (Mobile / Tablet client for therapy sessions, metric streaming, and child progress)
2. **React + Tailwind Doctor Dashboard** (Web client for pediatric therapists and specialists to observe longitudinal performance, adherence trends, and activity analytics)

### Base URLs & Environment
- **Development HTTP**: `http://localhost:5222`
- **Development HTTPS**: `https://localhost:7147`
- **Health Check Probe**: `GET /health` (Public, returns `{"status":"Healthy"}`)

### Authentication & Token Usage
- **Format**: JSON Web Token (JWT) Bearer token via `Authorization: Bearer <token>` HTTP header.
- **Expiry**: Development tokens are valid for 60 minutes.
- **Roles**:
  - `Parent`: Can manage children, generate linking codes, assign doctors, initiate sessions, record telemetry, and view owned child progress.
  - `Doctor`: Can view assigned children, redeem linking codes, view dashboard aggregates, review longitudinal progress, and inspect activity performance.

### Standard Error Response (RFC 7807 Problem Details)
All non-2xx responses adhere to the standard ASP.NET Core `ProblemDetails` specification:
```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.5",
  "title": "Not Found",
  "status": 404,
  "detail": "Child with id 'c8a2b53a-0e9e-4c72-9a67-84bc13328e7e' was not found."
}
```
Validation error responses (HTTP 400):
```json
{
  "type": "https://tools.ietf.org/html/rfc9110#section-15.5.1",
  "title": "Validation Error",
  "status": 400,
  "detail": "One or more validation errors occurred.",
  "errors": {
    "Email": ["'Email' is not a valid email address."]
  }
}
```

---

## 2. Authentication Endpoints (`api/auth`)

### 2.1 Register Parent
- **Method**: `POST`
- **Route**: `/api/auth/register-parent`
- **Authentication**: None (Anonymous)
- **Authorization**: Public
- **Request Body**:
  ```json
  {
    "email": "sarah.parent@example.com",
    "password": "Password123!",
    "fullName": "Sarah Jenkins",
    "phoneNumber": "+15551234567"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAtUtc": "2026-09-07T06:00:00Z",
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "email": "sarah.parent@example.com",
      "fullName": "Sarah Jenkins",
      "role": "Parent",
      "profileId": "7b89f53e-3241-45cd-8ef0-9e6b36021d74"
    }
  }
  ```
- **Errors**:
  - `400 Bad Request`: Validation failure (e.g. invalid email format, weak password).
  - `409 Conflict`: Email already registered.

### 2.2 Register Doctor
- **Method**: `POST`
- **Route**: `/api/auth/register-doctor`
- **Authentication**: None (Anonymous)
- **Authorization**: Public
- **Request Body**:
  ```json
  {
    "email": "dr.smith@example.com",
    "password": "Password123!",
    "fullName": "Dr. Marcus Smith",
    "specialization": "Pediatric Physical Therapy",
    "clinicName": "Children's Developmental Center",
    "licenseNumber": "PT-98421"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAtUtc": "2026-09-07T06:00:00Z",
    "user": {
      "id": "4fa85f64-5717-4562-b3fc-2c963f66afa7",
      "email": "dr.smith@example.com",
      "fullName": "Dr. Marcus Smith",
      "role": "Doctor",
      "profileId": "8c89f53e-3241-45cd-8ef0-9e6b36021d75"
    }
  }
  ```
- **Errors**:
  - `400 Bad Request`: Validation failure.
  - `409 Conflict`: Email already registered.

### 2.3 Login
- **Method**: `POST`
- **Route**: `/api/auth/login`
- **Authentication**: None (Anonymous)
- **Authorization**: Public
- **Request Body**:
  ```json
  {
    "email": "sarah.parent@example.com",
    "password": "Password123!"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "expiresAtUtc": "2026-09-07T06:00:00Z",
    "user": {
      "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "email": "sarah.parent@example.com",
      "fullName": "Sarah Jenkins",
      "role": "Parent",
      "profileId": "7b89f53e-3241-45cd-8ef0-9e6b36021d74"
    }
  }
  ```
- **Errors**:
  - `400 Bad Request`: Empty email or password.
  - `401 Unauthorized`: Invalid credentials.

### 2.4 Get Current User Profile (`/me`)
- **Method**: `GET`
- **Route**: `/api/auth/me`
- **Authentication**: Bearer Token
- **Authorization**: Authenticated Users (`Parent` or `Doctor`)
- **Request Body**: None
- **Response**: `200 OK`
  ```json
  {
    "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "email": "sarah.parent@example.com",
    "fullName": "Sarah Jenkins",
    "role": "Parent",
    "profileId": "7b89f53e-3241-45cd-8ef0-9e6b36021d74"
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Missing or invalid token.

---

## 3. Children Management Endpoints (`api/children`)

### 3.1 Create Child Profile
- **Method**: `POST`
- **Route**: `/api/children`
- **Authentication**: Bearer Token
- **Authorization**: `Parent` role only
- **Request Body**:
  ```json
  {
    "fullName": "Leo Jenkins",
    "dateOfBirth": "2019-04-15",
    "supportNotes": "Loves visual cues and counting games",
    "baselineMovementLevel": "Beginner",
    "baselineSpeechLevel": "Beginner",
    "baselineAttentionLevel": "Beginner"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "id": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "parentId": "7b89f53e-3241-45cd-8ef0-9e6b36021d74",
    "fullName": "Leo Jenkins",
    "dateOfBirth": "2019-04-15",
    "supportNotes": "Loves visual cues and counting games",
    "currentMovementLevel": "Beginner",
    "currentSpeechLevel": "Beginner",
    "currentAttentionLevel": "Beginner",
    "createdAtUtc": "2026-09-07T05:00:00Z"
  }
  ```
- **Errors**:
  - `400 Bad Request`: Validation failure (e.g. invalid date of birth).
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Parent.

### 3.2 List Parent's Children
- **Method**: `GET`
- **Route**: `/api/children`
- **Authentication**: Bearer Token
- **Authorization**: `Parent` role only
- **Request Body**: None
- **Response**: `200 OK`
  ```json
  [
    {
      "id": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
      "fullName": "Leo Jenkins",
      "dateOfBirth": "2019-04-15",
      "currentMovementLevel": "Beginner",
      "currentSpeechLevel": "Beginner",
      "currentAttentionLevel": "Beginner",
      "createdAtUtc": "2026-09-07T05:00:00Z"
    }
  ]
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Parent.

### 3.3 Get Child Details
- **Method**: `GET`
- **Route**: `/api/children/{childId}`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `childId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "id": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "parentId": "7b89f53e-3241-45cd-8ef0-9e6b36021d74",
    "fullName": "Leo Jenkins",
    "dateOfBirth": "2019-04-15",
    "supportNotes": "Loves visual cues and counting games",
    "currentMovementLevel": "Beginner",
    "currentSpeechLevel": "Beginner",
    "currentAttentionLevel": "Beginner",
    "createdAtUtc": "2026-09-07T05:00:00Z",
    "assignedDoctors": [
      {
        "doctorId": "8c89f53e-3241-45cd-8ef0-9e6b36021d75",
        "specialization": "Pediatric Physical Therapy",
        "clinicName": "Children's Developmental Center",
        "assignedAtUtc": "2026-09-07T05:10:00Z"
      }
    ]
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Child does not exist OR caller is not authorized (IDOR prevention).

### 3.4 Soft-Delete Child Profile
- **Method**: `DELETE`
- **Route**: `/api/children/{childId}`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent only
- **Route Parameters**: `childId` (Guid)
- **Response**: `204 No Content`
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Parent.
  - `404 Not Found`: Child not found or parent does not own child.

### 3.5 Generate Doctor Linking Code
- **Method**: `POST`
- **Route**: `/api/children/{childId}/linking-code`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent only
- **Route Parameters**: `childId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "code": "MK78XP",
    "expiresAtUtc": "2026-09-09T05:00:00Z",
    "createdAtUtc": "2026-09-07T05:00:00Z"
  }
  ```
- **Notes**: Code is 6 uppercase alphanumeric characters, valid for 48 hours.
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Parent.
  - `404 Not Found`: Child does not exist or parent does not own child.

### 3.6 Direct Assign Doctor (Parent-Initiated)
- **Method**: `POST`
- **Route**: `/api/children/{childId}/assign-doctor`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent only
- **Request Body**:
  ```json
  {
    "doctorId": "8c89f53e-3241-45cd-8ef0-9e6b36021d75"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "id": "e5b6a789-0123-4567-89ab-cdef01234567",
    "doctorId": "8c89f53e-3241-45cd-8ef0-9e6b36021d75",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "assignedAtUtc": "2026-09-07T05:15:00Z",
    "isActive": true
  }
  ```
- **Errors**:
  - `400 Bad Request`: Empty Doctor ID.
  - `404 Not Found`: Child or Doctor does not exist.
  - `409 Conflict`: Doctor is already actively assigned to this child.

### 3.7 Get Child Activity Performance
- **Method**: `GET`
- **Route**: `/api/children/{childId}/activities/performance`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `childId` (Guid)
- **Response**: `200 OK`
  ```json
  [
    {
      "activityId": "11111111-1111-1111-1111-111111111111",
      "activityTitle": "Animal Reach & Stretch",
      "domain": "Movement",
      "baseDifficulty": "Beginner",
      "timesPlayed": 8,
      "totalPracticeMinutes": 32,
      "averageScore": 88.50,
      "bestScore": 96.00,
      "latestScore": 92.00,
      "averageAccuracyPercentage": 89.20,
      "averageReactionTimeMs": 1450.00,
      "averageRepetitions": 12.50,
      "lastPlayedUtc": "2026-09-06T14:30:00Z"
    }
  ]
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Child not found or caller not authorized.

---

## 4. Activities Catalogue Endpoints (`api/activities`)

### 4.1 List Activities
- **Method**: `GET`
- **Route**: `/api/activities`
- **Authentication**: Bearer Token
- **Authorization**: Authenticated Users (`Parent` or `Doctor`)
- **Query Parameters**:
  - `domain` (optional, string): `Movement`, `Speech`, `Attention`
  - `difficulty` (optional, string): `Beginner`, `Intermediate`, `Advanced`
- **Example URL**: `/api/activities?domain=Movement&difficulty=Beginner`
- **Response**: `200 OK`
  ```json
  [
    {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Animal Reach & Stretch",
      "description": "Fun motor exercise reaching for animal targets on screen.",
      "domain": "Movement",
      "baseDifficulty": "Beginner",
      "adaptiveSettingsJson": "{\"targetPacingSeconds\":4,\"visualCueLevel\":\"Standard\",\"repetitionTarget\":8}",
      "createdAtUtc": "2026-09-01T00:00:00Z"
    }
  ]
  ```
- **Errors**:
  - `400 Bad Request`: Invalid domain or difficulty enum string.
  - `401 Unauthorized`: Unauthenticated.

### 4.2 Get Activity Details By ID
- **Method**: `GET`
- **Route**: `/api/activities/{activityId}`
- **Authentication**: Bearer Token
- **Authorization**: Authenticated Users (`Parent` or `Doctor`)
- **Route Parameters**: `activityId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "id": "11111111-1111-1111-1111-111111111111",
    "title": "Animal Reach & Stretch",
    "description": "Fun motor exercise reaching for animal targets on screen.",
    "domain": "Movement",
    "baseDifficulty": "Beginner",
    "adaptiveSettingsJson": "{\"targetPacingSeconds\":4,\"visualCueLevel\":\"Standard\",\"repetitionTarget\":8}",
    "createdAtUtc": "2026-09-01T00:00:00Z"
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Activity does not exist or is inactive.

---

## 5. Therapy Sessions Endpoints (`api/sessions`)

### 5.1 Start Adaptive Session
- **Method**: `POST`
- **Route**: `/api/sessions`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Request Body**:
  ```json
  {
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "activityId": "11111111-1111-1111-1111-111111111111"
  }
  ```
- **Response**: `201 Created`
  ```json
  {
    "id": "f2e4d6c8-1234-5678-90ab-cdef01234567",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "activityId": "11111111-1111-1111-1111-111111111111",
    "domain": "Movement",
    "status": "InProgress",
    "startTimeUtc": "2026-09-07T05:30:00Z",
    "targetDifficulty": "Intermediate",
    "adaptiveSettingsJson": "{\"targetPacingSeconds\":3,\"visualCueLevel\":\"Standard\",\"repetitionTarget\":10,\"pacingNotes\":\"Progressive pacing with increased challenge\"}"
  }
  ```
- **Adaptive Mechanism**:
  - Checks previous completed session's `RecommendedDifficultyAdjustment`.
  - Computes `TargetDifficulty` and forwards `AdaptiveSettingsJson`.
  - Child baseline in DB is not mutated.
- **Errors**:
  - `400 Bad Request`: Validation failure.
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Child or Activity not found, or caller not authorized.

### 5.2 Record Live Telemetry Metrics
- **Method**: `POST`
- **Route**: `/api/sessions/{sessionId}/metrics`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `sessionId` (Guid)
- **Request Body**:
  ```json
  {
    "metrics": [
      { "metricType": "RepetitionCount", "value": 1.0 },
      { "metricType": "AccuracyPercentage", "value": 94.5 },
      { "metricType": "ReactionTimeMs", "value": 1250.0 }
    ]
  }
  ```
- **Response**: `200 OK`
  ```json
  [
    {
      "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "metricType": "RepetitionCount",
      "value": 1.0,
      "timestampUtc": "2026-09-07T05:31:10Z"
    },
    {
      "id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e",
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "metricType": "AccuracyPercentage",
      "value": 94.5,
      "timestampUtc": "2026-09-07T05:31:10Z"
    },
    {
      "id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f",
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "metricType": "ReactionTimeMs",
      "value": 1250.0,
      "timestampUtc": "2026-09-07T05:31:10Z"
    }
  ]
  ```
- **Errors**:
  - `400 Bad Request`: Empty metric list or invalid metric type.
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Session not found or caller not authorized.
  - `409 Conflict`: Session is not in `InProgress` status.

### 5.3 Complete Session & Trigger AI Analysis
- **Method**: `POST`
- **Route**: `/api/sessions/{sessionId}/complete`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `sessionId` (Guid)
- **Request Body**:
  ```json
  {
    "actualDurationSeconds": 240,
    "metrics": [
      { "metricType": "AccuracyPercentage", "value": 92.0 },
      { "metricType": "RepetitionCount", "value": 10.0 }
    ]
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "id": "f2e4d6c8-1234-5678-90ab-cdef01234567",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "activityId": "11111111-1111-1111-1111-111111111111",
    "domain": "Movement",
    "status": "Completed",
    "startTimeUtc": "2026-09-07T05:30:00Z",
    "endTimeUtc": "2026-09-07T05:34:00Z",
    "actualDurationSeconds": 240,
    "analysisResult": {
      "id": "789abcde-f012-3456-789a-bcdef0123456",
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "overallPerformanceScore": 92.00,
      "domainScore": 92.00,
      "supportiveObservations": "Exceptional engagement and high accuracy demonstrated in motor coordination. The child is ready for adaptive challenge progression.",
      "fatigueObserved": false,
      "recommendedDifficultyAdjustment": "Increase",
      "adaptiveParametersJson": "{\"targetPacingSeconds\":3,\"visualCueLevel\":\"Standard\",\"repetitionTarget\":10,\"pacingNotes\":\"Progressive pacing with increased challenge\"}",
      "analyzedAtUtc": "2026-09-07T05:34:01Z",
      "isFallbackResult": false
    },
    "metrics": [
      {
        "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "RepetitionCount",
        "value": 1.0,
        "timestampUtc": "2026-09-07T05:31:10Z"
      },
      {
        "id": "b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "AccuracyPercentage",
        "value": 94.5,
        "timestampUtc": "2026-09-07T05:31:10Z"
      },
      {
        "id": "c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "ReactionTimeMs",
        "value": 1250.0,
        "timestampUtc": "2026-09-07T05:31:10Z"
      },
      {
        "id": "d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "AccuracyPercentage",
        "value": 92.0,
        "timestampUtc": "2026-09-07T05:34:00Z"
      },
      {
        "id": "e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "RepetitionCount",
        "value": 10.0,
        "timestampUtc": "2026-09-07T05:34:00Z"
      }
    ]
  }
  ```
- **Idempotency**: If called on an already completed session, returns the existing analysis and metrics without re-running AI.
- **Errors**:
  - `400 Bad Request`: Duration <= 0.
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Session not found or caller not authorized.
  - `409 Conflict`: Session is abandoned.

### 5.4 Abandon Session
- **Method**: `POST`
- **Route**: `/api/sessions/{sessionId}/abandon`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `sessionId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "id": "f2e4d6c8-1234-5678-90ab-cdef01234567",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "activityId": "11111111-1111-1111-1111-111111111111",
    "domain": "Movement",
    "status": "Abandoned",
    "startTimeUtc": "2026-09-07T05:30:00Z",
    "targetDifficulty": null,
    "adaptiveSettingsJson": null
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Session not found or caller not authorized.
  - `409 Conflict`: Session is already Completed or Abandoned.

### 5.5 Get Session Details
- **Method**: `GET`
- **Route**: `/api/sessions/{sessionId}`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `sessionId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "id": "f2e4d6c8-1234-5678-90ab-cdef01234567",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "activity": {
      "id": "11111111-1111-1111-1111-111111111111",
      "title": "Animal Reach & Stretch",
      "domain": "Movement",
      "baseDifficulty": "Beginner"
    },
    "domain": "Movement",
    "status": "Completed",
    "startTimeUtc": "2026-09-07T05:30:00Z",
    "endTimeUtc": "2026-09-07T05:34:00Z",
    "actualDurationSeconds": 240,
    "analysisResult": {
      "id": "789abcde-f012-3456-789a-bcdef0123456",
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "overallPerformanceScore": 92.00,
      "domainScore": 92.00,
      "supportiveObservations": "Exceptional engagement and high accuracy demonstrated in motor coordination. The child is ready for adaptive challenge progression.",
      "fatigueObserved": false,
      "recommendedDifficultyAdjustment": "Increase",
      "adaptiveParametersJson": "{\"targetPacingSeconds\":3,\"visualCueLevel\":\"Standard\",\"repetitionTarget\":10,\"pacingNotes\":\"Progressive pacing with increased challenge\"}",
      "analyzedAtUtc": "2026-09-07T05:34:01Z",
      "isFallbackResult": false
    },
    "metrics": [
      {
        "id": "a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d",
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "metricType": "AccuracyPercentage",
        "value": 92.0,
        "timestampUtc": "2026-09-07T05:34:00Z"
      }
    ]
  }
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Session not found or caller not authorized.

---

## 6. Progress & Longitudinal Analytics Endpoints (`api/children/{childId}/progress`)

### 6.1 Get Child Progress Summary
- **Method**: `GET`
- **Route**: `/api/children/{childId}/progress`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `childId` (Guid)
- **Response**: `200 OK`
  ```json
  {
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "totalCompletedSessions": 12,
    "totalPracticeMinutes": 48,
    "overallAverageScore": 84.50,
    "currentStreakDays": 4,
    "recentPerformanceTrend": "Improving",
    "domainSummaries": [
      {
        "domain": "Movement",
        "completedSessions": 8,
        "averageScore": 87.20,
        "latestScore": 92.00,
        "trend": "Improving"
      },
      {
        "domain": "Attention",
        "completedSessions": 4,
        "averageScore": 79.10,
        "latestScore": 80.00,
        "trend": "Stable"
      }
    ]
  }
  ```
- **Recent Performance Trend Values**:
  - `Improving`: Score trend consistently upward over recent sessions.
  - `Stable`: Performance maintains consistent levels within standard variance.
  - `NeedsSupport`: Recent score declines or observed fatigue indicates gentler difficulty / rest needed.
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Child not found or caller not authorized.

### 6.2 Get Paginated Session Progress History
- **Method**: `GET`
- **Route**: `/api/children/{childId}/progress/history`
- **Authentication**: Bearer Token
- **Authorization**: Owned Parent OR Actively Assigned Doctor
- **Route Parameters**: `childId` (Guid)
- **Query Parameters**:
  - `page` (optional, int, default 1)
  - `pageSize` (optional, int, default 20, max 100)
  - `domain` (optional, string): `Movement`, `Speech`, `Attention`
  - `fromDate` (optional, ISO 8601 DateTime)
  - `toDate` (optional, ISO 8601 DateTime)
- **Example URL**: `/api/children/c8a2b53a-0e9e-4c72-9a67-84bc13328e7e/progress/history?page=1&pageSize=10&domain=Movement`
- **Response**: `200 OK`
  ```json
  [
    {
      "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
      "activityTitle": "Animal Reach & Stretch",
      "domain": "Movement",
      "score": 92.00,
      "durationSeconds": 240,
      "completedAtUtc": "2026-09-07T05:34:00Z"
    },
    {
      "sessionId": "e1d3c5b7-0123-4567-89ab-cdef01234566",
      "activityTitle": "Color Stepping Stones",
      "domain": "Movement",
      "score": 85.00,
      "durationSeconds": 300,
      "completedAtUtc": "2026-09-06T15:20:00Z"
    }
  ]
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `404 Not Found`: Child not found or caller not authorized.

---

## 7. Doctor Dashboard Endpoints (`api/doctor`)

### 7.1 Get Doctor Dashboard Overview
- **Method**: `GET`
- **Route**: `/api/doctor/dashboard`
- **Authentication**: Bearer Token
- **Authorization**: `Doctor` role only
- **Response**: `200 OK`
  ```json
  {
    "totalAssignedChildren": 15,
    "activeChildrenCount": 12,
    "weeklyCompletedSessions": 42,
    "averageMovementScore": 81.40,
    "needsSupportCount": 2,
    "needsSupportAlerts": [
      {
        "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
        "fullName": "Leo Jenkins",
        "currentMovementLevel": "Beginner",
        "recentTrend": "NeedsSupport",
        "daysSinceLastSession": 4
      }
    ],
    "recentCompletedSessions": [
      {
        "sessionId": "f2e4d6c8-1234-5678-90ab-cdef01234567",
        "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
        "childFullName": "Leo Jenkins",
        "activityTitle": "Animal Reach & Stretch",
        "domain": "Movement",
        "overallScore": 92.00,
        "durationSeconds": 240,
        "completedAtUtc": "2026-09-07T05:34:00Z"
      }
    ]
  }
  ```
- **Clinical Framing Notice**:
  - Non-medical performance indicators.
  - Alerts denote app session frequency and recent app score trends, never medical diagnoses.
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Doctor.

### 7.2 Get Doctor Assigned Children Roster
- **Method**: `GET`
- **Route**: `/api/doctor/children`
- **Authentication**: Bearer Token
- **Authorization**: `Doctor` role only
- **Response**: `200 OK`
  ```json
  [
    {
      "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
      "fullName": "Leo Jenkins",
      "dateOfBirth": "2019-04-15",
      "ageYears": 7,
      "supportNotes": "Loves visual cues and counting games",
      "currentMovementLevel": "Beginner",
      "totalCompletedSessions": 12,
      "totalPracticeMinutes": 48,
      "overallAverageScore": 84.50,
      "recentTrend": "Improving",
      "lastSessionDateUtc": "2026-09-07T05:34:00Z",
      "assignedAtUtc": "2026-09-01T10:00:00Z"
    }
  ]
  ```
- **Errors**:
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Doctor.

### 7.3 Link Child via Linking Code (Doctor-Initiated)
- **Method**: `POST`
- **Route**: `/api/doctor/link-child`
- **Authentication**: Bearer Token
- **Authorization**: `Doctor` role only
- **Request Body**:
  ```json
  {
    "linkingCode": "MK78XP"
  }
  ```
- **Response**: `200 OK`
  ```json
  {
    "id": "e5b6a789-0123-4567-89ab-cdef01234567",
    "doctorId": "8c89f53e-3241-45cd-8ef0-9e6b36021d75",
    "childId": "c8a2b53a-0e9e-4c72-9a67-84bc13328e7e",
    "assignedAtUtc": "2026-09-07T05:40:00Z",
    "isActive": true
  }
  ```
- **Errors**:
  - `400 Bad Request`: Empty linking code or expired/invalid linking code.
  - `401 Unauthorized`: Unauthenticated.
  - `403 Forbidden`: Caller is not a Doctor.
  - `404 Not Found`: Child profile associated with code not found.
  - `409 Conflict`: Child is already actively assigned to this doctor.

---

## 8. System Health Endpoint

### 8.1 Health Probe
- **Method**: `GET`
- **Route**: `/health`
- **Authentication**: None (Anonymous)
- **Response**: `200 OK`
  ```json
  {
    "status": "Healthy"
  }
  ```
