# 13. Testing Strategy

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 13.1 Unit Testing

### Backend (Jest + ts-jest)

#### Configuration
```json
{
  "preset": "ts-jest",
  "testEnvironment": "node",
  "roots": ["<rootDir>/tests"],
  "testMatch": ["**/*.test.ts"],
  "runInBand": true
}
```

#### Test Suite Inventory
| Test File | Coverage Area | Key Tests |
|-----------|--------------|-----------|
| `auth.controller.test.ts` | Authentication endpoints | Signup validation, login flow, token generation, OTP verification |
| `email.service.test.ts` | Email delivery | OTP generation, SMTP delivery, template rendering |
| `health-score.service.test.ts` | Security health calculation | Score components, factor weighting, edge cases |
| `quishing.service.test.ts` | QR code analysis | URL extraction, redirect chain, risk scoring |
| `voice-scan.service.test.ts` | Voice analysis | Audio processing, pattern detection, scoring |
| `nlp-message.service.test.ts` | Message analysis | Entity extraction, pattern matching, language detection |
| `voice-signal.controller.test.ts` | Call signal reporting | Signal logging, metadata validation |
| `security_hardening.test.ts` | Security controls | Anti-replay, rate limiting, header validation |
| `report-rate-limit.test.ts` | Rate limit enforcement | Report submission limits, cooldown verification |

#### Integration Tests
| Test File | Coverage Area | Key Tests |
|-----------|--------------|-----------|
| `integration/admin.management.test.ts` | Admin workflows | User management, report moderation, status updates |

#### Running Tests
```bash
# All tests (sequential to avoid DB conflicts)
npm test

# Specific file
npx jest tests/auth.controller.test.ts

# Pattern matching
npx jest --testNamePattern="should validate JWT token"

# Watch mode
npm run test:watch

# Coverage report
npm run test:coverage
```

#### Mocking Strategy
| Dependency | Mock Method | Purpose |
|-----------|------------|---------|
| Prisma Client | Jest mock module | Database operations without real DB |
| Redis | In-memory mock | Rate limiting, OTP, nonce testing |
| External APIs | Jest spy/mock | OpenAI, Google, Firebase calls |
| SMTP | Mock transport | Email delivery verification |

### Flutter (Widget + Unit Tests)

#### Test Location
```
fraudshield/test/
├── widget_test.dart           # Basic widget rendering tests
├── services/                  # Service unit tests
├── screens/                   # Screen widget tests
└── utils/                     # Utility function tests
```

#### Running Flutter Tests
```bash
cd fraudshield
flutter test                   # All tests
flutter test test/widget_test.dart  # Specific file
flutter test --coverage        # With coverage report
```

---

## 13.2 Integration Testing

### Backend Integration Tests

#### Database Integration
| Scenario | Test Method |
|----------|------------|
| Report submission → cache update | End-to-end with test database |
| User registration → profile creation | Transaction verification |
| Verification vote → risk recalculation | Score accuracy validation |
| Account deletion → data anonymization | Data integrity check |

#### API Integration Patterns
```
[Test Client] → POST /auth/signup → Verify user created
[Test Client] → POST /auth/login → Receive tokens
[Test Client] → POST /reports (with token) → Verify report + cache
[Test Client] → POST /reports/verify → Verify score update
[Test Client] → GET /reports/lookup → Verify risk calculation
```

#### Middleware Integration
| Test | Validates |
|------|----------|
| Request without auth header → 401 | Authentication enforcement |
| Request with expired token → 401 | Token expiry handling |
| Request with revoked token → 401 | Token blocklist checking |
| Request without nonce → Varies | Anti-replay enforcement |
| Rapid requests → 429 | Rate limiter activation |
| Admin route as user → 403 | Role enforcement |

### Cross-Component Tests
| Scenario | Components | Validation |
|----------|-----------|------------|
| Report → Alert → Push | ReportController → AlertEngine → FCM | Alert delivered |
| Lookup → Risk → Journal | LookupController → RiskService → TransactionJournal | Score accuracy |
| Scan → Points → Badge | ScanController → GamificationService → Profile | Points awarded |
| Admin Action → Audit | AdminController → AuditService → AuditLog | Log created |

---

## 13.3 Security Testing

### Automated Security Checks

