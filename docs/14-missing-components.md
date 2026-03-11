# 14. Missing Components

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## Critical Assessment

This section identifies weaknesses and missing components required for a production-grade fintech mobile application. Items are prioritized by severity and business impact.

---

## 14.1 Critical Missing (Must Have Before Production)

### MC-01: Automated CI/CD Pipeline
**Severity**: Critical | **Impact**: Deployment reliability, team velocity

**Current State**: Manual deployment via SSH and docker-compose commands.

**What's Missing**:
- GitHub Actions (or equivalent) workflow for automated testing on PR
- Automated build and push to container registry
- Automated staging deployment
- Automated production deployment with approval gates
- Rollback automation

**Risk**: Manual deployments are error-prone, unreproducible, and lack audit trails.

---

### MC-02: Backend Error Tracking Service (Sentry/Datadog)
**Severity**: Critical | **Impact**: Incident detection, debugging speed

**Current State**: Winston logging to console/stdout. No centralized error aggregation, alerting, or contextual debugging.

**What's Missing**:
- Sentry or Datadog integration for real-time error tracking
- Error grouping and deduplication
- Release tracking (correlate errors with deployments)
- Performance monitoring (transaction traces)
- User context in error reports (anonymized user ID, device info)

**Risk**: Production errors go unnoticed until users report them. No visibility into error frequency, trends, or impact.

---

### MC-03: Payment Integration
**Severity**: Critical | **Impact**: Revenue, subscription monetization

**Current State**: Subscriptions are created directly in the database without payment processing. No payment gateway integrated.

**What's Missing**:
- Payment gateway integration (Stripe, RevenueCat, Google Play Billing)
- Subscription lifecycle management (renewal, cancellation, grace period)
- Receipt validation (Google Play receipt verification)
- Payment failure handling and retry logic
- Invoice generation
- Refund workflow

**Risk**: No revenue collection mechanism. Subscription system is cosmetic only.

---

### MC-04: Input Validation Library
**Severity**: High | **Impact**: Security, data integrity

**Current State**: Manual validation in controllers with inconsistent patterns. Some endpoints have thorough validation, others rely on database constraints.

**What's Missing**:
- Centralized validation library (Zod, Joi, or class-validator)
- Request schema definitions for all endpoints
- Type-safe validation at controller boundary
- Consistent error response format for validation failures

**Risk**: Inconsistent validation creates gaps for malformed data injection and unexpected behavior.

---

### MC-05: API Versioning Strategy
**Severity**: High | **Impact**: Backward compatibility, mobile app updates

**Current State**: Single version prefix `/api/v1`. No version negotiation or deprecation strategy.

**What's Missing**:
- Version header or URL-based versioning strategy document
- Deprecation policy for old API versions
- Version compatibility matrix (which app versions work with which API versions)
- Forced app update mechanism based on minimum API version

**Risk**: Breaking API changes will crash older mobile app versions without a migration path.

---

### MC-06: Database Migration Management
**Severity**: High | **Impact**: Schema changes, production safety

**Current State**: Uses `prisma db push` for development and `prisma migrate deploy` for production. No migration rollback strategy.

