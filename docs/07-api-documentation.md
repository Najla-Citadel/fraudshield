# 7. API Documentation

## Document Information
| Field | Value |
|-------|-------|
| Base URL | `https://api.fraudshieldprotect.com/api/v1` |
| Auth | Bearer JWT (Authorization header) |
| Content-Type | application/json |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 7.1 Authentication APIs

### POST `/auth/signup`
**Rate Limit**: 10 requests/2 min (loginLimiter)

| Field | Details |
|-------|---------|
| Auth | None |
| Request | `{ fullName: string, email: string, password: string, captchaToken: string }` |
| Success (201) | `{ user: SafeUser, message: "Verification email sent" }` |
| Error (409) | `{ message: "Email already in use" }` |
| Error (400) | `{ message: "Verification failed" }` (CAPTCHA) |
| Security | Cloudflare Turnstile CAPTCHA verification, bcrypt password hashing |

### POST `/auth/verify-email`
| Field | Details |
|-------|---------|
| Auth | None |
| Rate Limit | loginLimiter |
| Request | `{ email: string, otp: string }` |
| Success (200) | `{ user: SafeUser, accessToken: string, refreshToken: string }` |
| Error (400) | `{ message: "Invalid or expired OTP" }` |
| Security | OTP validated against Redis (5-min TTL), consumed on use |

### POST `/auth/login`
| Field | Details |
|-------|---------|
| Auth | None |
| Rate Limit | 10 attempts/2 min (loginLimiter) |
| Request | `{ email: string, password: string }` |
| Success (200) | `{ user: SafeUser, accessToken: string, refreshToken: string }` |
| Error (401) | `{ message: "Invalid credentials" }` |
| Security | bcrypt comparison, JWT generation (access: 15m, refresh: 30d) |

### POST `/auth/google`
| Field | Details |
|-------|---------|
| Auth | None |
| Rate Limit | loginLimiter |
| Request | `{ idToken: string }` |
| Success (200) | `{ user: SafeUser, accessToken: string, refreshToken: string }` |
| Security | Google OAuth token verified via Firebase Admin SDK |

### POST `/auth/refresh`
| Field | Details |
|-------|---------|
| Auth | None |
| Rate Limit | authLimiter (100/15 min) |
| Request | `{ refreshToken: string }` |
| Success (200) | `{ accessToken: string, refreshToken: string }` |
| Error (401) | `{ message: "Invalid refresh token" }` |
| Security | Old refresh token revoked, new pair issued |

### POST `/auth/forgot-password`
| Field | Details |
|-------|---------|
| Auth | None |
| Request | `{ email: string }` |
| Success (200) | `{ message: "Reset OTP sent" }` |

### POST `/auth/reset-password`
| Field | Details |
|-------|---------|
| Auth | None |
| Request | `{ email: string, otp: string, newPassword: string }` |
| Success (200) | `{ message: "Password reset successful" }` |

### GET `/auth/profile`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ user: SafeUser with profile, subscription }` |

### PATCH `/auth/profile`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ bio?: string, avatar?: string, preferredName?: string, mobile?: string, mailingAddress?: string }` |
| Success (200) | `{ profile: UpdatedProfile }` |
| Security | PII fields (bio, mobile, mailingAddress) encrypted with AES-256-GCM |

### POST `/auth/change-password`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ currentPassword: string, newPassword: string }` |
| Success (200) | `{ message: "Password changed" }` |

### POST `/auth/logout`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ message: "Logged out" }` |
| Security | Token added to Redis blocklist |

---

## 7.2 Reports APIs

### POST `/reports`
**Rate Limit**: 5 reports/10 min (reportLimiter)

