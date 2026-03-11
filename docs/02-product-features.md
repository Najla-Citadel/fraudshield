# 2. Product Features

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 2.1 Feature Classification Legend

| Classification | Description |
|---------------|-------------|
| **Core** | Essential features available to all users — the foundation of the product |
| **Supporting** | Features that enhance core functionality and user experience |
| **Premium** | Gated behind subscription plan — advanced AI-powered capabilities |

---

## 2.2 Complete Feature Inventory

### Authentication & Onboarding

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-01 | **Email/Password Registration** | Core | User signup with email, password, and full name. Client-side validation and server-side uniqueness checks. |
| F-02 | **Email Verification (OTP)** | Core | 6-digit OTP sent via SMTP. Required before accessing most features. Redis-backed TTL expiry. |
| F-03 | **Google Sign-In** | Core | OAuth 2.0 integration via Firebase Auth. Auto-creates account on first login. |
| F-04 | **Cloudflare Turnstile CAPTCHA** | Supporting | Bot protection on registration form. Server-side verification of challenge token. |
| F-05 | **Onboarding Tutorial** | Supporting | 3-step PageView with Lottie animations introducing key features on first launch. |
| F-06 | **Biometric Authentication** | Supporting | Fingerprint/Face ID guard for sensitive operations (voice scan, file scanner, transaction journal). |
| F-07 | **App Attestation** | Core | Google Play Integrity API verification triggered post-login. Validates device integrity and app authenticity. |
| F-08 | **Forgot Password / Reset** | Core | OTP-based password reset flow via email. |
| F-09 | **Terms & Privacy Acceptance** | Core | Versioned T&C consent. App enforces acceptance before feature access. |

### Scam Detection & Scanning

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-10 | **URL/Link Checker** | Core | Analyzes URLs for phishing indicators. Follows redirect chains and checks against Google Safe Browsing + community database. Heuristic scoring for suspicious domain patterns. |
| F-11 | **QR Code Scanner** | Core | Camera-based QR scanning via `mobile_scanner`. Extracts embedded URL and runs link analysis pipeline. Detects quishing (QR phishing) attacks. |
| F-12 | **Phone Number Lookup** | Core | Checks phone numbers against community-reported scam database (ScamNumberCache). Returns risk score, report count, categories, and community verification status. |
| F-13 | **Bank Account / Mule Check** | Core | Queries community database (ScamBankCache) and integrates with BNM SemakMule API for known mule accounts. |
| F-14 | **Message Analysis (NLP)** | Premium | AI-powered SMS/message screening using NLP. Detects phishing patterns, urgency manipulation, impersonation tactics, and suspicious links. |
| F-15 | **Voice Scam Detection** | Premium | Real-time audio recording and AI analysis during calls. Identifies scam speech patterns, keywords, and manipulation techniques. Requires biometric auth. |
| F-16 | **PDF Document Scanner** | Premium | Uploads and analyzes PDF files for embedded malware, phishing links, and fraudulent document patterns. |
| F-17 | **APK Malware Scanner** | Premium | Analyzes Android APK files for known malware signatures, suspicious permissions, and threat indicators. |
| F-18 | **Full Device Security Audit** | Core | 6-step comprehensive scan: installed app enumeration, permission vulnerability analysis, threat signature matching, risk scoring. Community verdict feedback. |
| F-19 | **Clipboard Monitor** | Supporting | Background monitoring of clipboard for scam URLs, suspicious IBAN/account numbers, and QR code data. Alerts user proactively. |
| F-20 | **Macau Scam Detection** | Core | Specialized behavioral analysis for Macau-pattern scams (impersonation of authorities, pressure tactics, call-back schemes). |

