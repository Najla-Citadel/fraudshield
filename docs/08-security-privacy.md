# 8. Security & Privacy

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 8.1 Required Permissions

### Android Manifest Permissions
| Permission | Justification | Runtime Request |
|-----------|--------------|-----------------|
| `INTERNET` | API communication with backend | No (normal) |
| `CAMERA` | QR code scanning, device auditing | Yes |
| `ACCESS_FINE_LOCATION` | Incident geolocation for scam reports | Yes |
| `ACCESS_COARSE_LOCATION` | Regional alert matching | Yes |
| `READ_PHONE_STATE` | Call state monitoring for Caller ID | Yes |
| `READ_PHONE_NUMBERS` | Number verification for call protection | Yes |
| `READ_CALL_LOG` | Android 9 and below call history | Yes |
| `POST_NOTIFICATIONS` | Push notification delivery | Yes (Android 13+) |
| `FOREGROUND_SERVICE` | Background call monitoring service | No (normal) |
| `FOREGROUND_SERVICE_PHONE_CALL` | Call-type foreground service | No (normal) |
| `SYSTEM_ALERT_WINDOW` | Caller risk overlay display | Yes (special) |
| `WAKE_LOCK` | CPU lock for background tasks | No (normal) |
| `RECORD_AUDIO` | Voice call analysis (Premium) | Yes |
| `RECEIVE_BOOT_COMPLETED` | Restart foreground service after reboot | No (normal) |

### Permission Minimization Strategy
- Permissions requested only at point of use (just-in-time)
- Degraded functionality if permission denied (not app-breaking)
- Clear explanation dialogs before system permission prompt
- No permission pre-bundling on app install

---

## 8.2 Data Storage Strategy

### Client-Side Storage
| Store | Technology | Contents | Encryption |
|-------|-----------|----------|------------|
| Secure Storage | FlutterSecureStorage | JWT tokens, device ID | AES (hardware-backed on Android) |
| Local Database | SQLite (sqflite) | Scam number cache, offline data | At-rest on device |
| Preferences | SharedPreferences | Theme, locale, onboarding state | None (non-sensitive) |
| Temporary Files | path_provider cache | Downloaded files, audio recordings | Cleared on app close |

### Server-Side Storage
| Store | Technology | Contents | Encryption |
|-------|-----------|----------|------------|
| Primary Database | PostgreSQL 16 | User data, reports, transactions | TLS in transit, field-level AES at rest |
| Cache Layer | Redis 7 | Rate limits, OTPs, nonces, tokens | TLS in transit, password auth |
| File Storage | AWS S3 | Evidence uploads (photos, docs) | SSE-S3 at rest, presigned URLs |
| Backups | postgres-backup-local | Automated daily DB backups | 7-day retention, encrypted at rest |

### Data Retention Policy
| Data Type | Retention | Deletion Method |
|-----------|-----------|-----------------|
| User PII (bio, mobile, address) | Until account deletion | Anonymization + field clearing |
| Scam Reports | Permanent (community data) | Soft delete (deletedAt flag) |
| OTPs | 5 minutes | Redis TTL auto-expiry |
| JWT Tokens | Access: 15m, Refresh: 30d | Redis TTL / DB clearing |
| Anti-replay Nonces | 5 minutes | Redis TTL auto-expiry |
| Audit Logs | Permanent | Immutable (no deletion) |
| Session Data | Until logout | Token revocation + Redis clear |
| Backups | 7 days (rolling) | Automated deletion |

---

## 8.3 Encryption Methods

### In Transit
| Layer | Method | Details |
|-------|--------|---------|
| HTTPS | TLS 1.2+ | Enforced via Nginx, HSTS headers |
| Certificate Pinning | SHA-256 | Pinned fingerprints for api.fraudshieldprotect.com |
| WebSocket | WSS | Socket.io over TLS |

### At Rest — Field-Level Encryption (AES-256-GCM)
| Field | Model | Encryption Type |
|-------|-------|-----------------|
| `bio` | Profile | Probabilistic (random IV) |
| `mobile` | Profile | Probabilistic |
| `mailingAddress` | Profile | Probabilistic |
| `target` | ScamReport | Deterministic (searchable) |

**Encryption Implementation** (`EncryptionUtils`):
```
Probabilistic: salt(64B) + iv(12B) + AES-256-GCM encrypt → salt:iv:tag:ciphertext (hex)
Deterministic: static salt + zero IV + AES-256-GCM → det:salt:tag:ciphertext (hex)

Key Derivation: scrypt(DB_ENCRYPTION_KEY, salt, 32) → 256-bit key
```

### Password Storage
| Algorithm | Rounds | Purpose |
|-----------|--------|---------|
| bcrypt | 12 | Password hashing |

### Token Security
| Token | Algorithm | Expiry | Storage |
|-------|-----------|--------|---------|
| Access JWT | HS256 | 15 minutes | Client secure storage |
| Refresh JWT | HS256 | 30 days | Client secure storage + DB |

---

## 8.4 Threat Model

### Threat Categories & Mitigations

#### T1: Credential Attacks
| Threat | Risk | Mitigation |
|--------|------|------------|
| Brute force login | High | Rate limiting: 10 attempts/2 min per IP |
| Credential stuffing | High | CAPTCHA (Cloudflare Turnstile) on registration |
| Token theft | Medium | Short-lived access tokens (15m), secure storage |
| Session hijacking | Medium | Token revocation on logout, Redis blocklist |

