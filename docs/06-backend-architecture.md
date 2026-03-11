# 6. Backend Architecture

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield Backend API |
| Runtime | Node.js 20.18 (Alpine) |
| Framework | Express.js + TypeScript |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 6.1 System Components

```
┌────────────────────────────────────────────────────────────────────────┐
│                          EXTERNAL CLIENTS                              │
│    ┌──────────────┐   ┌──────────────┐   ┌──────────────────┐         │
│    │ Mobile App   │   │ Admin Panel  │   │ Prometheus/       │         │
│    │ (Flutter)    │   │ (React)      │   │ Monitoring        │         │
│    └──────┬───────┘   └──────┬───────┘   └──────┬───────────┘         │
└───────────┼──────────────────┼──────────────────┼─────────────────────┘
            │                  │                  │
            ▼                  ▼                  ▼
┌────────────────────────────────────────────────────────────────────────┐
│                       NGINX REVERSE PROXY (Production)                 │
│                       SSL Termination / Rate Limiting                  │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │
                                 ▼
┌────────────────────────────────────────────────────────────────────────┐
│                          EXPRESS APPLICATION                           │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                     MIDDLEWARE STACK                              │  │
│  │  1. Tracer (X-Correlation-ID)                                    │  │
│  │  2. Metrics Middleware (Prometheus counters)                      │  │
│  │  3. Request Timeout (30s global)                                 │  │
│  │  4. Anti-Replay (nonce + timestamp)                              │  │
│  │  5. Helmet (security headers)                                    │  │
│  │  6. Passport (JWT initialization)                                │  │
│  │  7. CORS (origin whitelist)                                      │  │
│  │  8. Body Parser (JSON, 1MB limit)                                │  │
│  │  9. Compression (gzip)                                           │  │
│  │  10. Morgan (HTTP logging)                                       │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                        │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │                      ROUTE LAYER (12 routers)                    │  │
│  │  /auth  /reports  /features  /rewards  /admin  /users           │  │
│  │  /alerts  /transactions  /upload  /config  /attestation          │  │
│  │  /trending                                                       │  │
│  └───────────────────────────┬──────────────────────────────────────┘  │
│                               │                                        │
│  ┌───────────────────────────┼──────────────────────────────────────┐  │
│  │                   CONTROLLER LAYER (33 controllers)              │  │
│  │  AuthController  ReportController  FeatureController             │  │
│  │  AdminController  UserController  CommentController              │  │
│  │  AlertController  TransactionController  RewardController        │  │
│  │  VoiceSignalController  + more                                   │  │
│  └───────────────────────────┬──────────────────────────────────────┘  │
│                               │                                        │
│  ┌───────────────────────────┼──────────────────────────────────────┐  │
│  │                    SERVICE LAYER (26 services)                   │  │
│  │  AuthService  RiskEvaluationService  ContentModerationService   │  │
│  │  GamificationService  AlertEngineService  EmailService          │  │
│  │  HealthScoreService  AttestationService  AuditService           │  │
│  │  EncryptionUtils  MetricsService  + more                        │  │
│  └───────────────────────────┬──────────────────────────────────────┘  │
│                               │                                        │
└───────────────────────────────┼────────────────────────────────────────┘
                                │
        ┌───────────────────────┼───────────────────────┐
        ▼                       ▼                       ▼
┌──────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  PostgreSQL  │   │     Redis        │   │  External APIs   │
│  (Prisma ORM)│   │  (Cache/Queue)   │   │                  │
│              │   │                  │   │  • OpenAI        │
│  • Users     │   │  • Rate limits   │   │  • Google Safe   │
│  • Reports   │   │  • OTP store     │   │    Browsing      │
│  • Profiles  │   │  • Token block   │   │  • SemakMule     │
│  • Alerts    │   │  • Anti-replay   │   │  • Firebase FCM  │
│  • Txns      │   │  • Bull queues   │   │  • Cloudflare    │
│  • Caches    │   │  • Session cache │   │    Turnstile     │
│  • Audit     │   │                  │   │  • Play Integrity│
│  • Badges    │   │                  │   │  • AWS S3        │
│  • Rewards   │   │                  │   │  • SMTP (Resend) │
└──────────────┘   └──────────────────┘   └──────────────────┘
```

---

## 6.2 Request Flow