### Community & Reporting

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-21 | **Scam Report Submission** | Core | 4-step wizard: Identity selection → Category → Details & Evidence (description, location, file upload) → Review & Submit. Duplicate detection, content moderation, PII screening. |
| F-22 | **Community Verification** | Core | Upvote/downvote system on reports. Users confirm or deny reported scam. Weighted by reporter reputation. Drives risk score calculation. |
| F-23 | **Community Feed** | Core | Public feed of verified scam reports. Browse, search, and interact with community-submitted intelligence. |
| F-24 | **Report Comments** | Core | Threaded commenting on reports. AI + PII moderation on all comments. Real-time WebSocket updates. Character limits (3-500). |
| F-25 | **Content Flagging** | Supporting | Users can flag reports or comments for admin review. Reasons include misinformation, PII exposure, offensive content. |
| F-26 | **Trending Scams Dashboard** | Core | Map and list view of currently trending scams by region. Category filtering, risk level indicators. |
| F-27 | **Scam Map** | Core | Google Maps integration showing geolocated scam reports. Cluster markers by density. |
| F-28 | **Report History** | Core | User's personal submission history with status tracking (Pending → Verified/Rejected). |

### Alerts & Real-Time Protection

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-29 | **Push Notifications (FCM)** | Core | Firebase Cloud Messaging for threat alerts, report status updates, and system broadcasts. |
| F-30 | **Alert Center** | Core | Centralized feed of personal alerts with categories (Phishing, Login, Network, Community, Macau Scam, Mule Account). Mark read, resolve with action. |
| F-31 | **Alert Subscription Preferences** | Supporting | Users configure alert categories, geographic radius (default 15km), and email digest preferences. |
| F-32 | **Trending Alert Engine** | Core | Background job (Bull queue) generates hourly trending alerts based on report clustering by region and category. |
| F-33 | **Caller ID Protection** (Phase 2) | Premium | Real-time call state monitoring. System overlay displays risk assessment for incoming callers. Post-call safety check dialog. |
| F-34 | **Macau Intervention Overlay** (Phase 2) | Premium | Behavioral detection during calls. System-wide overlay warns user if call patterns match Macau scam profile. |
| F-35 | **Smart Notification Capture** (Phase 2) | Premium | Notification listener service for SMS/OTP interception awareness. Auto-recording triggers during suspicious calls. |

### Gamification & Rewards

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-36 | **Shield Points** | Core | Points earned for: reporting scams, verifying reports, daily login, consecutive streaks. Daily earning cap prevents farming. |
| F-37 | **Daily Login Reward** | Core | Consecutive login streak tracking. Bonus points for maintaining streaks. |
| F-38 | **Badge System** | Core | Achievement badges across tiers (Bronze/Silver/Gold/Platinum). Triggers: reputation milestones, report count, login streak, purchases. |
| F-39 | **Leaderboard** | Core | Global ranking by points/reputation. Personal rank display. Encourages competitive reporting. |
| F-40 | **Reward Store** | Core | Redeem Shield Points for rewards (Digital/Physical/Account types). Featured items, minimum tier requirements. |
| F-41 | **Points History** | Supporting | Transaction log of all points earned and spent with descriptions. |

### Transaction & Financial Protection

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-42 | **Transaction Journal** | Core | Pre-transfer verification tool. Log payments with check type (Phone/URL/Bank/etc.), amount, merchant, platform. Links to scam lookup results. Converts to report if scam detected. |
| F-43 | **Risk Evaluation Engine** | Core | Centralized scoring (0-100) combining: community reports (35%), verification ratio (30%), reporter reputation (20%), recency (15%). Boosted by SemakMule matches and Google Safe Browsing flags. |

### User Account & Privacy

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-44 | **User Profile Management** | Core | Edit bio, avatar (character selection), preferred name, mobile, mailing address. |
| F-45 | **Security Health Score** | Core | Composite device security rating based on: email verification, app integrity, scan history, report activity, subscription status. |
| F-46 | **Privacy Settings** | Core | Granular privacy controls for data sharing and visibility preferences. |
| F-47 | **Data Export (GDPR)** | Core | Full personal data export in JSON format. Includes profile, reports, transactions, alerts, subscriptions, redemptions. |
| F-48 | **Account Deletion** | Core | GDPR-compliant account deletion. Anonymizes user record, deletes PII, preserves community reports for audit trail. |
| F-49 | **Subscription Management** | Core | View/purchase subscription plans. Enables premium features (voice scan, message analysis, PDF/APK scan, caller ID). |
| F-50 | **Change Password** | Core | Requires current password verification. |

