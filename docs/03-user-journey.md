# 3. User Journey

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 3.1 First-Time User Journey

### Step 1: App Launch & Splash
```
[User]                           [System]
  │ Opens app                      │
  │──────────────────────────────→│
  │                                │ Display animated splash screen
  │                                │ Initialize Firebase (Crashlytics, FCM)
  │                                │ Run SecurityService checks
  │                                │   - Jailbreak/root detection
  │                                │   - App signature verification
  │                                │ Check authentication state
  │←──────────────────────────────│
  │ If compromised device:         │
  │ → SecurityAlertScreen          │
  │ If first launch:               │
  │ → OnboardingScreen             │
  │ If authenticated:              │
  │ → HomeScreen                   │
```

### Step 2: Onboarding
```
[User]                           [System]
  │ Views 3-step tutorial          │
  │   1. "Protect Yourself"        │ Lottie animations
  │   2. "Community Power"         │ PageView with indicators
  │   3. "Stay Alert"              │
  │ Taps "Get Started"            │
  │──────────────────────────────→│
  │                                │ Navigate to LoginScreen
```

### Step 3: Registration
```
[User]                           [System]
  │ Taps "Sign Up"                │
  │──────────────────────────────→│
  │                                │ Show SignUpScreen
  │ Enters:                        │
  │   - Full name                  │
  │   - Email                      │
  │   - Password (+ confirm)       │
  │   - Accepts Terms & Privacy    │
  │   - Completes Turnstile CAPTCHA│
  │ Taps "Create Account"         │
  │──────────────────────────────→│
  │                                │ POST /auth/signup
  │                                │ Validate uniqueness
  │                                │ Hash password (bcrypt)
  │                                │ Generate OTP → Send email
  │                                │ Create User + Profile records
  │←──────────────────────────────│
  │ Redirect to Email Verification │
  │ Enters 6-digit OTP            │
  │──────────────────────────────→│
  │                                │ POST /auth/verify-email
  │                                │ Verify OTP against Redis
  │                                │ Mark emailVerified = true
  │                                │ Generate JWT tokens
  │←──────────────────────────────│
  │ Redirect to HomeScreen         │
  │                                │ Trigger App Attestation
  │                                │ POST /attestation/verify
```

### Step 4: Home Screen (First Load)
```
[User]                           [System]
  │ Lands on HomeScreen           │
  │                                │ Fetch Security Health Score
  │                                │ Fetch user profile (points, badges)
  │                                │ Show Security Guide (first-time)
  │                                │ Initialize WebSocket connection
  │                                │ Register FCM token
  │                                │ Display:
  │                                │   - Security Health Card (animated)
  │                                │   - Quick Protection Actions grid
  │                                │   - Premium Protection carousel
  │                                │   - Recent Reports section
  │                                │   - Floating bottom nav bar
  │←──────────────────────────────│
  │ Sees dashboard with 0 reports  │
  │ Security score: needs setup    │
```

---

## 3.2 Core User Flows

### Flow A: Check a Suspicious Phone Number
```
[User]                           [System]
  │ Taps "Phone Lookup" on Home   │
  │──────────────────────────────→│
  │                                │ Navigate to lookup interface
  │ Enters phone number           │
  │ Taps "Check"                  │
  │──────────────────────────────→│
  │                                │ GET /reports/lookup?type=phone&target=XXX
  │                                │ Query ScamNumberCache
  │                                │ Run RiskEvaluationService:
  │                                │   - Community reports (35%)
  │                                │   - Verification ratio (30%)
  │                                │   - Reporter reputation (20%)
  │                                │   - Recency (15%)
  │                                │   - Boost if SemakMule match
  │                                │ Log to TransactionJournal
  │←──────────────────────────────│
  │ Sees result:                   │
  │   Risk Score: 78 (HIGH)        │
  │   Reports: 12                  │
  │   Categories: [Macau Scam]     │
  │   Last reported: 2 days ago    │
  │                                │
  │ Option A: "Report as Scam"    │→ Opens ScamReportingScreen (pre-filled)
  │ Option B: "Safe, proceed"     │→ Logs outcome in TransactionJournal
  │ Option C: Provide feedback    │→ POST /reports/lookup-feedback
```

