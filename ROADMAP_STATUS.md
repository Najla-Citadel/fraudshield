# FraudShield — Core Features Roadmap Status

**Last Updated:** February 20, 2026  
**Reference:** [fraudshield_strategic_review.md](./fraudshield_strategic_review.md)

---

## Immediate Action Items (from Strategic Review)

| # | Action | Est. | Status |
|---|---|---|---|
| 1 | Remove password logging from `api_service.dart` | 5 min | ✅ Done |
| 2 | Move Docker credentials to `.env` | 15 min | ✅ Done |
| 3 | Add "Coming Soon" label to Voice Detection | 30 min | ❌ Not done |
| 4 | Integrate Google Safe Browsing API for URL checks | 2 hrs | ✅ Done |
| 5 | Add Privacy Policy screen | 1 hr | ✅ Done |
| 6 | Set up Jest testing for auth controller | 2 hrs | ✅ Done |
| 7 | Apply `express-rate-limit` to auth routes | 30 min | ✅ Done |
| 8 | Add `express-validator` to signup/login | 1 hr | ✅ Done |

---

## Priority 1 — Make Free Features Real (Weeks 1–6)

| Feature | RICE | Status | Notes |
|---|---|---|---|
| Phone Number DB Integration | 300 | ❌ Not started | Integrate CCID Semak Mule or crowdsource from community |
| URL Reputation API (Google Safe Browsing) | 300 | ✅ Done | Backend + frontend integrated |
| QR Code Deep Analysis (redirect-following) | 224 | ❌ Not started | Follow shortened URLs before analysis |

## Priority 2 — Kill or Delay Paid Features

| Feature | Action | Status |
|---|---|---|
| 🔪 Voice Scam Detection | **KILL** — Label "Coming Soon" | ❌ Still shows random results |
| ⏸️ Transaction Risk Alerts | **DELAY** — Needs bank API | N/A — Parked |
| ⏸️ Security Health Score | **DELAY** — Insufficient data inputs | N/A — Parked |

## Priority 3 — Enable Monetization (Weeks 6–12)

| Feature | RICE | Status | Notes |
|---|---|---|---|
| Payment Gateway (Billplz / Stripe MY / Revenue Monster) | 113 | ❌ Not started | Required for real subscriptions |
| Push Notification Scam Alerts | 126 | ❌ Not started | Paid feature: area-based scam alerts |

---

## Completed Work (PDPA & Security)

- [x] Privacy Policy screen (`PrivacyPolicyScreen`)
- [x] Terms of Service screen (`TermsOfServiceScreen`)
- [x] Explicit Data Consent on signup (checkbox + validation)
- [x] Account Deletion flow (PDPA right to delete)
- [x] Jest tests for auth controller (signup, login)
- [x] Rate limiting on auth routes
- [x] Input validation with `express-validator`
- [x] Docker credentials moved to `.env`
- [x] Backend deployed to DigitalOcean

## Completed Work (UI Refinements)

- [x] Fraud Check screen — Premium deep navy theme
- [x] Scam Reporting screen — Dark cards, grouped sections
- [x] Subscription screen — Subscriber/free states, RM currency
- [x] Community Feed — Premium header, floating report button
- [x] Account screen — Deep navy theme sync
- [x] Rewards Store — Consistent design system
- [x] QR Scanner — Result sheet polish, scan history
- [x] Splash screen — Native splash fix

---

## 6-Month Roadmap (from Strategic Review)

```
Month 1–2: Foundation
├── Phone/URL DB integration (Google Safe Browsing, CCID)
├── QR deep analysis (redirect following)
├── Payment gateway (Billplz)
└── Automated testing setup

Month 3–4: Growth
├── Push notification alerts
├── Community scam heat map
├── Security Health Score v1
└── PDPA compliance audit

Month 5–6: Differentiation
├── Voice detection research/POC
├── Telco API partnerships
└── Bank API partnerships
```

---

## Next Steps (Recommended Order)

1. **Google Safe Browsing API** — Makes URL fraud check real (2 hrs)
2. **Voice Detection → "Coming Soon"** — Prevent trust damage (30 min)
3. **Verify password logging removed** — Critical security (5 min)
4. **Phone Number DB** — CCID integration or community crowdsource
5. **Payment Gateway** — Enable real subscription billing