| Field | Details |
|-------|---------|
| Auth | Required |
| Content-Type | multipart/form-data |
| Request Fields | `type` (phone\|bank\|link\|doc\|manual), `category`, `description`, `targetType?`, `target?`, `latitude?`, `longitude?`, `isPublic?`, `evidence?` (files) |
| Success (201) | `{ report: ScamReport, pointsAwarded: number }` |
| Error (400) | `{ message: "Content blocked", reasons: string[] }` (moderation) |
| Error (409) | `{ message: "Duplicate report" }` |
| Security | Content moderation (PII + AI), entity extraction, target encryption |

### GET `/reports/public`
| Field | Details |
|-------|---------|
| Auth | None |
| Query | `page?`, `limit?`, `category?` |
| Success (200) | `{ data: ScamReport[], meta: { page, totalPages, total } }` |

### GET `/reports/search`
| Field | Details |
|-------|---------|
| Auth | None |
| Query | `q?`, `category?`, `type?`, `status?` |
| Success (200) | `{ data: ScamReport[] }` |

### GET `/reports/lookup`
**Rate Limit**: 100/hour (featureLimiter)

| Field | Details |
|-------|---------|
| Auth | Required |
| Query | `type` (phone\|url\|bank), `target` |
| Success (200) | `{ found: boolean, score: 0-100, level: string, reasons: string[], factors: {...}, categories: string[], lastReported: ISO }` |
| Security | Result logged to TransactionJournal |

### GET `/reports/my`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ data: ScamReport[] }` (user's own reports) |

### GET `/reports/:id`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ report: ScamReport with comments, verifications }` |

### POST `/reports/verify`
**Rate Limit**: featureLimiter

| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ reportId: string, isSame: boolean }` |
| Success (201) | `{ verification, pointsAwarded }` |
| Error (409) | `{ message: "Already verified" }` |

### POST `/reports/flag-content`
| Field | Details |
|-------|---------|
| Auth | Required |
| Rate Limit | featureLimiter |
| Request | `{ targetId: string, type: "report"\|"comment", reason: string }` |
| Success (201) | `{ flag }` |

### POST `/reports/comments`
**Rate Limit**: reportLimiter

| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ reportId: string, text: string }` (3-500 chars) |
| Success (201) | `{ id, text, createdAt, commenter: { avatar, displayName, reputation } }` |
| Security | Content moderation (PII + AI), real-time WebSocket emit |

### GET `/reports/:reportId/comments`
| Field | Details |
|-------|---------|
| Auth | None |
| Success (200) | `[{ id, text, createdAt, commenter: { avatar, displayName, reputation } }]` |

### GET `/reports/scam-numbers/sync`
| Field | Details |
|-------|---------|
| Auth | Required |
| Rate Limit | featureLimiter |
| Success (200) | `{ numbers: ScamNumberCache[], lastSync: ISO }` |

---

## 7.3 Feature APIs

### POST `/features/check-url`
| Field | Details |
|-------|---------|
| Auth | Required |
| Rate Limit | featureLimiter (100/hour) |
| Request | `{ url: string }` |
| Success (200) | `{ riskScore, reasons, redirectChain, finalUrl, safeBrowsingResult }` |

### POST `/features/check-link`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ url: string }` |
| Success (200) | `{ riskScore, analysis: { redirects, finalDestination, heuristics, safeBrowsing } }` |

### POST `/features/check-qr`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ data: string }` (QR decoded content) |
| Success (200) | `{ extractedUrl, riskScore, analysis }` |

### POST `/features/analyze-message`
| Field | Details |
|-------|---------|
| Auth | Required (Premium) |
| Request | `{ message: string }` |
| Success (200) | `{ riskScore, patterns, extractedEntities, recommendation }` |

### POST `/features/analyze-voice`
| Field | Details |
|-------|---------|
| Auth | Required (Premium) |
| Content-Type | multipart/form-data |
| Request | `audioFile`, `duration?`, `callerNumber?` |
| Success (200) | `{ riskScore, patterns, transcription, summary, recommendation }` |

### POST `/features/scan-pdf`
| Field | Details |
|-------|---------|
| Auth | Required (Premium) |
| Content-Type | multipart/form-data |
| Request | `file` (PDF) |
| Success (200) | `{ riskScore, findings, extractedText, embeddedLinks }` |