### Administration (Admin Dashboard)

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-51 | **Admin Dashboard** | Core | Statistics overview: total users, reports, pending/resolved counts. Quick action links. |
| F-52 | **User Management** | Core | View all users. Edit profiles, roles (User/Admin), subscription assignments. View metadata (join date, points, verification status). |
| F-53 | **Report Moderation** | Core | Paginated report review. Verify/Reject/Reset status. Deep-dive modal with evidence, location (Google Maps link), AI moderation results, device fingerprint. |
| F-54 | **Global Scam Database** | Core | Search and browse crowdsourced entity database: phone numbers, malicious URLs, mule accounts. Risk score color coding, category tags. |
| F-55 | **Subscription Plan Management** | Core | CRUD operations on subscription plans: name, price (RM), duration, feature list. |
| F-56 | **Badge Configuration** | Core | CRUD operations on badge definitions: key, name, icon, tier, trigger metric, threshold. |
| F-57 | **Reward Store Management** | Core | CRUD operations on rewards. Manage redemption requests (Approve/Reject). |
| F-58 | **Threat Broadcasting** | Core | Create and send system-wide alerts to all users. View broadcast history with recipient counts. |
| F-59 | **Fraud Analysis** | Core | Review suspicious transactions. Apply/remove fraud labels. Track investigation status. |
| F-60 | **Content Flag Management** | Core | Review community-flagged content. Take action or dismiss. Status tracking (Pending/Taken Action/Dismissed). |

### Infrastructure & Platform

| # | Feature | Classification | Description |
|---|---------|---------------|-------------|
| F-61 | **Internationalization (i18n)** | Core | Full English and Bahasa Malaysia localization. ARB-based string management with generated delegates. |
| F-62 | **Dark/Light Theme** | Supporting | System-wide theme toggle via ThemeProvider. Design token-based theming with consistent surfaces. |
| F-63 | **Offline Scam Database Sync** | Core | Background periodic sync (12-hour intervals via Workmanager). Network-aware, battery-optimized. |
| F-64 | **Real-Time WebSocket** | Core | Socket.io connection for live comment updates, alert streaming, and threat intelligence synchronization. |
| F-65 | **Background Foreground Service** | Premium | Persistent Android service for call monitoring. Required for Caller ID and voice scan features. |

---

## 2.3 Feature Dependency Map

```
Authentication (F-01..F-09)
    │
    ├── Scam Detection (F-10..F-20)
    │       │
    │       └── Transaction Journal (F-42) ←→ Risk Engine (F-43)
    │
    ├── Community (F-21..F-28)
    │       │
    │       ├── Alerts (F-29..F-35)
    │       └── Gamification (F-36..F-41)
    │
    ├── Account (F-44..F-50)
    │       │
    │       └── Subscription → Unlocks Premium Features
    │
    └── Admin Dashboard (F-51..F-60)
            │
            └── Moderation ←→ Community Reports
```

---

## 2.4 Feature Maturity Matrix

| Feature Area | Status | Notes |
|-------------|--------|-------|
| Authentication | Production | Fully implemented |
| URL/QR/Phone Scanning | Production | Core detection pipeline operational |
| Community Reporting | Production | 4-step wizard with moderation |
| Gamification | Production | Points, badges, rewards functional |
| Voice Scan | Beta | Requires Premium subscription |
| Caller ID Protection | Phase 2 | Foreground service + overlay system |
| Smart Capture | Phase 2 | Notification listener integration |
| Admin Dashboard | Production | Full management capabilities |
| Offline Sync | Production | 12-hour background sync |
| AI Content Moderation | Production | OpenAI + PII detection active |