```
Client Request
    │
    ▼
[1] Tracer Middleware
    │ → Generates/propagates X-Correlation-ID
    │ → Attaches to req for downstream logging
    ▼
[2] Metrics Middleware
    │ → Records request start time
    │ → Increments request counter (route, method)
    ▼
[3] Request Timeout (30s)
    │ → Sets global timeout, returns 408 on breach
    ▼
[4] Anti-Replay Middleware
    │ → Validates X-FS-Timestamp (±5 min window)
    │ → Validates X-FS-Nonce (unique, stored in Redis)
    │ → Exempts GET requests and auth/admin routes
    │ → Fails-closed if Redis down (configurable)
    ▼
[5] Helmet
    │ → Sets HSTS, CSP, X-Frame-Options, etc.
    ▼
[6] Passport JWT
    │ → Initializes JWT strategy
    ▼
[7] CORS
    │ → Validates Origin against CORS_ORIGIN whitelist
    ▼
[8] Body Parser (JSON, 1MB limit)
    ▼
[9] Compression (gzip)
    ▼
[10] Morgan (HTTP logging)
    ▼
Route Matcher
    │ → /api/v1/auth/*  → Auth routes
    │ → /api/v1/reports/*  → Report routes
    │ → /api/v1/features/* → Feature routes
    │ → /api/v1/admin/*   → Admin routes (+ admin middleware)
    │ → ...
    ▼
[Per-Route Middleware]
    │ → authenticate (JWT validation + token blocklist)
    │ → requireAdmin (role check)
    │ → Rate limiter (per endpoint type)
    ▼
Controller
    │ → Validates request params/body
    │ → Calls service layer
    ▼
Service
    │ → Business logic
    │ → Database operations (Prisma)
    │ → External API calls
    │ → Cache operations (Redis)
    ▼
Response
    │ → JSON response
    │ → Metrics record response time
    │ → Correlation ID in response headers
```

---

## 6.3 Data Model Overview

### Entity Relationship Summary

```
User (1) ──── (1) Profile
  │
  ├── (1:N) ScamReport ──── (1:N) Comment
  │                    ──── (1:N) Verification
  │
  ├── (1:N) Alert
  ├── (1:N) Transaction
  ├── (1:N) TransactionJournal
  ├── (1:N) UserSubscription ──── (N:1) SubscriptionPlan
  ├── (1:N) Redemption ──── (N:1) Reward
  ├── (1:N) PointsTransaction
  ├── (1:N) AuditLog (admin actions)
  ├── (1:N) SecurityScan
  ├── (1:1) AlertSubscription
  └── (1:N) ContentFlag

Cache Tables (Standalone):
  ScamNumberCache    (phone → risk data)
  ScamUrlCache       (URL → risk data)
  ScamBankCache      (account → risk data)
  AppReputation      (packageName → community scores)
  AppActionLog       (user × app × action → unique)
  BadgeDefinition    (system-wide badge configs)
  FraudLabel         (admin-applied labels)
```

### Key Indexes
- `User.email` — unique
- `User.refreshToken` — unique
- `Profile.userId` — unique
- `Verification.[reportId, userId]` — compound unique
- `ContentFlag.[targetId, userId, type]` — compound unique
- `AlertSubscription.userId` — unique
- `AppActionLog.[userId, packageName, action]` — compound unique
- `BadgeDefinition.key` — unique

---

## 6.4 Service Architecture Details

### AuthService
- Password hashing: bcrypt (12 rounds)
- Token generation: JWT (access: 15m, refresh: 30d)
- Token revocation: Redis blocklist with TTL
- Google OAuth: Firebase Admin SDK verification
- CAPTCHA: Cloudflare Turnstile server-side validation
- OTP: 6-digit, Redis-stored, 5-minute TTL

### RiskEvaluationService
Weighted composite scoring (0-100):
```
Score = (CommunityWeight × CommunityScore)
      + (VerificationWeight × VerificationScore)
      + (ReputationWeight × ReputationScore)
      + (RecencyWeight × RecencyScore)
      + ExternalBoosts

Weights:
  Community Reports:    35%  (logarithmic curve)
  Verification Ratio:   30%  (agreement percentage)
  Reporter Reputation:  20%  (average of reporters)
  Recency:             15%  (exponential decay by days)

Boosts:
  SemakMule match:     Set to 75-90
  Google Safe Browsing: Set to 90
  URL Heuristics:      Variable
```