### POST `/features/scan-apk`
| Field | Details |
|-------|---------|
| Auth | Required (Premium) |
| Content-Type | multipart/form-data |
| Request | `file` (APK) |
| Success (200) | `{ riskScore, threats, permissions, signatures }` |

### POST `/features/evaluate-risk`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ type: string, target: string }` |
| Success (200) | `{ score, level, reasons, factors, checkedAt }` |

### GET `/features/subscription`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ subscription: UserSubscription \| null }` |

### POST `/features/subscription`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ planId: string }` |
| Success (201) | `{ subscription: UserSubscription }` |

### GET `/features/points`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ points, totalPoints, dailyPointsEarned, lastPointsReset }` |

### GET `/features/leaderboard`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `[{ rank, displayName, avatar, points, reputation, badges }]` |

### GET `/features/badges`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ badges: string[] }` (user's earned badge keys) |

### GET `/features/badges/all`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `[{ key, name, description, icon, tier, trigger, threshold }]` |

### POST `/features/security-scans`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ totalAppsScanned: number, riskyApps: object[] }` |
| Success (201) | `{ scan: SecurityScan }` |

### POST `/features/behavioral`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ event: string, metadata: object }` |
| Success (201) | `{ logged: true }` |

### POST `/features/behavioral/call-signal`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ callerNumber: string, callDuration: number, metadata: object }` |
| Success (201) | `{ signal: logged }` |

---

## 7.4 Alert APIs

### GET `/alerts`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `[{ id, title, message, type, category, severity, isRead, metadata, createdAt }]` |

### GET `/alerts/trending`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ trending: Alert[] }` (region-filtered) |

### PATCH `/alerts/read-all`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ updated: number }` |

### POST `/alerts/:id/resolve`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ actionTaken: string }` |
| Success (200) | `{ alert: resolved }` |

### POST `/alerts/subscribe`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ categories: string[], latitude?: number, longitude?: number, radiusKm?: number, fcmToken?: string, emailDigestEnabled?: boolean }` |
| Success (200) | `{ subscription: AlertSubscription }` |

---

## 7.5 Transaction APIs

### GET `/transactions`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ data: TransactionJournal[] }` |

### POST `/transactions`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ checkType, target?, amount?, merchant?, paymentMethod?, platform?, notes? }` |
| Success (201) | `{ transaction: TransactionJournal }` |

### POST `/transactions/:id/report`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (201) | `{ report: ScamReport }` (auto-generated from transaction) |

---

## 7.6 Reward APIs

### GET `/rewards`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `[{ id, name, description, pointsCost, type, active, isFeatured, minTier }]` |

### POST `/rewards/redeem`
| Field | Details |
|-------|---------|
| Auth | Required |
| Request | `{ rewardId: string }` |
| Success (201) | `{ redemption, remainingPoints }` |
| Error (400) | `{ message: "Insufficient points" }` |

### POST `/rewards/daily`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ pointsAwarded, streak, totalPoints }` |
| Error (400) | `{ message: "Already claimed today" }` |

---

## 7.7 User APIs

### GET `/users/security-health`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ score: 0-100, factors: { emailVerified, appAttestation, recentScan, reportActivity, subscription } }` |

### GET `/users/export`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ exportDate: ISO, data: { profile, reports, transactions, alerts, subscriptions, redemptions } }` |
| Security | Excludes passwordHash, refreshToken |

### DELETE `/users/me`
| Field | Details |
|-------|---------|
| Auth | Required |
| Success (200) | `{ message: "Account deleted successfully" }` |
| Security | Transactional: anonymize user, delete PII, preserve community reports |

---

## 7.8 Admin APIs (All require admin role)

### GET `/admin/stats`
| Success (200) | `{ totalUsers, totalReports, pendingReports, resolvedReports }` |

