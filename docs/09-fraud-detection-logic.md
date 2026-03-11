# 9. Fraud Detection Logic

## Document Information
| Field | Value |
|-------|-------|
| Product | FraudShield |
| Version | 1.1.0 |
| Date | 2026-03-11 |
| Classification | Internal — Confidential |

---

## 9.1 Risk Signals

### Signal Categories

#### Community Intelligence Signals
| Signal | Source | Weight | Description |
|--------|--------|--------|-------------|
| Report Count | ScamNumberCache / ScamUrlCache / ScamBankCache | 35% | Total number of community reports against target |
| Verification Ratio | Verification table | 30% | Percentage of verifiers agreeing target is scam |
| Reporter Reputation | Profile.reputation | 20% | Average reputation score of reporting users |
| Recency | Cache.lastReported | 15% | How recently the target was last reported |

#### External Intelligence Signals
| Signal | Source | Boost | Description |
|--------|--------|-------|-------------|
| SemakMule Match | BNM SemakMule API | Set 75-90 | Target found in official mule account database |
| Google Safe Browsing | Google Safe Browsing API | Set 90 | URL flagged by Google's threat intelligence |
| URL Heuristics | Internal analysis | Variable | Suspicious domain patterns, redirect chains, newly registered domains |

#### Behavioral Signals (Phase 2)
| Signal | Source | Description |
|--------|--------|-------------|
| Call Duration | CallStateService | Unusually long calls with unknown numbers |
| Call Pattern | Behavioral logging | Repeated calls from same area code cluster |
| Authority Claim | Voice analysis | Caller claims to be from bank/police/government |
| Urgency Pressure | Voice/message NLP | Language indicating immediate action required |
| Financial Request | Voice/message NLP | Request for money transfer, OTP, or credentials |

---

## 9.2 Fraud Scoring Logic

### RiskEvaluationService — Composite Scoring Algorithm

```
INPUTS:
  target: string          (phone number, URL, or bank account)
  type: string            (phone | url | bank)

STEP 1: Fetch Community Data
  cacheEntry = query ScamNumberCache/ScamUrlCache/ScamBankCache
  IF not found → return { score: 0, level: "low", found: false }

STEP 2: Calculate Component Scores

  communityScore = log(1 + reportCount) / log(1 + MAX_EXPECTED_REPORTS) × 100
    // Logarithmic curve: diminishing returns after many reports
    // 1 report ≈ 15, 5 reports ≈ 50, 20 reports ≈ 78, 100 reports ≈ 95

  verificationScore = (verifiedCount / totalVerifications) × 100
    // Simple ratio of confirming votes to total votes
    // 0 verifications → 0 (neutral, not penalized)

  reputationScore = avgReporterReputation / MAX_REPUTATION × 100
    // Normalized against max possible reputation
    // High-reputation reporters boost score

  recencyScore = exp(-daysSinceLastReport / DECAY_CONSTANT) × 100
    // Exponential decay: recent reports score higher
    // 0 days = 100, 7 days ≈ 50, 30 days ≈ 10

STEP 3: Weighted Combination
  baseScore = (0.35 × communityScore)
            + (0.30 × verificationScore)
            + (0.20 × reputationScore)
            + (0.15 × recencyScore)

STEP 4: External Intelligence Boosts
  IF semakMuleMatch:
    CASE "high_risk"   → score = max(score, 90)
    CASE "medium_risk" → score = max(score, 80)
    CASE "low_risk"    → score = max(score, 75)

  IF googleSafeBrowsingFlagged:
    score = max(score, 90)

  IF urlHeuristicsMatch:
    score = score + heuristicBoost  (capped at 100)

STEP 5: Classification
  IF score >= 75 → level = "critical"
  IF score >= 50 → level = "high"
  IF score >= 25 → level = "medium"
  ELSE           → level = "low"

OUTPUT:
  {
    score: 0-100,
    level: "low" | "medium" | "high" | "critical",
    reasons: string[],       // Human-readable explanations
    factors: {
      communityReports,
      verifiedReports,
      avgReporterReputation,
      recencyScore,
      verificationRatio,
      semakMuleFound
    },
    checkedAt: ISO timestamp
  }
```

---

## 9.3 Detection Workflows

