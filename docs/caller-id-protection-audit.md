# Caller ID Protection Module - Production Readiness Audit

**Audit Date:** 2026-03-09
**Module:** Caller ID Protection (Phase 2)
**Platform:** Android (Flutter + Native Kotlin)
**Overall Score:** 5.8/10 - NOT production-ready

## Context

FraudShield's Caller ID Protection is a Phase 2 feature providing real-time scam call detection on Android. This audit evaluates whether the module is production-ready, secure, compliant, and effective at detecting scam calls. The system spans Flutter frontend services, native Kotlin code, and a Node.js/Express backend with Prisma + Redis.

---

## 1. Detection Capability

### What It Can Detect

| Threat Type | Supported | Mechanism |
|---|---|---|
| Known scam numbers | Yes | Community reports database (encrypted, indexed) |
| Robocalls | Partial | No dedicated robocall signature detection |
| Spoofed numbers | Yes | STIR/SHAKEN attestation (Android 11+) + neighbor spoofing algorithm |
| Reported scam callers | Yes | Community reports + admin-verified reports with weighted scoring |
| International scam calls | Partial | No country-code-specific risk boosting; relies on reports |
| Bank mule network numbers | Planned | PDRM Semak Mule API integration is **mocked** (not live) |

### Intelligence Sources

| Source | Status |
|---|---|
| Real-time cloud lookup | **Active** - `POST /api/v1/features/evaluate-risk` |
| Offline number database | **Not implemented** - no local DB fallback |
| Cloud scam intelligence API | **Mock only** - Semak Mule API awaiting data agreement |
| Community reports | **Active** - weighted scoring with verification |
| STIR/SHAKEN carrier attestation | **Active** - native Kotlin via MethodChannel (Android 11+) |

### Detection Gaps

1. **No offline database** - If internet is unavailable, only contact-book whitelist and neighbor spoofing heuristics work. No cached scam number DB.
2. **Semak Mule API is mocked** - The official Malaysian police scam database integration returns fake data. Numbers ending in "000"/"999" are hardcoded as blacklisted.
3. **No robocall detection** - No audio fingerprinting, no cadence analysis, no carrier-level robocall metadata.
4. **No third-party threat feeds** - No integration with global scam databases (Hiya, Truecaller API, GSMA, etc.).
5. **No number rotation tracking** - Scammers using sequential/rotating numbers won't be detected unless individually reported.

---

## 2. Real-Time Call Handling

### Workflow

```
Incoming Call -> phone_state package detects RINGING ->
  CallStateService._handleIncomingCall() ->
    Contact book check (if saved -> score 0, skip) ->
    Show loading overlay immediately ->
    Async: Backend risk evaluation + STIR/SHAKEN check ->
    Update overlay with risk score + reasons
```

### Latency Analysis

| Step | Estimated Latency | Notes |
|---|---|---|
| Phone state detection | ~50-100ms | Native broadcast receiver via `phone_state` package |
| Contact book lookup | ~20-50ms | `flutter_contacts` local query |
| Loading overlay display | ~100ms | Shown before network call |
| Backend risk API call | **300-800ms** | Network dependent; no caching |
| STIR/SHAKEN check | ~10ms | Local MethodChannel to native |
| **Total to first visual** | **~200ms** | Loading state shown quickly |
| **Total to risk score** | **~500-1000ms** | Backend response updates overlay |

**Verdict:** The progressive loading UX (show overlay immediately, update with data) effectively masks backend latency. However, the actual risk score display exceeds the 300ms target.

### Background Service Reliability

- **Foreground service** (`flutter_foreground_task`) with `stopWithTask: false` ensures survival after app kill
- **Service type:** `specialUse` - requires Google Play declaration justification
- **Auto-restart on boot:** Controlled via `SharedPreferences` flag, re-enabled in `main.dart`

### Failure Scenarios

