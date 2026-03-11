# 1. Product Overview

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 (Build 9) |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 1.1 Product Vision

FraudShield is a **community-powered, AI-enhanced anti-fraud mobile platform** designed to protect individuals in Malaysia from financial scams, phishing attacks, and fraudulent digital activities. The platform combines crowdsourced intelligence, real-time threat detection, and behavioral analysis to create a comprehensive shield against evolving fraud tactics.

The vision is to become the **national standard for consumer fraud protection** — empowering every Malaysian with the tools, knowledge, and community support to identify, report, and prevent scam encounters before financial loss occurs.

---

## 1.2 Problem Statement

Malaysia faces a rapidly escalating fraud crisis:

- **Rising scam volume**: Phone scams (Macau scams), online investment fraud, phishing links, and mule account operations are increasing year over year.
- **Information asymmetry**: Victims lack real-time intelligence about known scam numbers, URLs, and bank accounts. By the time warnings are published through official channels, thousands more have been targeted.
- **Fragmented reporting**: Existing reporting mechanisms (CCID, BNM) are slow, not interconnected, and provide no feedback loop to reporters.
- **Sophisticated tactics**: Scammers use AI-generated voice, deepfake caller IDs, and multi-channel approaches that bypass basic awareness.
- **No unified defense**: There is no single platform that combines detection (URL, voice, message, file scanning), community intelligence, and real-time protection.

---

## 1.3 Target Users

### Primary Users
| Segment | Description | Key Needs |
|---------|-------------|-----------|
| **General Public** | Malaysian adults (18-65) with smartphones | Simple fraud checking tools, scam reporting, real-time alerts |
| **Vulnerable Demographics** | Elderly users, non-tech-savvy individuals | Caller ID protection, voice scam detection, simplified UX |
| **Frequent Digital Users** | Online shoppers, crypto traders, gig workers | URL verification, transaction journaling, mule account checking |

### Secondary Users
| Segment | Description | Key Needs |
|---------|-------------|-----------|
| **Platform Administrators** | Internal fraud analysts and system operators | Report moderation, fraud labeling, broadcast management, user management |
| **Community Contributors** | Active reporters and verification participants | Gamification rewards, reputation system, leaderboard recognition |

### Geographic Focus
- **Primary Market**: Malaysia (Bahasa Malaysia + English localization)
- **Regulatory Context**: PDPA (Personal Data Protection Act 2010), BNM guidelines, MCMC regulations

---

## 1.4 Core Value Proposition

### For End Users
| Value | How Delivered |
|-------|---------------|
| **Instant Scam Verification** | Check any phone number, URL, bank account, or QR code against a live community database in seconds |
| **AI-Powered Detection** | Multi-modal scanning: voice analysis, NLP message screening, PDF/APK malware detection, URL redirect chain analysis |
| **Real-Time Protection** | Caller ID overlay during incoming calls, clipboard monitoring, push notification alerts for regional threats |
| **Community Intelligence** | Crowdsourced reports with verification voting, reputation-weighted risk scoring, trending scam dashboards |
| **Privacy-First Design** | AES-256-GCM encryption of PII, anonymized community interactions, GDPR-aligned data export and deletion |

### For Administrators
| Value | How Delivered |
|-------|---------------|
| **Fraud Intelligence Hub** | Global scam entity database, transaction risk analysis, fraud labeling system |
| **Community Moderation** | Content flagging, AI+PII moderation, report verification workflow |
| **Threat Broadcasting** | System-wide alert distribution to all users with FCM push notifications |
| **Operational Visibility** | Dashboard statistics, Prometheus metrics, audit logging |

### Competitive Differentiators
1. **Community-first approach**: Unlike government portals (SemakMule), FraudShield provides real-time bidirectional intelligence
2. **Multi-modal AI scanning**: Voice, message, URL, QR, PDF, and APK analysis in one app
3. **Gamification layer**: Shield Points, badges, leaderboards, and reward store incentivize reporting
4. **Real-time caller protection**: System overlay during active calls (Phase 2)
5. **Offline capability**: Scam number database synced locally for offline verification
6. **Malaysian context**: Localized for Macau scam patterns, Malaysian IC detection, BNM mule account database integration

---

## 1.5 Product Ecosystem

```
┌─────────────────────────────────────────────────────────────────┐
│                     FraudShield Ecosystem                       │
├─────────────────┬───────────────────────┬───────────────────────┤
│  Mobile App     │   Backend API         │   Admin Dashboard     │
│  (Flutter)      │   (Node.js/Express)   │   (React/Vite)        │
│                 │                       │                       │
│  • Scam Scanner │   • Auth & Security   │   • User Management   │
│  • Reporting    │   • Risk Evaluation   │   • Report Moderation │
│  • Caller ID    │   • AI Moderation     │   • Fraud Analysis    │
│  • Rewards      │   • Alert Engine      │   • Broadcasts        │
│  • Community    │   • Gamification      │   • Subscriptions     │
│  • Voice Scan   │   • File Processing   │   • Rewards Store     │
│  • QR/URL Check │   • Real-time WS      │   • Global Database   │
└─────────────────┴───────────────────────┴───────────────────────┘
        │                    │                        │
        └────── PostgreSQL ──┴──── Redis ─────────────┘
                Firebase (FCM, Crashlytics, Auth)
                S3 (File Storage)
                OpenAI (Content Moderation)
                Google Play Integrity API
```

---

## 1.6 Key Metrics (North Star)

| Metric | Description |
|--------|-------------|
| **Reports Submitted** | Total community scam reports — measures engagement |
| **Verification Participation** | % of reports receiving community verification votes |
| **Detection Accuracy** | False positive/negative rate of AI scanning features |
| **Time-to-Alert** | Latency from report submission to community alert broadcast |
| **User Retention (D7/D30)** | Daily active users returning after 7 and 30 days |
| **Prevention Rate** | Users who checked before transacting and avoided confirmed scams |
