# 12. Compliance

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 12.1 Google Play Policy Considerations

### Permissions Justification

| Permission | Policy Requirement | FraudShield Justification |
|-----------|-------------------|--------------------------|
| `CAMERA` | Must be core to app functionality | Core: QR code scanning for fraud detection |
| `ACCESS_FINE_LOCATION` | Must provide clear user benefit | Core: Geolocating scam incidents for community mapping |
| `READ_PHONE_STATE` | Restricted; requires declaration form | Core: Real-time caller ID fraud detection |
| `READ_CALL_LOG` | Restricted; requires declaration form | Required for Android 9 and below call monitoring |
| `RECORD_AUDIO` | Must be justified and disclosed | Premium: AI voice scam analysis during calls |
| `SYSTEM_ALERT_WINDOW` | Must explain overlay usage | Core: Caller risk display during incoming calls |
| `FOREGROUND_SERVICE` | Must justify background activity | Core: Continuous call monitoring for fraud protection |
| `POST_NOTIFICATIONS` | Requires runtime permission (Android 13+) | Core: Security alert delivery |

### Google Play Declaration Requirements
- **Phone permission declaration**: Required form explaining call monitoring use for fraud detection
- **Call log declaration**: Required form for Android 9 and below support
- **Foreground service declaration**: Must declare phone call type
- **Overlay declaration**: Must explain caller risk display purpose
- **Data safety section**: Must accurately reflect data collection, sharing, and encryption

### App Store Listing Requirements
| Requirement | Status |
|-------------|--------|
| Privacy Policy URL | Required (PrivacyPolicyScreen in app) |
| Terms of Service | Required (TermsOfServiceScreen in app) |
| Data Safety Section | Must declare all data types collected |
| Age Rating | Content Advisory for fraud/scam topics |
| Contact Information | Developer email and physical address |

### Sensitive Content Guidelines
| Area | Policy | FraudShield Compliance |
|------|--------|----------------------|
| User-generated content | Must have moderation | AI + PII moderation pipeline, content flagging, admin review |
| Financial services | Must comply with local regulations | Not providing financial services; fraud prevention tool |
| Deceptive behavior | App must function as described | Transparent about all features and data usage |
| Data collection | Must be disclosed | Privacy policy covers all collection points |

### Google Play Integrity API
- FraudShield uses Play Integrity for device attestation
- Verifies: genuine device, genuine Play Store install, no tampering
- Premium features gated behind successful attestation
- Prevents sideloaded/modified APK access

---

## 12.2 Privacy Protection

### Data Collection Inventory

| Data Category | Data Points | Purpose | Retention |
|--------------|------------|---------|-----------|
| **Account Data** | Email, full name, password hash | Authentication, identity | Until deletion |
| **Profile Data** | Bio, avatar, preferred name, mobile, address | Personalization, contact | Until deletion (encrypted at rest) |
| **Usage Data** | Security scans, lookups, transactions | Service delivery, scoring | Until deletion |
| **Reports** | Scam descriptions, evidence, locations | Community intelligence | Permanent (anonymized on deletion) |
| **Device Data** | Device ID, app list (scan), OS version | Security assessment, attestation | Session-scoped / scan duration |
| **Location Data** | GPS coordinates (report submission) | Incident geolocation, alerts | Stored with report |
| **Voice Data** | Audio recordings (voice scan) | AI scam detection analysis | Processed and discarded |
| **Behavioral Data** | Call signals, app usage patterns | Phase 2 scam detection | Session-scoped |

### Privacy by Design Principles

| Principle | Implementation |
|-----------|---------------|
| **Data Minimization** | Only essential fields collected; optional fields clearly marked |
| **Purpose Limitation** | Each data point has documented purpose; no secondary use |
| **Consent** | Versioned T&C acceptance required and tracked per user |
| **Anonymization** | Community reports display preferred name or "Community Member" |
| **Encryption** | PII encrypted at rest (AES-256-GCM), in transit (TLS 1.2+) |
| **Access Control** | JWT-based auth, admin role separation, biometric guards |
| **Transparency** | Privacy policy accessible in-app, data export available |
| **User Control** | Data export, account deletion, privacy settings screen |