### Flow B: Submit a Scam Report
```
[User]                           [System]
  │ Taps "Report Scam" on Home    │
  │──────────────────────────────→│
  │                                │ Navigate to ScamReportingScreen
  │                                │
  │ Step 1: Identity Selection     │
  │ Selects: Phone / Bank /        │
  │   Social / Website / Other     │
  │ Enters target (phone/URL/etc) │
  │ Taps "Next"                   │
  │──────────────────────────────→│
  │                                │
  │ Step 2: Category Selection     │
  │ Selects: Investment / Phishing │
  │   / Job / Love / Shopping /    │
  │   Other                        │
  │ Taps "Next"                   │
  │──────────────────────────────→│
  │                                │
  │ Step 3: Details & Evidence     │
  │ Writes description             │
  │ Picks incident location (map)  │
  │ Attaches screenshots (optional)│
  │ Taps "Next"                   │
  │──────────────────────────────→│
  │                                │ Validate location distance
  │                                │
  │ Step 4: Review & Submit        │
  │ Reviews all details            │
  │ Toggles community visibility   │
  │ Taps "Submit Report"          │
  │──────────────────────────────→│
  │                                │ POST /reports
  │                                │ Content Moderation:
  │                                │   - PII detection (IC, email, phone)
  │                                │   - OpenAI offensive check
  │                                │ Entity extraction (phones, URLs, accounts)
  │                                │ Create ScamReport record
  │                                │ Update cache tables (ScamNumberCache, etc.)
  │                                │ Award Shield Points (+10)
  │                                │ Emit WebSocket: new_report
  │                                │ Check badge triggers
  │←──────────────────────────────│
  │ Success screen with:           │
  │   - Points earned confirmation │
  │   - Report ID                  │
  │   - Share option               │
```

### Flow C: Full Device Security Scan
```
[User]                           [System]
  │ Taps "Device Scan" on Home    │
  │──────────────────────────────→│
  │                                │ Navigate to ScamScannerScreen
  │ Taps "Start Scan"            │
  │──────────────────────────────→│
  │                                │ 6-step progressive scan:
  │                                │   1. Enumerate installed apps
  │  ░░░░░░░░░░ 17%               │   2. Check app permissions
  │  ██░░░░░░░░ 33%               │   3. Signature verification
  │  ████░░░░░░ 50%               │   4. Threat database matching
  │  ██████░░░░ 67%               │   5. Network analysis
  │  ████████░░ 83%               │   6. Risk score calculation
  │  ██████████ 100%              │
  │←──────────────────────────────│
  │ Sees results:                  │
  │   Overall Risk: 35 (LOW)       │
  │   Apps Scanned: 87             │
  │   Risky Apps: 2                │
  │                                │
  │ For each risky app:            │
  │   - Risk reason                │
  │   - "Uninstall" button         │
  │   - "Open Settings" button     │
  │   - Community verdict buttons  │
  │     (Flag as Safe / Report)    │
  │──────────────────────────────→│
  │                                │ POST /features/security-scans
  │                                │ Save scan results
  │                                │ POST /features/apps/action
  │                                │ Update AppReputation
  │                                │ Award points for scan
```

### Flow D: Premium Voice Scan (During Call)
```
[User]                           [System]
  │ Receives suspicious call      │
  │                                │ CallStateService detects incoming call
  │                                │ Check number against ScamNumberCache
  │                                │ If high risk: show Caller ID overlay
  │                                │
  │ Opens app during call          │
  │ Taps "Voice Scan"            │
  │──────────────────────────────→│
  │                                │ Biometric authentication check
  │                                │ Check subscription (Premium required)
  │                                │ Start audio recording
  │                                │ Begin real-time analysis
  │                                │
  │ Continues conversation         │ Live transcription display
  │                                │ Pattern matching (keywords, tactics)
  │                                │ Risk score updating in real-time
  │                                │
  │ Call ends                      │
  │                                │ POST /features/analyze-voice
  │                                │ Generate analysis summary
  │                                │ Show Post-Call Safety Check dialog
  │←──────────────────────────────│
  │ Sees: "High Risk Detected"    │
  │   Patterns: authority claim,   │
  │   urgency, financial request   │
  │   Score: 85/100                │
  │                                │
  │ Prompted: "Report this call?" │
  │ Taps "Yes"                    │→ Pre-filled ScamReportingScreen
```