| Scenario | Behavior | Severity |
|---|---|---|
| No internet | Only contact whitelist + neighbor spoofing work. Unknown numbers get default score 35 (medium). | **High** - most scam calls will be missed |
| Backend timeout (30s) | Global `requestTimeout` middleware. Overlay stays in loading state. | **Medium** - poor UX |
| Foreground service killed by OS | Android may kill service under memory pressure despite foreground status | **Medium** |
| Phone state event deduplication failure | Code handles duplicate events, but edge cases with rapid call cycling possible | **Low** |
| Redis down | Rate limiter fails open (allows requests). Risk scoring still works via Prisma. | **Low** |

### Key Issue: No Offline Fallback

The system has **no local scam number database**. When offline, the only protection is:
- Contact book whitelist (known numbers score 0)
- Neighbor spoofing detection (digit matching)
- Default "unknown" score of 35

**Recommendation:** Ship a periodic sync of top-reported scam numbers to a local SQLite database.

---

## 3. Telephony Integration

### Android Implementation

| Permission | Declared | Used | Play Store Risk |
|---|---|---|---|
| `READ_PHONE_STATE` | Yes | Yes - phone_state package | **Medium** - requires core functionality justification |
| `READ_CALL_LOG` | Yes | Yes - call monitoring | **High** - restricted permission, requires declaration form |
| `READ_PHONE_NUMBERS` | Yes | Yes - user phone number | **Medium** - requires justification |
| `SYSTEM_ALERT_WINDOW` | Yes | Yes - overlay display | **Low** - standard for caller ID apps |
| `FOREGROUND_SERVICE` | Yes | Yes - background monitoring | **Low** - standard |
| `RECORD_AUDIO` | Yes | Yes - voice analysis (premium) | **Medium** - requires clear user consent |

### Play Store Policy Risks

**Critical: `READ_CALL_LOG` is a restricted permission.**
- Google requires apps to be registered as "default dialer" or "default SMS handler" to use `READ_CALL_LOG`
- Alternatively, must submit a **Permissions Declaration Form** with video demonstration
- **FraudShield does NOT register as default dialer** - relies on `CALL_SCREENING_SERVICE` approach
- **Risk:** App could be rejected or removed if declaration is insufficient

**`FOREGROUND_SERVICE` with `specialUse` type:**
- Google requires justification for `specialUse` foreground service type
- Must explain why standard types (phone, mediaPlayback, etc.) are insufficient
- **Recommendation:** Consider using `foregroundServiceType="phoneCall"` instead if applicable

**No `CALL_SCREENING_SERVICE` integration:**
- The app uses `phone_state` package (broadcast receiver) instead of the modern `CallScreeningService` API
- `CallScreeningService` is the Google-recommended approach for call screening apps
- Provides: incoming call notification without `READ_CALL_LOG`, ability to reject/silence calls, better OS integration
- **Recommendation:** Migrate to `CallScreeningService` for Android 10+ to reduce permission burden

### iOS Implementation

**Status: NOT IMPLEMENTED**

| Component | Status |
|---|---|
| CallKit framework | Not integrated |
| Call Directory Extension | Not created |
| VoIP push notifications | Not configured |
| Info.plist permissions | Missing call-related keys |

**Impact:** The entire Caller ID feature is Android-only. iOS users get zero call protection.

**Required for iOS:**
1. `CallKit CXCallDirectoryProvider` extension for spam identification
2. Local phone number database (CallKit requires offline DB, no real-time API calls during lookup)
3. Background refresh to sync scam database
4. App Extension lifecycle management

---

## 4. Scam Intelligence Integration

### Current Intelligence Sources

| Source | Status | Weight in Scoring |
|---|---|---|
| Community reports | **Active** | 35% (community score) |
| Report verification | **Active** | 30% (verification ratio) |
| Reporter reputation | **Active** | 20% |
| Report recency | **Active** | 15% |
| PDRM Semak Mule | **Mocked** | Override: min score 75/90 when active |
| STIR/SHAKEN | **Active** (Android 11+) | +/-20-30 score adjustment |