### Workflow A: Phone Number Check
```
User Input (phone number)
    │
    ▼
[1] Format Validation
    │ → Validate Malaysian/international phone format
    │ → Normalize (remove spaces, dashes, country code)
    │
    ▼
[2] Local Cache Check
    │ → Query ScamNumberCache by normalized number
    │ → If found: proceed to scoring
    │ → If not found: check external
    │
    ▼
[3] External Intelligence
    │ → Query SemakMule API (if available)
    │ → Apply boost if match found
    │
    ▼
[4] Risk Scoring
    │ → Run RiskEvaluationService.evaluateRisk()
    │ → Generate composite score
    │
    ▼
[5] Logging
    │ → Create TransactionJournal entry
    │ → Record: checkType=PHONE, target, riskScore, status
    │
    ▼
[6] Response
    → Return score, level, reasons, factors
```

### Workflow B: URL/Link Analysis
```
User Input (URL)
    │
    ▼
[1] URL Validation & Normalization
    │ → Validate URL format
    │ → Extract domain, path, query parameters
    │
    ▼
[2] Redirect Chain Analysis
    │ → Follow HTTP redirects (max 10 hops)
    │ → Record each redirect URL
    │ → Identify final destination
    │
    ▼
[3] Heuristic Analysis
    │ → Check domain age (newly registered = suspicious)
    │ → Check for typosquatting (levenshtein distance to known brands)
    │ → Check for URL shorteners (bit.ly, tinyurl, etc.)
    │ → Check for suspicious TLDs (.xyz, .tk, .ml)
    │ → Check path patterns (/login, /verify, /secure)
    │ → Check for IP-based URLs
    │
    ▼
[4] External Intelligence
    │ → Google Safe Browsing API check
    │ → Community database check (ScamUrlCache)
    │
    ▼
[5] Risk Scoring
    │ → Combine heuristic score + external intelligence
    │ → Generate composite score
    │
    ▼
[6] Response
    → { riskScore, redirectChain, finalUrl, heuristics, safeBrowsingResult }
```

### Workflow C: QR Code Analysis (Quishing Detection)
```
Camera/Image Input
    │
    ▼
[1] QR Decode
    │ → Extract encoded data via mobile_scanner
    │ → Identify content type (URL, text, vCard, etc.)
    │
    ▼
[2] Content Classification
    │ → IF URL: proceed to URL analysis pipeline (Workflow B)
    │ → IF text: extract embedded URLs, phone numbers
    │ → IF vCard: extract phone numbers, URLs
    │
    ▼
[3] URL Analysis (if applicable)
    │ → Full redirect chain + heuristic analysis
    │
    ▼
[4] Risk Scoring
    │ → Apply QR-specific boosts:
    │   - Shortened URLs in QR = +15
    │   - Payment URLs in QR = +10
    │   - Unknown domains = +10
    │
    ▼
[5] Response
    → { extractedUrl, contentType, riskScore, analysis }
```

### Workflow D: Message Analysis (NLP)
```
User Input (SMS/chat message)
    │
    ▼
[1] Text Preprocessing
    │ → Language detection (EN/MS)
    │ → Normalize whitespace, encoding
    │
    ▼
[2] Entity Extraction
    │ → Phone numbers
    │ → URLs
    │ → Bank account numbers
    │ → Email addresses
    │
    ▼
[3] Pattern Detection
    │ → Urgency indicators ("immediately", "urgent", "deadline")
    │ → Authority impersonation ("bank", "police", "BNM", "LHDN")
    │ → Financial keywords ("transfer", "OTP", "PIN", "password")
    │ → Emotional manipulation ("help", "emergency", "family")
    │ → Prize/reward lures ("congratulations", "winner", "claim")
    │
    ▼
[4] Extracted Entity Lookup
    │ → Any URLs found → URL analysis pipeline
    │ → Any phone numbers → Phone number lookup
    │ → Any bank accounts → Bank account check
    │
    ▼
[5] Composite Risk Scoring
    │ → Pattern match count × weight
    │ → Entity risk scores (from lookups)
    │ → Language analysis confidence
    │
    ▼
[6] Response
    → { riskScore, patterns, extractedEntities, recommendation }
```

