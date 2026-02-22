# FraudShield — MVP Launch Checklist

This checklist contains only the absolute bare minimum requirements to safely launch FraudShield as a Minimum Viable Product (MVP) on the App Store and Play Store. Polishing and scaling optimizations are deferred for post-launch updates.

> **Last updated:** 22 Feb 2026

---

## 🔴 Phase 1: Absolute Bare Minimum (Must Have for Go-Live)
*Estimated Time: ~3-4 Hours total*

If these are not fixed, you risk losing data, leaking passwords, or facing app store rejection.

- [ ] **D1. Add HTTPS / SSL (1-2 hrs)**
  - Mobile apps require secure connections. Add an nginx container with Let's Encrypt SSL or a Cloudflare proxy.
- [x] **M1. Hide Voice Detection (30 min)**
  - The current voice screen uses mock data. Replace it with a "Coming Soon" overlay to avoid bad reviews.
- [x] **S1. Fix JWT Secret (10 min)**
  - Remove the hardcoded fallback (`'your-super-secret-jwt-key'`) in `auth.service.ts` so the system throws an error if `JWT_SECRET` is missing.
- [x] **S2. Stop Error Logging Passwords (10 min)**
  - Remove `body: req.body` from the global error handler (`app.ts`) to avoid logging plaintext passwords.
- [x] **S3. Restrict CORS (10 min)**
  - Set `CORS_ORIGIN` in `.env.prod` to prevent falling back to `'*'` and allowing unauthorized web origins.
- [x] **S9. Payload Size Limit (5 min)**
  - Add `express.json({ limit: '1mb' })` in `app.ts` to prevent memory exhaustion from large payloads.
- [ ] **D3. Set up automated database backups (1 hr)**
  - Set up a daily automated backup (e.g., pg_dump script to a storage bucket) to prevent complete data loss on failure.

---

## 🟠 Phase 2: Highly Recommended (Should Have for Day 1 UX)
*Estimated Time: ~4-5 Hours total*

The app functions without these, but lacking them will severely hurt early user retention and debugging capabilities.

- [ ] **U1. "Forgot Password" Flow (3-4 hrs)**
  - Implement an email-based password reset. Without it, early adopters who forget their password are permanently locked out.
- [ ] **M6. Crash Reporting (1 hr)**
  - Integrate Firebase Crashlytics or Sentry. Real users will experience edge-case crashes that you won't catch in emulators.

---

## 🟢 Phase 3: Post-Launch / V1.1 (Deferred)
The following tasks from the main production checklist have intentionally been deferred until after the MVP launch:

*   **Security:** Email Verification (S7), JWT Refresh Tokens (S6).
*   **Reliability:** API Pagination (R2), Request Timeout (R3), Database Indexes (DB1), DB Connection Pooling (DB4), Soft Delete (DB3).
*   **Mobile App:** Secure token storage migration (M4), Certificate Pinning (M3), App Versioning check (M5), removing debug logs (M7), improved loading/error states (M2).
*   **Compliance & Docs:** PDPA Data Export (U2), Unit Tests (R5), API Docs (R6), Terms update consent (U3), Structured Logging (R4), Re-enable Rewards Routes (R1).