### Scoring Algorithm

```
rawScore = communityScore(log2 curve) * 0.35
         + verificationRatio * 0.30
         + reputationScore * 0.20
         + recencyScore * 0.15

If semakMule.found: rawScore = max(rawScore, 75)
If semakMule.riskLevel == 'high': rawScore = max(rawScore, 90)
```

### Database Freshness

- Reports submitted in real-time by users
- Admin moderation required before reports go public (`PENDING` -> `VERIFIED`)
- **No automatic expiry** of old reports (stale data risk)
- **No batch import** capability for external threat feeds
- Trending alert analysis runs hourly (Bull queue cron)

### Gaps

1. **No third-party threat intelligence feeds** (Hiya, Truecaller, GSMA Fraud Intelligence)
2. **No telecom carrier integration** (CNAM lookup, carrier-reported spam)
3. **No ML model** - rule-based only; code comments acknowledge this: "This is the formula that ML will eventually replace"
4. **No report expiry/decay** - A number reported 2 years ago has same weight as recent if recency component is low
5. **Manual moderation bottleneck** - Reports stay `PENDING` until admin reviews; delays intelligence availability

---

## 5. User Experience During Incoming Call

### Overlay Behavior

**Dual-mode overlay system:**
1. **In-app overlay** (app in foreground) - `CallerRiskOverlay` widget
2. **System overlay** (app in background/phone dialer active) - `flutter_overlay_window`

### Visual Design Assessment

| Element | Implementation | Quality |
|---|---|---|
| Risk score display | Progress bar 0-100, color-coded | Good |
| Color coding | Red (critical 80+), Orange (high 55+), Yellow (medium 30+), Green (low) | Good |
| Pulsing animation | Red ring animation for high-risk | Good |
| Category tags | "Fake Bank Officer", "Government Agency", etc. | Good |
| Community reports badge | "Reported 52 times" with report count | Good |
| Scam script preview | Contextual warnings per scam type | Excellent |
| Frosted glass background | `BackdropFilter` with blur | Good |

### Available Actions

| Action | Available | Notes |
|---|---|---|
| View warning | Yes | Automatic overlay display |
| Record & Analyze | Yes | Premium feature, launches voice detection |
| Report Scam | Yes | Navigates to report form |
| How to Block | Yes | Shows step-by-step blocking instructions |
| Dismiss | Yes | With friction dialog for high/critical risk |
| Block call directly | **No** | Cannot programmatically block - only shows instructions |
| Mark as safe / whitelist | **No** | No way to whitelist from overlay |

### Lock Screen Behavior

- System overlay (`SYSTEM_ALERT_WINDOW`) displays over lock screen
- Foreground service notification persists
- **Limitation:** Some Android OEMs (Xiaomi, Huawei, OPPO) may block system overlays or kill foreground services aggressively

### Post-Call Safety Check

- Triggers automatically after calls with risk score >= 55
- Asks: "Did the previous caller ask you to transfer money or provide your OTP/password?"
- Options: "No, I'm Safe" / "Yes, Report"
- **Excellent behavioral intervention design**

### Cool-Down Banner

- 10-minute countdown after critical-risk calls
- Message: "Do not make any transfers. Scam calls often create false urgency!"
- **Excellent Macau scam countermeasure**

### UX Gaps

1. **No direct call blocking** from overlay - user must follow manual instructions
2. **No whitelist/safe-mark** from overlay - cannot quickly mark a false positive
3. **No call history integration** - doesn't show past risk assessments for same number
4. **No auto-answer prevention** - cannot intercept auto-answer accessories

---

## 6. False Positive Risk

### Current Safeguards

| Mechanism | Implementation | Effectiveness |
|---|---|---|
| Contact book whitelist | Saved contacts score 0 automatically | **Good** - prevents most false positives for known callers |
| STIR/SHAKEN passed | Score reduced by 20 points | **Good** - carrier-verified calls get lower risk |
| Low community reports | Logarithmic curve means 1 report = score ~10 | **Moderate** - single malicious report has limited impact |
| Admin moderation | Reports must be verified before public | **Good** - prevents mass false reporting |
| Reporter reputation | Low-rep users' reports weighted less | **Moderate** |