### Workflow E: Voice Scam Detection (Premium)
```
Audio Stream (during call)
    │
    ▼
[1] Audio Capture
    │ → Record via `record` package
    │ → Buffer audio for streaming analysis
    │
    ▼
[2] Transcription
    │ → Real-time speech-to-text
    │ → Display live transcription to user
    │
    ▼
[3] Real-Time Pattern Analysis
    │ → Authority claim detection
    │ → Urgency/pressure language
    │ → Financial information requests
    │ → Social engineering tactics
    │ → Macau scam pattern matching
    │
    ▼
[4] Live Risk Score
    │ → Updated in real-time on UI
    │ → Threshold alerts (>75 = warning overlay)
    │
    ▼
[5] Post-Call Analysis
    │ → Full transcript submission to backend
    │ → POST /features/analyze-voice
    │ → Comprehensive scoring with full context
    │
    ▼
[6] Safety Check
    → Post-call dialog: "Was this call safe?"
    → Option to report if suspicious
```

### Workflow F: Device Security Audit
```
User triggers scan
    │
    ▼
[1] App Enumeration
    │ → List all installed packages via native bridge
    │ → Get package names, versions, install dates
    │
    ▼
[2] Permission Analysis
    │ → Check dangerous permissions per app
    │ → Flag: SMS access, call log, overlay, accessibility
    │ → Compare against expected permissions for app category
    │
    ▼
[3] Signature Verification
    │ → Verify APK signatures against known publishers
    │ → Flag unsigned or self-signed apps
    │
    ▼
[4] Threat Database Match
    │ → Check package names against local threat DB
    │ → Query AppReputation table for community verdicts
    │ → Check against known malware signatures
    │
    ▼
[5] Network Analysis
    │ → Check for VPN configurations
    │ → Detect proxy settings
    │
    ▼
[6] Risk Scoring
    │ → Per-app risk score (0-100)
    │ → Overall device risk score (average + penalties)
    │
    ▼
[7] Results + Community Feedback
    → Display risky apps with actions (uninstall, settings, flag)
    → User verdicts update AppReputation table
```

---

## 9.4 Content Moderation Pipeline

```
User-Generated Content (report description, comment)
    │
    ▼
[1] PII Detection (Regex-based)
    │ → Malaysian IC: /\d{6}-\d{2}-\d{4}/
    │ → Email: standard email regex
    │ → Phone: Malaysian phone patterns
    │ → Address: street/postcode patterns
    │ → Postcode: /\d{5}/ in context
    │
    │ IF PII found → Block + return reasons
    │
    ▼
[2] AI Moderation (OpenAI API)
    │ → Submit text to moderation endpoint
    │ → Check categories: hate, violence, sexual, self-harm
    │ → Check political/divisive content (custom rules)
    │ → Check spam patterns
    │
    │ IF flagged → Block + return reasons
    │
    ▼
[3] Entity Extraction
    │ → Extract: phones, emails, URLs, bank accounts
    │ → Store in report.evidence._extractedEntities
    │ → Used for cache table population
    │
    ▼
[4] Content Passes
    → Proceed with report/comment creation
    → Moderation results stored in evidence._moderation
```

---

## 9.5 Cache Table Management

### ScamNumberCache / ScamUrlCache / ScamBankCache
These tables aggregate community intelligence for fast lookup:

```
On new report submission:
  1. Extract target entities from report
  2. For each entity:
     IF exists in cache:
       - Increment reportCount
       - Add new categories
       - Update lastReported
       - Recalculate riskScore
     ELSE:
       - Create new cache entry
       - Set initial reportCount = 1
       - Set initial riskScore based on first report

On verification vote:
  1. Recalculate verifiedCount for target
  2. Update verificationRatio
  3. Trigger riskScore recalculation

On admin status change (VERIFIED/REJECTED):
  1. If VERIFIED: boost cache entry riskScore
  2. If REJECTED: reduce cache entry riskScore
  3. Update metadata flags
```

### Offline Sync (Mobile)
```
Every 12 hours (Workmanager):
  1. Check network connectivity
  2. Check battery level (skip if low)
  3. GET /reports/scam-numbers/sync?since=lastSyncTimestamp
  4. Update local SQLite database
  5. Update lastSync timestamp
```
