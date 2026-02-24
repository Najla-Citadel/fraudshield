# FraudShield — MVP Launch Checklist

This checklist contains only the absolute bare minimum requirements to safely launch FraudShield as a Minimum Viable Product (MVP) on the App Store and Play Store. Polishing and scaling optimizations are deferred for post-launch updates.

> **Last updated:** 24 Feb 2026

---

## Overall MVP Progress

| Phase | Done | Total | Status |
|-------|:----:|:-----:|--------|
| 🔴 Phase 1: Bare Minimum | 7 / 7 | 100% | **✅ Complete** |
| 🟠 Phase 2: Recommended | 2 / 2 | 100% | **✅ Complete** |
| **Total** | **9 / 9** | **100%** | 🚀 MVP launch-ready |

> **All blockers cleared.** HTTPS/SSL live (Feb 24) and Firebase Crashlytics integrated (Feb 24).

---

## 🔴 Phase 1: Absolute Bare Minimum (Must Have for Go-Live)
*Estimated Remaining Time: ~1-2 Hours*

If these are not fixed, you risk losing data, leaking passwords, or facing app store rejection.

- [x] **D1. Add HTTPS / SSL** ✅
  - Nginx + Let's Encrypt SSL live on `api.fraudshieldprotect.com`. API port 3000 locked to internal only.
- [x] **M1. Hide Voice Detection (30 min)** ✅
  - Replaced with a "Coming Soon" overlay to avoid bad reviews.
- [x] **S1. Fix JWT Secret (10 min)** ✅
  - Removed the hardcoded fallback (`'your-super-secret-jwt-key'`). System throws error if `JWT_SECRET` is missing.
- [x] **S2. Stop Error Logging Passwords (10 min)** ✅
  - Removed `body: req.body` from the global error handler (`app.ts`).
- [x] **S3. Restrict CORS (10 min)** ✅
  - `CORS_ORIGIN` set in `.env.prod` to prevent falling back to `'*'`.
- [x] **S9. Payload Size Limit (5 min)** ✅
  - Added `express.json({ limit: '1mb' })` in `app.ts`.
- [x] **D3. Set up automated database backups (1 hr)** ✅
  - Daily automated pg_dump backup configured.

---

## 🟠 Phase 2: Highly Recommended (Should Have for Day 1 UX)
*Estimated Remaining Time: ~1 Hour*

The app functions without these, but lacking them will severely hurt early user retention and debugging capabilities.

- [x] **U1. "Forgot Password" Flow (3-4 hrs)** ✅
  - Email-based password reset with OTP implemented — 2-step flow on Flutter frontend.
- [x] **M6. Crash Reporting** ✅
  - Firebase Crashlytics integrated (Feb 24). Real crash events visible in Firebase console.

---

## 🟢 Phase 3: Post-Launch / V1.1 (Deferred)
The following tasks from the main production checklist have intentionally been deferred until after the MVP launch:

*   **Security:** Email Verification (S7), JWT Refresh Tokens (S6).
*   **Reliability:** API Pagination (R2), Request Timeout (R3), Database Indexes (DB1), DB Connection Pooling (DB4), Soft Delete (DB3).
*   **Mobile App:** Secure token storage migration (M4), Certificate Pinning (M3), App Versioning check (M5), removing debug logs (M7), improved loading/error states (M2).
*   **Compliance & Docs:** PDPA Data Export (U2), Unit Tests (R5), API Docs (R6), Terms update consent (U3), Structured Logging (R4), Re-enable Rewards Routes (R1).

---

## 🚀 Launch Decision Matrix

| Criteria | Status | Notes |
|----------|--------|-------|
| Core features work | ✅ | Fraud check (Google Safe Browsing), QR scan, community feed, reporting |
| Security basics | ✅ | JWT, CORS, passwords no longer logged, payload limits |
| User auth flow | ✅ | Signup, login, change password, forgot password |
| Mock features hidden | ✅ | Voice detection shows "Coming Soon" |
| Database backups | ✅ | Daily pg_dump configured |
| HTTPS/SSL | ✅ | Live on `api.fraudshieldprotect.com` (Feb 24) |
| Crash reporting | ✅ | Firebase Crashlytics integrated (Feb 24) |
| PDPA compliance | ✅ | Privacy Policy, ToS, data consent, account deletion |

> **🚀 MVP is launch-ready.** All blocking items resolved. You are cleared to submit to Google Play and the App Store.