### False Positive Risks

1. **No user whitelist capability** - Users cannot manually whitelist numbers not in contacts (e.g., doctor's office, delivery drivers)
2. **No business number database** - Legitimate businesses with new numbers may trigger unknown (score 35)
3. **Default unknown score of 35 (medium)** - All unknown numbers show as "medium" risk, which may cause alarm fatigue
4. **No feedback loop** - Users cannot report false positives to improve scoring
5. **Neighbor spoofing false positives** - Legitimate local businesses sharing area code prefix could trigger neighbor spoofing detection (5-digit match = score 20)

### Recommendations

1. Add user-managed whitelist with persistent storage
2. Reduce default unknown score from 35 to 15-20 (low) to reduce alarm fatigue
3. Add "Mark as Safe" action in overlay that suppresses future alerts for that number
4. Implement false positive reporting mechanism
5. Consider integrating a business number database

---

## 7. Privacy & Data Protection

### Data Handling Assessment

| Data Point | Storage | Protection | Compliance |
|---|---|---|---|
| Scam phone numbers | PostgreSQL | **Deterministic encryption** | Good |
| User phone number | User profile DB | Standard DB encryption | Adequate |
| Call signals (Macau detection) | Redis (1hr TTL) | Phone number stored as `'HIDDEN'` | **Excellent** |
| Audio recordings | Temp files, uploaded to backend | Deleted after analysis | Adequate |
| Contact book data | Local only | Not transmitted to server | Good |
| Call logs | Accessed locally | Not stored on server | Good |

### GDPR/PDPA Compliance

| Requirement | Status |
|---|---|
| Data minimization | **Good** - call signals don't include phone numbers |
| Purpose limitation | **Good** - data used only for scam detection |
| Storage limitation | **Partial** - scam reports have no auto-expiry (`deletedAt` exists but no auto-delete) |
| Right to erasure | **Partial** - `deletedAt` soft-delete exists but no self-service deletion |
| Consent for recording | **Yes** - explicit user action required for recording |
| Data encryption | **Yes** - deterministic encryption for phone numbers |
| Cross-border transfers | **Unknown** - depends on server location |

### Privacy Risks

1. **Deterministic encryption weakness** - Same number always produces same ciphertext, enabling frequency analysis
2. **No data retention policy enforced** - Reports and transaction journals stored indefinitely
3. **Audio uploads** - Voice recordings transmitted to server for analysis; retention period unclear
4. **`READ_CALL_LOG` permission** - Access to full call history is a significant privacy surface
5. **No privacy dashboard** - Users cannot view/export/delete their data

---

## 8. Performance & Battery Usage

### Background Service Impact

| Component | CPU Impact | Memory | Battery | Network |
|---|---|---|---|---|
| Foreground service | Low (idle listener) | ~15-30MB | **Medium** - persistent service | None when idle |
| Phone state monitoring | Negligible (broadcast receiver) | Minimal | Low | None |
| System overlay | Low (only during calls) | ~5-10MB during calls | Low | None |
| Risk API call | Brief spike per call | Minimal | Low per call | ~1-5KB per request |
| Contact book lookup | Brief spike per call | Depends on contact count | Negligible | None |

### Battery Concerns

1. **Foreground service persistent notification** - Standard for caller ID apps; users expect this
2. **No wake lock abuse** - Service uses broadcast receiver, not polling
3. **No periodic network requests** - Only triggers on incoming calls
4. **Redis-backed rate limiting** - Prevents excessive API calls (20/hour max)

### Optimizations Needed

1. **Add phone number risk cache** - Redis TTL cache (5-10 min) for recently checked numbers to avoid repeated backend calls for the same number
2. **Batch contact sync optimization** - Large contact books could cause latency on first lookup
3. **Overlay rendering** - `BackdropFilter` with blur is GPU-intensive; consider simpler overlay for low-end devices
4. **No connection pooling configuration** visible for backend HTTP client

**Overall:** Battery impact is **acceptable** for a security app. The event-driven architecture (broadcast receiver, not polling) is the correct approach.

---

## 9. Security Risks

### Vulnerability Assessment

| Vulnerability | Risk Level | Current Mitigation | Recommendation |
|---|---|---|---|
| Attacker bypassing detection (new numbers) | **High** | Community reports only | Add third-party threat feeds, ML pattern detection |
| Number spoofing limitations | **Medium** | STIR/SHAKEN (Android 11+ only) | Document limitation; carrier adoption varies |
| Scam numbers rotating frequently | **High** | Individual number tracking only | Add prefix/range-based risk scoring |
| Exploiting whitelist (compromised contacts) | **Low** | Contact book = auto score 0 | Add option to scan even saved contacts |
| Report flooding/manipulation | **Low** | Admin moderation + rate limiting (5/10min) + reputation gating | Consider automated anomaly detection |
| API replay attack | **Low** | Anti-replay middleware (nonce + timestamp) | Adequate |
| Man-in-middle on risk API | **Low** | Certificate pinning in Flutter app | Adequate |
| Malicious overlay spoofing | **Low** | App signature verification | Adequate |
| Deterministic encryption cracking | **Medium** | Standard algorithm | Consider adding salt per-user |

### Critical Security Gaps

1. **No Call Screening Service integration** - Cannot programmatically block/reject calls, only warn
2. **STIR/SHAKEN limited to Android 11+** - Older devices get no carrier attestation
3. **No VPN/proxy detection** - Backend doesn't validate client network integrity
4. **Simulation method (`simulateRinging`) accessible** - Should be stripped from production builds
5. **Mock Semak Mule API** - Hardcoded patterns ("000"/"999") could be exploited if exposed

---

## 10. Production Readiness Score

| Category | Score (1-10) | Justification |
|---|---|---|
| **Detection Capability** | **5/10** | Community reports active, but no offline DB, no third-party feeds, Semak Mule mocked |
| **Real-Time Performance** | **7/10** | Progressive loading UX is excellent; backend latency acceptable; no offline fallback |
| **Security** | **6/10** | Anti-replay, cert pinning, encryption present; STIR/SHAKEN limited; no call blocking |
| **Compliance** | **5/10** | `READ_CALL_LOG` restricted permission risk; no iOS; no data retention policy; privacy gaps |
| **User Experience** | **8/10** | Overlay design excellent; post-call check innovative; missing whitelist and direct blocking |
| **Scam Intelligence** | **4/10** | Community-only intelligence; no ML; no external feeds; mock official API |

### **Overall Score: 5.8/10**

---

## Findings Summary

### Critical Weaknesses (Must Fix Before Production)

1. **PDRM Semak Mule API is mocked** - Core intelligence source returns fake data. Production deployment without real API means missing the most authoritative scam database in Malaysia.
2. **`READ_CALL_LOG` Play Store compliance** - This restricted permission requires a declaration form and may cause app rejection. Migrate to `CallScreeningService` API.
3. **No offline fallback** - Zero protection when internet is unavailable. Ship a synced local scam number database.
4. **No iOS implementation** - Half of potential users have zero protection. At minimum, implement CallKit Call Directory Extension.
5. **`simulateRinging()` in production code** - Debug method should be behind a debug flag or removed entirely.

### Medium Improvements (Should Fix)

1. **Add Redis caching for phone number risk scores** (5-10 min TTL) to reduce backend load and latency
2. **Implement user whitelist** - Allow users to mark numbers as safe from the overlay
3. **Add "Mark as Safe" / false positive reporting** in the overlay UI
4. **Reduce default unknown number score** from 35 to ~15-20 to reduce alarm fatigue
5. **Add data retention policy** - Auto-expire old reports and transaction journals
6. **Implement `CallScreeningService`** for Android 10+ (reduces permission requirements, enables call rejection)
7. **Add foreground service type justification** documentation for Play Store review
8. **Strip debug methods** from release builds

### Optional Enhancements (Nice to Have)

1. **Third-party threat intelligence** - Integrate Hiya, Truecaller, or GSMA feeds
2. **ML-based risk scoring** - Replace rule-based weights with trained model
3. **Number range/prefix risk scoring** - Detect rotating scam number patterns
4. **Business number database** - Reduce false positives for legitimate businesses
5. **Privacy dashboard** - Let users view, export, and delete their data
6. **OEM-specific optimizations** - Handle Xiaomi/Huawei/OPPO battery optimization settings
7. **Call blocking integration** - Programmatic call rejection via `CallScreeningService`
8. **Audio analysis improvements** - Real-time transcription during calls (not just post-recording)

---

## Production Readiness Verdict

**NOT READY for production deployment in current state.**

The Caller ID Protection module has an **excellent UX and architectural foundation** but has critical gaps that prevent safe production deployment:

1. The primary intelligence source (Semak Mule) is fake/mocked
2. Google Play compliance risk with `READ_CALL_LOG` restricted permission
3. Zero protection when offline (common scenario for users)
4. No iOS support at all
5. Debug simulation code present in production

### Recommended Path to Production

1. **Phase 1 (2-4 weeks):** Fix Play Store compliance (`CallScreeningService` migration), remove debug code, add offline DB
2. **Phase 2 (4-8 weeks):** Integrate real Semak Mule API, add user whitelist, implement Redis caching
3. **Phase 3 (8-16 weeks):** iOS CallKit implementation, third-party threat feeds, ML scoring
4. **Phase 4 (ongoing):** OEM-specific testing, privacy dashboard, advanced detection

The module can be deployed as a **beta/preview feature** with clear disclaimers, but should not be marketed as production-grade anti-scam protection until at least Phase 1 and Phase 2 are complete.

---

## Key Files Audited

| File | Description |
|---|---|
| `fraudshield/lib/services/call_state_service.dart` | Core call monitoring orchestrator |
| `fraudshield/lib/services/risk_evaluator.dart` | Frontend risk scoring engine |
| `fraudshield/lib/widgets/caller_risk_overlay.dart` | Overlay UI (720 lines) |
| `fraudshield/lib/widgets/post_call_safety_check.dart` | Post-call intervention |
| `fraudshield/lib/widgets/cooldown_banner.dart` | Cool-down timer |
| `fraudshield/lib/services/notification_service.dart` | Overlay state management |
| `fraudshield/android/.../MainActivity.kt` | STIR/SHAKEN native integration |
| `fraudshield/android/.../AndroidManifest.xml` | Permissions declarations |
| `fraudshield-backend/src/services/risk-evaluation.service.ts` | Backend scoring engine |
| `fraudshield-backend/src/controllers/risk-evaluation.controller.ts` | Risk API endpoint |
| `fraudshield-backend/src/services/semak-mule.service.ts` | Mock police API |
| `fraudshield-backend/src/controllers/voice-signal.controller.ts` | Call signal tracking |
| `fraudshield-backend/src/services/macau-scam.service.ts` | Macau scam detection |
| `fraudshield-backend/src/services/nlp-message.service.ts` | NLP scam pattern matching |
| `fraudshield-backend/src/services/alert-engine.service.ts` | Alert dispatch |
| `fraudshield-backend/src/services/alert-worker.service.ts` | Background job processing |
| `fraudshield-backend/src/middleware/rateLimiter.ts` | Rate limiting |
| `fraudshield-backend/prisma/schema.prisma` | Database schema |
| `fraudshield/lib/screens/account_screen.dart` | Settings toggle |
| `fraudshield/lib/main.dart` | App entry point, overlay entry point |
