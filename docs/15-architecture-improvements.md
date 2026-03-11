# 15. Architecture Improvement Suggestions

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 15.1 Scalability Improvements

### AI-01: Horizontal API Scaling
**Priority**: Critical | **Effort**: Medium

**Current State**: Single Node.js instance on single server.

**Recommendation**:
- Deploy API behind a load balancer (Nginx upstream or AWS ALB)
- Run 2+ API instances with PM2 cluster mode or Docker replicas
- Ensure stateless API design (already achieved — sessions in Redis)
- Add health check endpoint for load balancer probes (already exists)

```
                  ┌─────────────┐
                  │   Nginx LB  │
                  └──────┬──────┘
                ┌────────┼────────┐
                ▼        ▼        ▼
          ┌─────────┐┌─────────┐┌─────────┐
          │ API #1  ││ API #2  ││ API #3  │
          └────┬────┘└────┬────┘└────┬────┘
               │          │          │
          ┌────┴──────────┴──────────┴────┐
          │     PostgreSQL + Redis         │
          └───────────────────────────────┘
```

**Impact**: Eliminates single point of failure, enables zero-downtime deployments.

---

### AI-02: Database Read Replicas
**Priority**: High | **Effort**: Medium

**Current State**: Single PostgreSQL instance handles all reads and writes.

**Recommendation**:
- Add PostgreSQL streaming replica for read-heavy queries
- Route read queries (leaderboard, trending, public reports, lookup) to replica
- Keep writes on primary
- Prisma supports `$queryRaw` for replica routing; alternatively, use connection pool with read/write splitting

**Target Queries for Replica**:
- `GET /reports/public` (paginated public feed)
- `GET /features/leaderboard` (top users)
- `GET /alerts/trending` (trending scams)
- `GET /reports/lookup` (read-only lookups)
- `GET /admin/stats` (dashboard statistics)

**Impact**: 60-70% read traffic offloaded from primary, enabling write performance headroom.

---

### AI-03: Caching Layer Enhancement
**Priority**: High | **Effort**: Low

**Current State**: Redis used for rate limiting, OTPs, and anti-replay. Limited use for response caching.

**Recommendation**:
- Cache risk evaluation results (TTL: 5 minutes)
- Cache leaderboard results (TTL: 15 minutes)
- Cache trending scams response (TTL: 10 minutes)
- Cache app configuration (TTL: 1 hour)
- Cache badge definitions (TTL: 1 hour)
- Implement cache invalidation on write operations

```
Request → Check Redis Cache → Cache hit? → Return cached
                            → Cache miss? → Query DB → Store in Redis → Return
```

**Impact**: 3-5x reduction in database queries for common endpoints.

---

### AI-04: Event-Driven Architecture Migration
**Priority**: Medium | **Effort**: High

**Current State**: Synchronous processing with some Bull queue usage.

**Recommendation**: Introduce event bus for decoupled processing:
```
Report Submitted → Event Bus → [Cache Update Worker]
                             → [Alert Engine Worker]
                             → [Points Award Worker]
                             → [Notification Worker]
                             → [Analytics Worker]
```

**Implementation Options**:
- **Phase 1**: Expand Bull queue usage for all side effects
- **Phase 2**: Migrate to Apache Kafka or AWS SQS for true event streaming
- **Phase 3**: Consider CQRS pattern for read/write separation

**Impact**: Faster API response times (side effects async), better failure isolation, easier feature addition.

---

### AI-05: CDN for Static Content
**Priority**: Medium | **Effort**: Low

**Recommendation**:
- Serve evidence files via CloudFront/Cloudflare CDN
- Cache public API responses at edge (trending, public reports)
- Use presigned S3 URLs with CDN distribution
- Admin dashboard static assets via CDN

**Impact**: Lower server bandwidth, faster file delivery, reduced origin load.

---

## 15.2 Security Improvements

### SI-01: Web Application Firewall (WAF)
**Priority**: Critical | **Effort**: Low

**Current State**: No WAF protection. Relies on Helmet headers and rate limiting.

**Recommendation**:
- Deploy Cloudflare WAF or AWS WAF in front of API
- Enable OWASP Core Rule Set
- Configure custom rules for known attack patterns
- IP reputation filtering
- Geographic blocking (if needed)
- Bot detection and management