#### T2: API Abuse
| Threat | Risk | Mitigation |
|--------|------|------------|
| Replay attacks | High | Anti-replay middleware (nonce + timestamp) |
| Report spam | High | Rate limiting: 5 reports/10 min per user |
| Feature abuse | Medium | 100 scans/hour per user |
| DDoS | High | Nginx rate limiting + Helmet headers |

#### T3: Data Exfiltration
| Threat | Risk | Mitigation |
|--------|------|------------|
| Database breach | Critical | Field-level AES-256-GCM encryption of PII |
| API data leak | High | SafeUser serialization (omits passwordHash, tokens) |
| Log exposure | Medium | PII never logged, correlation IDs only |
| Backup theft | Medium | Encrypted backups, 7-day retention |

#### T4: Client-Side Attacks
| Threat | Risk | Mitigation |
|--------|------|------------|
| Rooted device | High | Jailbreak detection (flutter_jailbreak_detection) |
| App tampering | High | Play Integrity attestation, signature verification |
| MITM attack | Critical | Certificate pinning (SHA-256), HTTPS-only |
| Reverse engineering | Medium | ProGuard/R8 obfuscation (release builds) |

#### T5: Content & Social Engineering
| Threat | Risk | Mitigation |
|--------|------|------------|
| PII exposure in reports | High | ContentModerationService PII detection (IC, email, phone, address) |
| Offensive content | Medium | OpenAI Moderation API screening |
| Fake reports | Medium | Community verification, reputation-weighted scoring |
| Coordinated manipulation | Medium | Duplicate detection, flag system, admin review |

#### T6: Infrastructure
| Threat | Risk | Mitigation |
|--------|------|------------|
| Redis failure | High | Fail-closed anti-replay (configurable), graceful degradation |
| Database exhaustion | Medium | Connection pool limits (10-20), pool timeout (20s) |
| Request timeout DoS | Medium | Global 30s timeout, compression |
| Secret exposure | Critical | Environment variables, never in code, .gitignore enforced |

---

## 8.5 Abuse Prevention

### Report System Abuse Prevention
| Mechanism | Implementation |
|-----------|---------------|
| **Rate Limiting** | 5 reports per 10 minutes per authenticated user |
| **Duplicate Detection** | Same target by same user within 24h → 409 |
| **Content Moderation** | AI + PII screening on all text content |
| **Community Verification** | Reports require community votes to be verified |
| **Reputation Weighting** | Low-reputation users' reports carry less weight |
| **Admin Moderation** | All reports visible in admin dashboard for manual review |
| **Content Flagging** | Community members can flag suspicious reports |
| **Daily Points Cap** | Prevents point farming through excessive submissions |

### Authentication Abuse Prevention
| Mechanism | Implementation |
|-----------|---------------|
| **Login Rate Limiting** | 10 attempts per 2 minutes per IP |
| **CAPTCHA** | Cloudflare Turnstile on registration |
| **Email Verification** | Required before feature access |
| **Token Revocation** | Immediate on logout, Redis blocklist |
| **Refresh Token Rotation** | New pair issued on refresh, old invalidated |

### API Abuse Prevention
| Mechanism | Implementation |
|-----------|---------------|
| **Anti-Replay** | Nonce + timestamp (5-min window) on all mutations |
| **Feature Rate Limiting** | 100 scans per hour per user |
| **Request Size Limiting** | 1MB JSON body limit |
| **Request Timeout** | 30s global timeout |
| **CORS** | Origin whitelist enforcement |
| **Helmet Headers** | HSTS, CSP, X-Frame-Options, X-Content-Type-Options |

### Admin Accountability
| Mechanism | Implementation |
|-----------|---------------|
| **Audit Logging** | Every admin action logged with adminId, action, target, payload |
| **Role Enforcement** | Admin middleware checks user.role === 'admin' |
| **Immutable Logs** | AuditLog records cannot be modified or deleted |
| **Admin Separation** | Admin dashboard uses separate token storage |

---

## 8.6 Data Privacy Compliance

### PDPA (Malaysia) Compliance
| Requirement | Implementation |
|-------------|---------------|
| Consent | Terms & Privacy acceptance versioned and tracked |
| Data Access | GET `/users/export` — full personal data export |
| Data Deletion | DELETE `/users/me` — anonymization + PII deletion |
| Data Minimization | Only essential fields collected, PII encrypted |
| Purpose Limitation | Data used only for fraud detection and prevention |
| Security | AES-256-GCM encryption, TLS, access controls |

### GDPR Alignment
| Right | Implementation |
|-------|---------------|
| Right to Access | Data export endpoint |
| Right to Erasure | Account deletion with anonymization |
| Right to Rectification | Profile update endpoint |
| Right to Data Portability | JSON export format |
| Right to Object | Privacy settings screen |
| Consent Withdrawal | Account deletion flow |

### Anonymization Strategy (Account Deletion)
1. Email → `deleted_{userId}@fraudshield.deleted`
2. Password → `deleted`
3. Full name → `Deleted User`
4. Role → `deleted`
5. Profile (bio, mobile, address) → Deleted entirely
6. Subscriptions → Deleted
7. Alerts → Deleted
8. Redemptions → Deleted
9. **Preserved**: ScamReports, Comments (community data with anonymized author)
10. **Preserved**: TransactionJournals (audit trail)
