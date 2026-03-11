# 4. Functional Specification Document (FSD)

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## FSD-01: User Registration

### Description
New users register with email, password, and full name. Email verification via OTP is required to activate the account.

### Trigger
User taps "Sign Up" on the Login screen.

### Functional Flow
1. User fills registration form (full name, email, password, confirm password)
2. User completes Cloudflare Turnstile CAPTCHA challenge
3. User accepts Terms of Service and Privacy Policy
4. Client validates: password match, minimum length (8 chars), email format
5. Client sends `POST /auth/signup` with form data + CAPTCHA token
6. Server validates CAPTCHA via Cloudflare API
7. Server checks email uniqueness
8. Server hashes password with bcrypt (12 rounds)
9. Server creates User record (role: "user", emailVerified: false)
10. Server creates Profile record (points: 0, reputation: 0)
11. Server generates 6-digit OTP, stores in Redis (5-min TTL)
12. Server sends OTP via SMTP email
13. Client redirects to EmailVerificationScreen
14. User enters OTP
15. Server validates OTP, sets emailVerified = true
16. Server generates JWT access token (15m) + refresh token (30d)
17. Client stores tokens securely (FlutterSecureStorage, AES-encrypted)
18. Client triggers App Attestation (Google Play Integrity)

### Inputs
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| fullName | String | Yes | 2-100 characters |
| email | String | Yes | Valid email format, unique |
| password | String | Yes | Min 8 characters |
| captchaToken | String | Yes | Valid Turnstile token |

### Outputs
| Scenario | Status | Response |
|----------|--------|----------|
| Success | 201 | `{ user, accessToken, refreshToken }` |
| Duplicate email | 409 | `{ message: "Email already in use" }` |
| Invalid CAPTCHA | 400 | `{ message: "Verification failed" }` |
| Validation error | 400 | `{ message: "..." }` |

### Edge Cases
- User closes app during OTP entry → OTP expires after 5 minutes, user must request new one
- Network failure during registration → Client shows error, allows retry
- User registers with Google email → Should use Google Sign-In instead (soft guidance)
- Duplicate OTP request within TTL → Resend same OTP, reset TTL

### Error Handling
- SMTP delivery failure → Return 500, suggest retry after 60 seconds
- Redis unavailable → Registration fails with 503 Service Unavailable
- Rate limited → Return 429 (10 attempts/2 min per IP)

---

## FSD-02: Scam Report Submission

### Description
Users submit scam reports through a 4-step wizard with evidence, geolocation, and community visibility controls. Reports undergo AI moderation and entity extraction.

### Trigger
User taps "Report Scam" from Home screen or from a scan result.