### GET `/admin/users`
| Success (200) | `[{ id, email, fullName, role, emailVerified, createdAt, profile, subscriptions }]` |

### PATCH `/admin/users/:id`
| Request | `{ role?, fullName?, profile?: { preferredName, mobile, mailingAddress } , planId? }` |
| Success (200) | `{ user: updated }` |
| Security | AuditLog created |

### GET `/admin/reports?page=X&limit=15&sortBy=X`
| Success (200) | `{ data: ScamReport[], meta: { page, totalPages, total } }` |

### PATCH `/admin/reports/:id/status`
| Request | `{ status: "VERIFIED"\|"REJECTED"\|"PENDING" }` |
| Success (200) | `{ report: updated }` |
| Security | AuditLog created, triggers alert engine on verify |

### CRUD `/admin/subscription-plans`
| POST | `{ name, price, features: string[], durationDays }` → 201 |
| PUT `/:id` | `{ name?, price?, features?, durationDays? }` → 200 |
| DELETE `/:id` | → 200 |

### CRUD `/admin/badges`
| POST | `{ key, name, description, icon, tier, trigger, threshold? }` → 201 |
| PUT `/:id` | Same fields → 200 |
| DELETE `/:id` | → 200 |

### CRUD `/admin/rewards`
| POST | `{ name, description, pointsCost, type, active? }` → 201 |
| PUT `/:id` | Same fields → 200 |
| DELETE `/:id` | → 200 |

### POST `/admin/broadcasts`
| Request | `{ title: string, message: string }` |
| Success (201) | `{ broadcast, recipientCount }` |
| Security | Creates Alert for all users, sends FCM |

### POST `/admin/fraud-labels`
| Request | `{ txId: string, label: string }` |
| Success (201) | `{ label: FraudLabel }` |

### GET `/admin/global-entities?type=X&search=X&limit=15`
| Success (200) | `[{ phoneNumber\|url\|accountNumber, riskScore, reportCount, categories, lastReported }]` |

---

## 7.9 Infrastructure APIs

### GET `/health`
| Auth | None |
| Success (200) | `{ status: "ok" }` |

### GET `/api/v1/status`
| Auth | None |
| Success (200) | `{ database: "connected"\|"disconnected", redis: "connected"\|"disconnected", uptime: seconds }` |

### GET `/metrics`
| Auth | API Key (METRICS_API_KEY query param) |
| Success (200) | Prometheus text format |

### GET `/attestation/challenge`
| Auth | Required |
| Success (200) | `{ nonce: string }` |

### POST `/attestation/verify`
| Auth | Required |
| Request | `{ token: string }` (Play Integrity token) |
| Success (200) | `{ verified: boolean, deviceIntegrity: object }` |

---

## 7.10 Global Security Controls

### Request Headers (Required for state-changing requests)
| Header | Purpose | Format |
|--------|---------|--------|
| `Authorization` | JWT authentication | `Bearer <token>` |
| `X-FS-Timestamp` | Anti-replay timestamp | ISO 8601 |
| `X-FS-Nonce` | Anti-replay nonce | UUID v4 |
| `X-Correlation-ID` | Request tracing | UUID (auto-generated if absent) |

### Rate Limiting Summary
| Limiter | Window | Limit | Scope |
|---------|--------|-------|-------|
| loginLimiter | 2 min | 10 | Per IP |
| authLimiter | 15 min | 100 | Per IP |
| reportLimiter | 10 min | 5 | Per user |
| featureLimiter | 1 hour | 100 | Per user |

### Response Status Codes
| Code | Meaning |
|------|---------|
| 200 | Success |
| 201 | Created |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized (missing/invalid token) |
| 403 | Forbidden (insufficient role) |
| 404 | Not Found |
| 408 | Request Timeout (30s exceeded) |
| 409 | Conflict (duplicate) |
| 429 | Rate Limited |
| 500 | Internal Server Error |
| 503 | Service Unavailable (Redis/DB down) |