---

## 3.3 Admin User Journey

### Admin Report Moderation Flow
```
[Admin]                          [System]
  │ Logs into Admin Dashboard     │
  │──────────────────────────────→│
  │                                │ POST /auth/login
  │                                │ Validate role === 'admin'
  │                                │ Store JWT in localStorage
  │                                │ Redirect to Dashboard
  │                                │
  │ Views Dashboard stats:        │
  │   Total Users: 5,234          │
  │   Total Reports: 1,847        │
  │   Pending: 42                 │
  │   Resolved: 1,805             │
  │                                │
  │ Clicks "Scam Reports"        │
  │──────────────────────────────→│
  │                                │ GET /admin/reports?page=1&limit=15
  │                                │
  │ Clicks "Deep Dive" on report  │
  │──────────────────────────────→│
  │                                │ GET /admin/reports/:id
  │                                │ Show ReportDetailModal:
  │                                │   - Full description
  │                                │   - Target info
  │                                │   - AI Moderation results
  │                                │   - Device fingerprint
  │                                │   - Evidence (JSON)
  │                                │   - Location (Google Maps link)
  │                                │   - Reporter info
  │                                │
  │ Clicks "Verify & Approve"    │
  │──────────────────────────────→│
  │                                │ PATCH /admin/reports/:id/status
  │                                │   { status: "VERIFIED" }
  │                                │ Create AuditLog entry
  │                                │ Update cache tables
  │                                │ Trigger Alert Engine
  │                                │ Award reporter points (+5 reputation)
  │←──────────────────────────────│
  │ Report status updates to green │
```

---

## 3.4 System Interaction Lifecycle

```
┌──────────┐     ┌──────────────┐     ┌──────────────┐     ┌───────────┐
│  Mobile   │────→│   Backend    │────→│  PostgreSQL   │     │   Redis   │
│   App     │←────│   API        │←────│  (Prisma)     │     │  (Cache)  │
│ (Flutter) │     │ (Express)    │     └──────────────┘     └───────────┘
└──────────┘     └──────────────┘            │                    │
      │                │                      │                    │
      │                ├── Socket.io ──────→ Real-time events     │
      │                ├── Bull Queue ─────→ Background jobs      │
      │                ├── OpenAI API ─────→ Content moderation   │
      │                ├── Firebase ────────→ Push notifications   │
      │                ├── S3 ─────────────→ File storage         │
      │                └── Google APIs ────→ Safe Browsing, Maps  │
      │                                                           │
      │  ┌──────────┐                                             │
      └──│  Admin    │── Axios ──→ Same Backend API ──────────────┘
         │Dashboard  │
         │ (React)   │
         └──────────┘
```

---

## 3.5 Notification & Alert Flow

```
Trigger Event                    Processing                    Delivery
─────────────                    ──────────                    ────────
Report verified          →  AlertEngineService       →  FCM Push Notification
                                    │                    Socket.io real-time
                                    │                    In-app Alert Center
                                    │
Trending scam detected   →  Bull Queue (hourly)     →  Regional push alerts
                                    │                    Email digest (if opted)
                                    │
Admin broadcast          →  POST /admin/broadcasts  →  All users via FCM
                                    │                    Alert record per user
                                    │
Caller ID risk           →  CallStateService        →  System overlay
                                    │                    Foreground notification
                                    │
Subscription expiry      →  Background check        →  In-app alert
                                                        Email notification
```