### Functional Flow
1. **Step 1 — Identity Selection**: User selects target type (Phone/Bank/Social/Website/Other) and enters target value
2. **Step 2 — Category Selection**: User selects scam category (Investment/Phishing/Job/Love/Shopping/Other)
3. **Step 3 — Details & Evidence**: User writes description (min 20 chars), selects incident location on map, optionally uploads files (JPG/PNG/PDF, max 5MB each)
4. **Step 4 — Review & Submit**: User reviews all data, toggles community visibility, confirms submission
5. Client sends `POST /reports` with multipart form data
6. Server runs ContentModerationService.screenContent():
   - PII detection: Malaysian IC (YYMMDD-##-####), emails, phone numbers, addresses, postcodes
   - OpenAI Moderation API for offensive/harmful content
   - Political/spam/divisive content check
7. If moderation flags content → Return 400 with reasons
8. Server runs ContentModerationService.extractEntities() → phones, emails, URLs, bank accounts
9. Server encrypts target field (deterministic for searchability)
10. Server creates ScamReport record with evidence JSON
11. Server updates cache tables (ScamNumberCache/ScamUrlCache/ScamBankCache):
    - Increment reportCount
    - Recalculate riskScore
    - Update categories and lastReported
12. Server awards Shield Points (10 points for submission)
13. Server checks badge triggers (report count milestone)
14. Server emits WebSocket event `new_report`
15. Client shows success screen with points earned

### Inputs
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| type | String | Yes | phone\|bank\|link\|doc\|manual |
| category | String | Yes | Enum of categories |
| targetType | String | No | phone\|bank_account\|url\|social_media\|other |
| target | String | No | Target identifier |
| description | String | Yes | 20-2000 characters |
| latitude | Float | No | Valid coordinate |
| longitude | Float | No | Valid coordinate |
| isPublic | Boolean | No | Default: false |
| evidence | File[] | No | JPG/PNG/PDF, max 5MB each |

### Outputs
| Scenario | Status | Response |
|----------|--------|----------|
| Success | 201 | `{ report, pointsAwarded }` |
| Moderation blocked | 400 | `{ message: "Content blocked", reasons }` |
| Duplicate report | 409 | `{ message: "Similar report exists" }` |
| Rate limited | 429 | `{ message: "..." }` (5 reports/10 min) |

### Edge Cases
- User submits report with location >50km from current position → Warning shown, allowed to proceed
- File upload fails → Report submitted without evidence, user notified
- Identical target reported within 24h by same user → 409 duplicate detection
- Content contains PII → Blocked with specific reasons (IC number, email, etc.)
- Offline submission → Queued locally, submitted on reconnect (if implemented)

### Error Handling
- OpenAI API timeout → Proceed without AI moderation, flag for manual review
- S3 upload failure → Report saved without file evidence
- Database write failure → Return 500, no partial state saved (transaction)

---

## FSD-03: Phone/URL/Bank Lookup

### Description
Users verify a phone number, URL, or bank account against the community intelligence database and external sources. Returns a risk score with supporting evidence.

### Trigger
User enters a target in the lookup interface or taps "Check" on a pre-filled value.

### Functional Flow
1. User enters phone number, URL, or bank account number
2. Client sends `GET /reports/lookup?type=phone&target=XXXX`
3. Server queries relevant cache table (ScamNumberCache/ScamUrlCache/ScamBankCache)
4. Server runs RiskEvaluationService.evaluateRisk():
   - **Community Reports (35%)**: Logarithmic scale of report count
   - **Verification Ratio (30%)**: Percentage of verifications agreeing target is scam
   - **Reporter Reputation (20%)**: Average reputation of reporters
   - **Recency (15%)**: Days since last report (exponential decay)
   - **Boost: SemakMule match**: Score set to 75-90 based on risk level
   - **Boost: Google Safe Browsing**: Score set to 90 if flagged
   - **Boost: URL Heuristics**: Variable boost for suspicious patterns
5. Server logs result to TransactionJournal (type: PHONE/URL/BANK)
6. Client displays risk score with color coding:
   - 0-39: Green (Low Risk)
   - 40-74: Yellow (Medium Risk)
   - 75-100: Red (High/Critical Risk)
7. Client shows: risk level, report count, categories, last reported date, verification count

### Inputs
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| type | String | Yes | phone\|url\|bank |
| target | String | Yes | Non-empty, valid format per type |

### Outputs
```json
{
  "found": true,
  "score": 78,
  "level": "high",
  "reasons": ["12 community reports", "High verification agreement", "Recently reported"],
  "factors": {
    "communityReports": 12,
    "verifiedReports": 9,
    "avgReporterReputation": 45,
    "recencyScore": 0.85,
    "verificationRatio": 0.75,
    "semakMuleFound": false
  },
  "categories": ["MACAU_SCAM", "IMPERSONATION"],
  "lastReported": "2026-03-09T14:30:00Z",
  "checkedAt": "2026-03-11T10:00:00Z"
}
```

### Edge Cases
- Target not found in database → Return score 0 with `found: false`
- Partial phone number → Validate format, reject if <8 digits
- International URL → Follow redirect chain, check final destination
- Bank account with leading zeros → Preserve formatting during lookup
- Redis cache miss → Fall back to database query

### Error Handling
- External API (SemakMule) timeout → Proceed without external boost, note in response
- Rate limited → Return 429 (100 scans/hour)

---

## FSD-04: Community Verification

### Description
Users upvote or downvote scam reports to collectively validate or invalidate claims. Verification votes are weighted by reporter reputation.

### Trigger
User taps "Verify" or "Deny" button on a community report.

### Functional Flow
1. User views a public report in the community feed
2. User taps "I've seen this" (upvote) or "Not a scam" (downvote)
3. Client sends `POST /reports/verify` with `{ reportId, isSame: true/false }`
4. Server validates: user has not already voted on this report (@@unique constraint)
5. Server creates Verification record
6. Server recalculates report risk score with new verification data
7. Server updates cache tables with new verification count
8. Server awards reporter points if verification confirms their report
9. Server awards voter points (+2 for participating)

### Inputs
| Field | Type | Required |
|-------|------|----------|
| reportId | String | Yes |
| isSame | Boolean | Yes |

### Outputs
| Scenario | Status | Response |
|----------|--------|----------|
| Success | 201 | `{ verification, pointsAwarded }` |
| Already voted | 409 | `{ message: "Already verified" }` |
| Report not found | 404 | `{ message: "Report not found" }` |

### Edge Cases
- User tries to verify own report → Should be blocked (server-side check)
- Report is already rejected by admin → Verification should still be allowed (community disagrees)
- Flood of downvotes → May trigger content flag for admin review

---

## FSD-05: Full Device Security Scan

### Description
Comprehensive device audit scanning installed apps for malware, permission vulnerabilities, and known threats.

### Trigger
User taps "Full Device Scan" on Home screen.

### Functional Flow
1. User taps "Start Scan"
2. ScamScannerService invokes native channel bridge
3. Progressive 6-step scan with real-time progress:
   - Step 1: Enumerate all installed apps
   - Step 2: Analyze app permissions (camera, SMS, contacts access)
   - Step 3: Verify app signatures
   - Step 4: Match against threat database (local + remote)
   - Step 5: Network connection analysis
   - Step 6: Calculate composite risk score
4. Display results: total scanned, risky apps found, overall risk score (0-100)
5. For each risky app: risk reason, uninstall button, open settings, community verdict
6. User can flag app as Safe or Report as Threat
7. Client sends `POST /features/security-scans` with scan results
8. Client sends `POST /features/apps/action` for each user verdict

### Inputs
Device-level scan (no user input required beyond initiation)

### Outputs
| Field | Type | Description |
|-------|------|-------------|
| totalAppsScanned | Int | Number of apps analyzed |
| riskyApps | Array | List of flagged apps with details |
| overallRisk | Int | 0-100 composite score |
| recommendations | Array | Security improvement suggestions |

### Edge Cases
- Scan interrupted by app backgrounding → Resume or restart
- No risky apps found → Show "All Clear" celebration
- App not in threat database → Use permission-based heuristic scoring
- AppReputation disagreement → Community majority wins

---

## FSD-06: AI Voice Scan

### Description
Real-time voice analysis during phone calls to detect scam patterns using AI.

### Trigger
User taps "Voice Scan" while on an active call (Premium feature).

### Functional Flow
1. System checks biometric authentication (fingerprint/face)
2. System verifies active subscription (Premium required)
3. Audio recording begins via `record` package
4. Real-time transcription displayed on screen
5. NLP pattern matching runs against transcription:
   - Authority impersonation keywords
   - Financial urgency phrases
   - Personal information requests
   - Pressure tactics detection
6. Risk score updates in real-time on UI
7. On call end: full analysis submitted to `POST /features/analyze-voice`
8. Post-call safety check dialog displayed
9. User prompted to report if high risk

### Inputs
| Field | Type | Required |
|-------|------|----------|
| audioData | Binary | Yes (recorded audio) |
| callDuration | Int | Yes (seconds) |
| callerNumber | String | No |

### Outputs
```json
{
  "riskScore": 85,
  "patterns": ["authority_claim", "urgency", "financial_request"],
  "transcription": "...",
  "summary": "Caller claimed to be from a bank...",
  "recommendation": "HIGH_RISK - Do not share personal information"
}
```

### Edge Cases
- User denies microphone permission → Feature unavailable, prompt permission
- Call ends before analysis completes → Submit partial analysis
- Background noise interference → Lower confidence score
- Non-supported language → Fall back to keyword detection only
- Premium subscription expired mid-scan → Complete current scan, block next

### Error Handling
- Audio capture failure → Notify user, suggest retry
- API analysis timeout → Return partial result with disclaimer
- Network unavailable → Queue analysis for later submission

---

## FSD-07: Alert Subscription & Delivery

### Description
Users configure alert preferences by category and geographic radius. System delivers alerts via push notification, in-app, and optional email digest.

### Trigger
- Background: Alert Engine generates alerts based on report clustering
- User action: Configures preferences in Alert Center

### Functional Flow
1. User opens Alert Center → `GET /alerts` (personal alerts)
2. User configures preferences → `POST /alerts/subscribe`:
   - Categories: PHISHING, LOGIN, NETWORK, COMMUNITY, MACAU_SCAM, MULE_ACCOUNT
   - Location: latitude, longitude
   - Radius: 5-50 km (default 15km)
   - Email digest: enabled/disabled
   - FCM token: registered automatically
3. Alert Engine (Bull Queue, hourly cron):
   - Clusters reports by region and category
   - Identifies trending threats (> threshold in timeframe)
   - Matches against user subscriptions (category + geo radius)
   - Creates Alert records per matched user
   - Sends FCM push notifications
4. User receives push → Opens Alert Center
5. User can: mark read, resolve with action, view details

### Inputs (Subscription)
| Field | Type | Required |
|-------|------|----------|
| categories | String[] | Yes |
| latitude | Float | No |
| longitude | Float | No |
| radiusKm | Int | No (default: 15) |
| emailDigestEnabled | Boolean | No (default: false) |

### Outputs (Alert)
```json
{
  "id": "...",
  "title": "New Phishing Campaign Detected",
  "message": "15 reports of bank impersonation SMS...",
  "type": "ALERT",
  "category": "PHISHING",
  "severity": "HIGH",
  "isRead": false,
  "riskScore": 82,
  "metadata": { "reportCount": 15, "region": "Selangor" }
}
```

---

## FSD-08: Transaction Journal

### Description
Pre-transfer verification and payment logging tool. Users record transactions, check counterparties, and convert suspicious entries to scam reports.

### Trigger
User opens Transaction Journal from Home screen.

### Functional Flow
1. User taps "New Transaction"
2. Selects check type: PHONE, URL, BANK, DOC, MANUAL, MSG, QR, VOICE
3. Enters target (counterparty phone/bank/URL)
4. System runs automatic lookup → Shows risk assessment inline
5. User enters: amount, merchant, payment method, platform, notes
6. User saves entry → `POST /transactions`
7. Entry logged with risk score and status (SAFE/SUSPICIOUS/BLOCKED/SCAMMED)
8. If suspicious: "Report" button available → Converts to ScamReport with pre-filled data

### Inputs
| Field | Type | Required |
|-------|------|----------|
| checkType | Enum | Yes |
| target | String | No |
| amount | Float | No |
| merchant | String | No |
| paymentMethod | String | No |
| platform | String | No |
| notes | String | No |

### Edge Cases
- User logs transaction after being scammed → Status = SCAMMED, auto-generates report
- Target already in database as high risk → Show warning before saving
- Duplicate transaction within 5 minutes → Prompt confirmation

---

## FSD-09: Admin Threat Broadcasting

### Description
Administrators send system-wide threat intelligence alerts to all users.

### Trigger
Admin clicks "New Broadcast" in admin dashboard.

### Functional Flow
1. Admin fills: title (max 100 chars), message body
2. System shows warning: "This will be sent to ALL users"
3. Admin confirms broadcast
4. Server creates Alert record for every active user (type: BROADCAST)
5. Server sends FCM push notification to all registered devices
6. Server records recipientCount
7. Broadcast appears in admin history with stats

### Inputs
| Field | Type | Required | Validation |
|-------|------|----------|------------|
| title | String | Yes | Max 100 characters |
| message | String | Yes | Non-empty |

### Outputs
| Scenario | Status | Response |
|----------|--------|----------|
| Success | 201 | `{ broadcast, recipientCount }` |
| Not admin | 403 | `{ message: "Forbidden" }` |

### Edge Cases
- Broadcasting to 100K+ users → Batched FCM delivery, queue-based processing
- Admin accidentally sends → No undo (broadcasts are immutable)
- User has notifications disabled → Still appears in Alert Center on next open

### Error Handling
- FCM partial delivery failure → Log failed tokens, retry once
- Database transaction timeout on large user base → Batch inserts (1000 per batch)