### ContentModerationService
Dual-layer moderation pipeline:
1. **PII Detection** (regex-based):
   - Malaysian IC numbers (YYMMDD-##-####)
   - Email addresses
   - Phone numbers (Malaysian format)
   - Physical addresses
   - Postcodes
2. **AI Moderation** (OpenAI API):
   - Offensive/harmful content detection
   - Political content filtering
   - Spam detection
   - Divisive content identification
3. **Entity Extraction**:
   - Phone numbers
   - Email addresses
   - Bank account numbers
   - URLs

### EncryptionUtils (AES-256-GCM)
- **Probabilistic encryption**: Random IV + salt per operation. Used for PII at rest (bio, mobile, mailingAddress)
- **Deterministic encryption**: Static IV for searchable fields (report targets). Same plaintext → same ciphertext
- **Format**: `salt:iv:tag:encrypted` (hex-encoded)
- **Key derivation**: scrypt from DB_ENCRYPTION_KEY

### AlertEngineService
- Real-time alert dispatch via Bull Queue
- Hourly trending analysis (configurable via TRENDING_ALERT_CRON)
- FCM push notification delivery
- Email digest generation
- Alert severity classification: LOW, MEDIUM, HIGH, CRITICAL

### GamificationService
- Point awards with daily cap
- Badge trigger evaluation
- Reputation calculation from verification activity
- Leaderboard ranking

### AuditService
- Immutable audit log for all admin actions
- Records: adminId, action, targetType, targetId, payload
- Actions: UPDATE_USER, DELETE_REPORT, APPROVE_REPORT, REJECT_REPORT, etc.

---

## 6.5 Real-Time Communication

### Socket.io Architecture
```
Server (server.ts)
    │
    ├── Connection established
    │   └── Client joins rooms based on context
    │
    ├── Events Emitted:
    │   ├── new_report      → Broadcast to community feed listeners
    │   ├── new_comment      → Sent to report_${reportId} room
    │   ├── alert_update     → Sent to user-specific room
    │   └── threat_intel     → Broadcast to all connected clients
    │
    └── Rooms:
        ├── report_${reportId}  → Users viewing a specific report
        ├── user_${userId}      → Personal alert channel
        └── community           → Global feed updates
```

### Bull Queue (Background Jobs)
- **Queue name**: alert-processing
- **Job types**: trending analysis, broadcast delivery, email digest
- **Backed by**: Redis
- **Concurrency**: Configurable per worker
- **Retry**: 3 attempts with exponential backoff

---

## 6.6 External Service Integrations

| Service | Purpose | Integration |
|---------|---------|-------------|
| **OpenAI Moderation API** | Content screening for offensive/harmful content | REST API call in ContentModerationService |
| **Google Safe Browsing** | URL threat intelligence | REST API call in RiskEvaluationService |
| **BNM SemakMule** | Malaysian mule account database | REST API call in RiskEvaluationService |
| **Google Play Integrity** | Android app attestation | REST API in AttestationService |
| **Firebase Admin SDK** | FCM push notifications, Google OAuth verification | Firebase Admin library |
| **Cloudflare Turnstile** | Bot protection on registration | REST API verification |
| **AWS S3** | File storage (evidence uploads) | AWS SDK (presigned URLs) |
| **SMTP (Resend)** | Email delivery (OTP, notifications) | Nodemailer with SMTP transport |

---

## 6.7 Database Connection Management

### PostgreSQL (Prisma)
```
Connection URL parameters:
  connection_limit=10   (dev) / 20 (prod)
  pool_timeout=20       (fail-fast after 20s)

Singleton pattern:
  src/config/database.ts exports single `prisma` instance
  Used across all services and controllers
```

### Redis
```
Configuration:
  Host: REDIS_HOST (default: localhost)
  Port: REDIS_PORT (default: 6379)
  Password: REDIS_PASSWORD (required)

Usage:
  - Rate limiting counters (TTL-based)
  - OTP storage (5-minute TTL)
  - Token blocklist (JWT expiry TTL)
  - Anti-replay nonce storage (5-minute TTL)
  - Bull queue backing store
  - Session caching
```

---

## 6.8 Error Handling Strategy

### Global Error Handler
```
Controller try/catch → next(error) → Express error middleware
    │
    ├── Known errors → Appropriate HTTP status + message
    ├── Validation errors → 400 Bad Request
    ├── Auth errors → 401 Unauthorized / 403 Forbidden
    ├── Not found → 404 Not Found
    ├── Rate limited → 429 Too Many Requests
    └── Unknown errors → 500 Internal Server Error + logged
```

### Correlation ID Tracing
- Every request gets X-Correlation-ID (generated or propagated)
- ID injected into Winston logger context
- Appears in all log entries for the request lifecycle
- Returned in response headers for client-side debugging