#### OWASP Top 10 Coverage
| Vulnerability | Test | Status |
|--------------|------|--------|
| **A01: Broken Access Control** | Admin endpoint without admin role → 403 | `security_hardening.test.ts` |
| **A02: Cryptographic Failures** | PII encrypted at rest verification | Manual |
| **A03: Injection** | SQL injection via Prisma parameterization | Framework-protected |
| **A04: Insecure Design** | Rate limiting prevents abuse | `report-rate-limit.test.ts` |
| **A05: Security Misconfiguration** | Helmet headers present | `security_hardening.test.ts` |
| **A06: Vulnerable Components** | `npm audit` check | Manual |
| **A07: Auth Failures** | Brute force protection, token management | `auth.controller.test.ts` |
| **A08: Data Integrity** | Anti-replay nonce validation | `security_hardening.test.ts` |
| **A09: Logging Failures** | Correlation ID tracing verified | Manual |
| **A10: SSRF** | URL checker redirect depth limit | Implemented |

#### Security-Specific Test Cases
| Test Case | Expected Result |
|-----------|----------------|
| Login with wrong password (11 times) | Rate limited after 10 attempts |
| Submit report with IC number in text | Blocked by PII detection |
| Replay request with same nonce | Rejected (409 or 400) |
| Request with timestamp >5 min old | Rejected |
| Access profile with revoked token | 401 Unauthorized |
| Admin action logged in AuditLog | Record created with all fields |
| Encrypted field decrypts correctly | Round-trip encryption test |
| Certificate pinning bypass attempt | Connection rejected |

### Penetration Testing Checklist
| Area | Test | Method |
|------|------|--------|
| Authentication | Credential stuffing | Automated tool |
| API | Endpoint fuzzing | OWASP ZAP |
| Network | MITM attack simulation | Burp Suite |
| Mobile | APK reverse engineering | JADX/Frida |
| Database | SQL injection attempts | SQLMap |
| Rate Limits | Distributed bypass | Multi-IP tool |
| Encryption | Key extraction attempt | Memory analysis |

---

## 13.4 Test Coverage Goals

### Backend Coverage Targets
| Category | Current | Target |
|----------|---------|--------|
| Controllers | ~40% | 80% |
| Services | ~50% | 85% |
| Middleware | ~60% | 90% |
| Utils | ~30% | 80% |
| Overall | ~45% | 80% |

### Critical Paths (Must have >90% coverage)
1. Authentication flow (signup → verify → login → refresh → logout)
2. Report submission pipeline (moderation → creation → cache update)
3. Risk evaluation scoring algorithm
4. Token management (generation → validation → revocation)
5. Anti-replay middleware
6. Rate limiting enforcement
7. Account deletion / anonymization
8. Content moderation pipeline

### Mobile Coverage Targets
| Category | Target |
|----------|--------|
| Services | 70% |
| Providers | 80% |
| Models | 90% |
| Utils | 80% |
| Widget (key screens) | 50% |

---

## 13.5 Test Environments

| Environment | Purpose | Database | Redis |
|------------|---------|----------|-------|
| Local | Developer testing | Docker PostgreSQL | Docker Redis |
| CI | Automated pipeline | Ephemeral Docker | Ephemeral Docker |
| Staging | Pre-production validation | Staging DB (anonymized) | Staging Redis |
| Production | Smoke tests only | Production DB (read-only) | Production Redis |

---

## 13.6 Test Data Management

### Seed Data
```bash
# Admin seed (development)
npx prisma db seed

# Alert seed (development)
GET /alerts/seed

# Reward seed (development)
POST /rewards/seed
```

### Test Data Principles
1. **Isolation**: Each test creates and cleans its own data
2. **Determinism**: No dependency on external state
3. **No PII**: Test data uses synthetic/fake information
4. **Idempotency**: Tests can be run repeatedly without side effects

---

## 13.7 Quality Gates

### Pre-Commit
- [ ] TypeScript compilation passes (`tsc --noEmit`)
- [ ] ESLint passes (`npm run lint`)
- [ ] Flutter analyze passes (`flutter analyze`)

### Pre-Merge
- [ ] All unit tests pass
- [ ] No new security vulnerabilities (`npm audit`)
- [ ] Code review completed
- [ ] Integration tests pass

### Pre-Deploy
- [ ] Full test suite passes
- [ ] Staging environment smoke test
- [ ] Database migration tested
- [ ] Health endpoints responding
- [ ] Rollback plan documented