**Impact**: Blocks automated attacks, SQL injection, XSS, before they reach the application.

---

### SI-02: Admin Multi-Factor Authentication
**Priority**: Critical | **Effort**: Medium

**Current State**: Admin accounts use single-factor (password) authentication.

**Recommendation**:
- Add TOTP-based MFA (Google Authenticator, Authy)
- Require MFA on every admin login
- Store MFA secrets encrypted in database
- Provide backup codes for recovery
- Log MFA success/failure in audit trail

**Impact**: Prevents admin account takeover even with compromised credentials.

---

### SI-03: Secret Rotation Automation
**Priority**: High | **Effort**: Medium

**Current State**: Static secrets (JWT_SECRET, DB_ENCRYPTION_KEY) with no rotation.

**Recommendation**:
- Implement JWT secret rotation with dual-key validation (accept both old and new during rotation window)
- DB_ENCRYPTION_KEY rotation with re-encryption migration script
- Automated rotation schedule (quarterly for JWT, annually for encryption key)
- Use HashiCorp Vault or AWS Secrets Manager for secret storage
- Eliminate secrets from environment files

**Impact**: Limits damage from secret exposure, meets security compliance requirements.

---

### SI-04: Database Activity Monitoring
**Priority**: High | **Effort**: Medium

**Recommendation**:
- Enable PostgreSQL `pgaudit` extension for SQL-level audit logging
- Monitor for bulk data exports (SELECT * patterns)
- Alert on unusual query patterns (off-hours, new IPs)
- Log all DDL operations (schema changes)
- Integrate with SIEM if available

**Impact**: Detects unauthorized data access, supports forensic investigation.

---

### SI-05: Token Security Enhancement
**Priority**: Medium | **Effort**: Medium

**Recommendation**:
- Migrate from HS256 to RS256 (asymmetric JWT signing)
- Implement refresh token rotation on every use
- Add device fingerprinting to token validation
- Rotate refresh token on password change
- Implement concurrent session limits (max 3 devices)

**Impact**: Reduces token theft attack surface, enables device-level session management.

---

### SI-06: Rate Limiting Enhancement
**Priority**: Medium | **Effort**: Low

**Recommendation**:
- Add distributed rate limiting (consistent across API replicas)
- Implement adaptive rate limiting (tighten under attack)
- Add per-user daily quotas (not just per-window)
- Block IPs with repeated rate limit violations
- Rate limit WebSocket connections

---

## 15.3 Fraud Detection Improvements

### FD-01: Machine Learning Risk Scoring
**Priority**: High | **Effort**: High

**Current State**: Rule-based composite scoring with fixed weights.

**Recommendation**:
- Train ML model on historical report data (verified vs. rejected)
- Features: report volume, verification ratio, reporter behavior, temporal patterns, geographic clustering
- Deploy as separate inference service (Python/FastAPI)
- A/B test ML score vs. rule-based score
- Gradually transition to ML-primary with rules as fallback

```
Lookup Request → Feature Extraction → ML Model Inference → Score
                                    → Rule Engine (fallback) → Score
                                    → Ensemble (weighted blend)
```

**Impact**: Improved detection accuracy, adapts to evolving scam patterns, reduces false positives.

---

### FD-02: Network Graph Analysis
**Priority**: Medium | **Effort**: High

**Recommendation**:
- Build relationship graph: phone numbers ↔ reports ↔ users ↔ bank accounts ↔ URLs
- Detect scam networks (multiple entities connected through reports)
- Identify coordinated fake reporting (multiple users reporting same false targets)
- Graph database (Neo4j) or graph queries in PostgreSQL (recursive CTEs)

**Impact**: Uncovers scam rings, improves coordinated fraud detection.

---

### FD-03: Real-Time Threat Intelligence Feed
**Priority**: Medium | **Effort**: Medium

**Recommendation**:
- Ingest external threat feeds (PhishTank, URLHaus, abuse.ch)
- Cross-reference with community reports
- Auto-boost risk scores for externally confirmed threats
- Publish FraudShield's community data as a feed for partners

**Impact**: Broader threat coverage, faster detection of new campaigns.

---

### FD-04: Behavioral Analytics
**Priority**: Medium | **Effort**: High

