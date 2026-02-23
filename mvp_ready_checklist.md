# FraudShield — MVP Launch Checklist

This checklist contains only the absolute bare minimum requirements to safely launch FraudShield as a Minimum Viable Product (MVP) on the App Store and Play Store. Polishing and scaling optimizations are deferred for post-launch updates.

> **Last updated:** 22 Feb 2026

---

## Overall MVP Progress

| Phase | Done | Total | Status |
|-------|:----:|:-----:|--------|
| 🔴 Phase 1: Bare Minimum | 6 / 7 | 86% | **1 item remaining** |
| 🟠 Phase 2: Recommended | 1 / 2 | 50% | 1 item remaining |
| **Total** | **7 / 9** | **78%** | Almost launch-ready |

> **Remaining blockers:** HTTPS/SSL setup and crash reporting integration.

---

## 🔴 Phase 1: Absolute Bare Minimum (Must Have for Go-Live)
*Estimated Remaining Time: ~1-2 Hours*

If these are not fixed, you risk losing data, leaking passwords, or facing app store rejection.

- [ ] **D1. Add HTTPS / SSL (1-2 hrs)** 🔴 LAST BLOCKER
  - Mobile apps require secure connections. Add an nginx container with Let's Encrypt SSL or a Cloudflare proxy.
  - **Why it's critical:** App Store may reject apps making insecure HTTP calls. Auth tokens travel in plaintext.
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
- [ ] **M6. Crash Reporting (1 hr)**
  - Integrate Firebase Crashlytics or Sentry. Real users will experience edge-case crashes that you won't catch in emulators.

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
| HTTPS/SSL | ❌ | **Must complete before launch** |
| Crash reporting | ⚠️ | Highly recommended but not blocking |
| PDPA compliance | ✅ | Privacy Policy, ToS, data consent, account deletion |

> **Bottom line:** Complete D1 (HTTPS/SSL) and you are cleared for MVP launch. M6 (crash reporting) is strongly recommended but won't block the release.