### Cross-Border Data Transfer
| Aspect | Implementation |
|--------|---------------|
| Server location | Singapore (DigitalOcean) — ASEAN region |
| Data residency | Primary data in PostgreSQL on server |
| Third-party transfers | OpenAI (US), Google (US), Firebase (US) |
| Safeguards | Data minimization in API calls, no PII sent to OpenAI |

---

## 12.3 Data Governance

### Data Classification

| Classification | Description | Examples | Controls |
|---------------|-------------|----------|----------|
| **Restricted** | Highly sensitive PII | Passwords, IC numbers, encryption keys | Encrypted, never logged, access-controlled |
| **Confidential** | Personal data | Email, phone, address, mobile | Encrypted at rest, JWT-authenticated access |
| **Internal** | Business data | Reports, transactions, audit logs | Authenticated access, role-based |
| **Public** | Community data | Public reports, trending scams, leaderboard | Available to authenticated users |

### Access Control Matrix

| Role | User Data | Reports | Admin Functions | Audit Logs |
|------|-----------|---------|-----------------|------------|
| **User** | Own data only | Own + public reports | None | None |
| **Admin** | All users (read/edit) | All reports (moderate) | Full access | Read only |
| **System** | All (automated) | All (automated) | Background jobs | Write only |
| **Deleted** | None | Anonymized author | None | None |

### Data Lifecycle Management

```
Collection                    Processing                  Storage                    Deletion
──────────                    ──────────                  ───────                    ────────
User registers           →   Validate + hash password →  PostgreSQL (encrypted)  →  Account deletion:
User submits report      →   Moderate + encrypt       →  PostgreSQL + cache      →  Soft delete / anonymize
User uploads evidence    →   Virus scan + store       →  AWS S3 (SSE)           →  On report deletion
Voice scan recording     →   AI analysis              →  NOT stored (transient)  →  Discarded after analysis
OTP generated           →   Send via email            →  Redis (5-min TTL)       →  Auto-expiry
Session token           →   JWT signing               →  Client secure storage   →  Logout / expiry
```

### Regulatory Framework Compliance

#### PDPA (Personal Data Protection Act 2010 — Malaysia)
| Principle | Implementation |
|-----------|---------------|
| General Principle | Consent obtained via Terms acceptance |
| Notice & Choice | Privacy policy disclosed at registration |
| Disclosure | Data sharing limited to stated purposes |
| Security | AES-256-GCM encryption, access controls, audit logging |
| Retention | Data retained only as long as necessary |
| Data Integrity | Validation on all inputs, moderation on content |
| Access | Data export endpoint available to all users |

#### GDPR Alignment (for future EU expansion)
| Right | Endpoint | Status |
|-------|----------|--------|
| Right to Access | `GET /users/export` | Implemented |
| Right to Erasure | `DELETE /users/me` | Implemented |
| Right to Rectification | `PATCH /auth/profile` | Implemented |
| Right to Data Portability | `GET /users/export` (JSON) | Implemented |
| Right to Object | Privacy settings screen | Implemented |
| Consent Management | Terms versioning + acceptance tracking | Implemented |
| Breach Notification | — | Not yet implemented |

### Incident Response Plan
| Phase | Action | Owner |
|-------|--------|-------|
| **Detection** | Monitor logs, Crashlytics, metrics for anomalies | DevOps |
| **Assessment** | Determine scope, affected data, severity | Security Lead |
| **Containment** | Revoke compromised tokens, rotate keys, block IPs | DevOps |
| **Notification** | Notify affected users, regulators (PDPA: Commissioner) | Legal + Product |
| **Recovery** | Restore from backups, patch vulnerability, deploy fix | Engineering |
| **Post-Mortem** | Document incident, update procedures, improve controls | All |

### Third-Party Data Processors

| Processor | Data Shared | Purpose | DPA Status |
|-----------|------------|---------|------------|
| **OpenAI** | Text content (no PII — moderated) | Content moderation | Required |
| **Google** | OAuth tokens, FCM tokens | Authentication, notifications | Google ToS |
| **Firebase** | Crash data, device info | Error reporting | Firebase ToS |
| **Cloudflare** | IP address | CAPTCHA verification | Cloudflare ToS |
| **Resend (SMTP)** | Email addresses | Email delivery | Required |
| **AWS S3** | Evidence files | File storage | AWS DPA |
| **DigitalOcean** | All server data | Infrastructure hosting | DO DPA |