**Recommendation**:
- Track user behavior patterns (normal login times, device, location)
- Detect anomalous behavior (new device, unusual location, rapid actions)
- Risk-based authentication (step-up auth for unusual logins)
- Scam victim behavior modeling (users who are targeted show distinct patterns)

**Impact**: Proactive protection before scam completion, reduced false positives.

---

### FD-05: Reporter Reputation Enhancement
**Priority**: High | **Effort**: Medium

**Current State**: Linear reputation from verification votes.

**Recommendation**:
- Time-decayed reputation (recent accuracy weighted higher)
- Cross-validation scoring (reporters whose reports are later verified by others)
- Negative reputation for false reports (admin-rejected)
- Sybil resistance (multiple accounts from same device/IP penalized)
- Trust tiers: New User → Contributor → Trusted → Expert

**Impact**: Higher quality community intelligence, reduced manipulation.

---

## 15.4 Infrastructure Improvements

### II-01: Container Orchestration (Kubernetes)
**Priority**: Medium | **Effort**: High

**Recommendation (when scaling beyond single server)**:
- Migrate from Docker Compose to Kubernetes (DigitalOcean Kubernetes or EKS)
- Auto-scaling based on CPU/memory/request metrics
- Rolling deployments with health check gates
- Self-healing (automatic container restart)
- Resource limits and quotas

---

### II-02: Observability Stack
**Priority**: High | **Effort**: Medium

**Recommendation**:
```
Metrics:  Prometheus → Grafana (dashboards, alerting)
Logs:     Winston → Loki → Grafana (unified log search)
Traces:   OpenTelemetry → Jaeger/Tempo (distributed tracing)
Errors:   Sentry (real-time error tracking)
```

**Impact**: Single pane of glass for all observability. Faster incident detection and resolution.

---

### II-03: Multi-Region Deployment
**Priority**: Low (future) | **Effort**: Very High

**Recommendation (when expanding beyond Malaysia)**:
- Deploy API in multiple regions (Singapore, Hong Kong, Australia)
- PostgreSQL with read replicas per region
- Redis Cluster with cross-region replication
- CDN for static assets
- Geographic DNS routing

---

### II-04: Staging Environment
**Priority**: High | **Effort**: Low

**Current State**: No staging environment. Changes go directly to production.

**Recommendation**:
- Mirror production infrastructure at smaller scale
- Anonymized production data copy for testing
- Deploy all changes to staging first
- Automated smoke tests against staging
- Minimum 24-hour soak time before production

---

## 15.5 Architecture Roadmap

### Phase 1 (Immediate — 0-3 months)
| Item | Priority | Effort |
|------|----------|--------|
| CI/CD pipeline (GitHub Actions) | Critical | Low |
| WAF deployment (Cloudflare) | Critical | Low |
| Error tracking (Sentry) | Critical | Low |
| Payment integration | Critical | Medium |
| Staging environment | High | Low |
| Response caching (Redis) | High | Low |
| Admin MFA | Critical | Medium |
| Input validation library (Zod) | High | Medium |

### Phase 2 (Near-term — 3-6 months)
| Item | Priority | Effort |
|------|----------|--------|
| Horizontal API scaling | High | Medium |
| Database read replica | High | Medium |
| Observability stack (Grafana) | High | Medium |
| Log aggregation (Loki) | High | Medium |
| Secret rotation | High | Medium |
| Comprehensive test coverage (80%) | High | High |
| Reporter reputation enhancement | High | Medium |
| iOS app release | High | High |

### Phase 3 (Medium-term — 6-12 months)
| Item | Priority | Effort |
|------|----------|--------|
| ML-based risk scoring | High | High |
| Event-driven architecture | Medium | High |
| Network graph analysis | Medium | High |
| Behavioral analytics | Medium | High |
| External threat feed integration | Medium | Medium |
| Feature flagging system | Medium | Medium |
| API versioning strategy | Medium | Medium |

### Phase 4 (Long-term — 12+ months)
| Item | Priority | Effort |
|------|----------|--------|
| Kubernetes migration | Medium | High |
| Multi-region deployment | Low | Very High |
| Real-time streaming (Kafka) | Medium | High |
| CQRS pattern | Low | High |
| Partner API (threat intelligence sharing) | Medium | Medium |