**What's Missing**:
- Migration rollback scripts (Prisma doesn't support auto-rollback)
- Pre-migration backup automation
- Migration dry-run validation
- Schema diff review in PR process
- Zero-downtime migration patterns for large tables

**Risk**: Failed migrations in production require manual SQL intervention with potential data loss.

---

### MC-07: Centralized Log Aggregation
**Severity**: High | **Impact**: Debugging, compliance, forensics

**Current State**: Logs written to container stdout. Lost on container restart.

**What's Missing**:
- ELK Stack (Elasticsearch + Logstash + Kibana) or Grafana Loki
- Log shipping from containers to central store
- Log retention policy (30-90 days for compliance)
- Log search and filtering UI
- Alert rules on log patterns

**Risk**: Unable to investigate past incidents. No forensic trail for security events.

---

## 14.2 High Priority Missing (Should Have for Production)

### MH-01: Comprehensive Test Coverage
**Current State**: ~45% backend coverage. Limited Flutter tests.

**What's Missing**:
- Controller tests for all API endpoints
- Service tests for all business logic
- End-to-end API integration tests
- Flutter widget tests for critical screens
- Load/stress testing suite
- Estimated gap: 100+ test cases needed

---

### MH-02: API Rate Limiting Dashboard
**Current State**: Rate limits enforced but not monitored or visualized.

**What's Missing**:
- Dashboard showing rate limit usage per user/IP
- Alerting on users hitting limits frequently
- Dynamic rate limit adjustment without deployment
- Allowlist/denylist management UI

---

### MH-03: Feature Flagging System
**Current State**: No feature flags. Features are code-gated or subscription-gated.

**What's Missing**:
- Feature flag service (LaunchDarkly, Unleash, or custom)
- Gradual rollout capability (% of users)
- Kill switch for problematic features
- A/B testing infrastructure

---

### MH-04: Backup Verification
**Current State**: Automated backups at 3 AM daily, 7-day retention.

**What's Missing**:
- Automated backup restoration testing
- Backup integrity verification (checksums)
- Cross-region backup replication
- Backup monitoring alerts (failure notification)
- Point-in-time recovery capability

---

### MH-05: Admin Dashboard Authentication
**Current State**: JWT stored in localStorage. No MFA, no session management.

**What's Missing**:
- Multi-factor authentication for admin accounts
- Session timeout and inactivity logout
- IP allowlisting for admin access
- Admin audit trail export
- Role-based access control (super-admin vs. read-only admin)

---

### MH-06: iOS Support
**Current State**: Flutter framework supports iOS, but no iOS-specific implementation exists.

**What's Missing**:
- iOS-specific permission handling
- CallKit integration (iOS equivalent of CallScreeningService)
- APNs push notification configuration
- App Store compliance review
- iOS-specific certificate pinning configuration
- TestFlight beta testing setup

---

### MH-07: Data Breach Notification System
**Current State**: No automated breach detection or notification mechanism.

**What's Missing**:
- Anomaly detection on data access patterns
- Automated breach notification to affected users
- Regulatory notification workflow (PDPA Commissioner)
- Post-breach credential rotation automation

---

## 14.3 Medium Priority Missing (Nice to Have)

### MM-01: Internationalization Backend
- API response messages are hardcoded in English
- Error messages not localized
- Database content not translation-aware

### MM-02: Webhook System
- No webhook delivery for integration partners
- No event subscription mechanism for external systems

### MM-03: API Documentation (OpenAPI)
- Swagger UI exists but may not cover all endpoints
- No automated OpenAPI spec generation from code
- Missing request/response examples

### MM-04: Content Delivery Network (CDN)
- Static assets served directly from server
- No edge caching for public content (trending scams, public reports)

### MM-05: Database Read Replicas
- Single database instance for all reads and writes
- No read scaling for heavy query endpoints (leaderboard, trending)

### MM-06: Queue Dead Letter Handling
- Bull queue jobs that fail 3 times are lost
- No dead letter queue for investigation
- No job retry monitoring dashboard

### MM-07: Mobile App Offline Mode
- Offline scam number sync exists, but no offline report submission
- No offline queue for scan results or verification votes
- No conflict resolution for offline-created data

### MM-08: Accessibility Audit
- Basic accessibility via Flutter framework
- No formal WCAG compliance audit
- Screen reader testing not documented

---

## 14.4 Security Gaps

| Gap | Severity | Description |
|-----|----------|-------------|
| No WAF | High | No Web Application Firewall in front of API |
| No DDoS Protection | High | Relies on Nginx rate limiting only; no Cloudflare/AWS Shield |
| Admin no MFA | High | Admin accounts have single-factor authentication only |
| No key rotation | Medium | DB_ENCRYPTION_KEY and JWT secrets have no rotation schedule |
| Git conflict markers in env | Low | `.env.prod.example` contains unresolved merge conflict markers |
| No security scanning in CI | Medium | No automated SAST/DAST in development workflow |
| No dependency scanning | Medium | No automated `npm audit` or Snyk in pipeline |
| Session fixation | Low | Refresh token not rotated on password change |

---

## 14.5 Operational Gaps

| Gap | Severity | Description |
|-----|----------|-------------|
| Single server | Critical | No redundancy; single point of failure |
| No auto-scaling | High | Cannot handle traffic spikes |
| No health check automation | Medium | Manual health monitoring |
| No runbook documentation | Medium | No documented procedures for common incidents |
| No capacity planning | Medium | No monitoring of resource utilization trends |
| No staging environment | High | Changes deployed directly to production |
