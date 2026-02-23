# FraudShield — Transaction Risk Alerts: Implementation Spec

> **Created:** 22 Feb 2026
> **Scope:** Tiers 1–3 (no bank API partnerships required)

---

## Feature Overview

Transaction Risk Alerts protects users at the **moment of payment** — the critical window when they're about to transfer money to a potential scammer. This feature leverages FraudShield's existing community scam database, the Fraud Check infrastructure, and new backend endpoints to provide real, useful pre-transaction checks.

### What This Is NOT
- ❌ Automatic bank transaction monitoring (requires bank API / Open Banking)
- ❌ Real-time SMS parsing (Tier 4 — future phase)
- ❌ Credit card fraud detection (different problem domain)

### What This IS
- ✅ "Check Before You Pay" — verify recipients before sending money
- ✅ Community-powered risk intelligence on bank accounts, DuitNow IDs, merchants
- ✅ Proactive scam alerts based on trending report patterns
- ✅ Personal transaction journal for tracking and converting to reports

---

## Tier 1: Pre-Transaction Check (Est. ~8 hrs)
*"Is this person safe to pay?"*

### Concept
Before sending money via DuitNow, bank transfer, or e-wallet, users check the recipient against FraudShield's community database. This is an extension of the existing Fraud Check screen with a dedicated "Payment Safety" flow.

### Backend Changes

#### [NEW] `GET /api/reports/lookup`
A dedicated lookup endpoint optimized for pre-transaction checks. Unlike `searchReports` (which returns paginated feed data), this returns a focused risk assessment.

```typescript
// Request
GET /api/reports/lookup?type=bank_account&value=1234567890
GET /api/reports/lookup?type=phone&value=60123456789
GET /api/reports/lookup?type=merchant&value=ShopeeStore123

// Response
{
  "found": true,
  "riskLevel": "high" | "medium" | "low" | "unknown",
  "communityReports": 3,         // Number of matching ScamReports
  "verifiedReports": 2,          // Reports with ≥2 verifications
  "categories": ["e-commerce", "investment"],  // Report categories
  "lastReported": "2026-02-15T...",            // Most recent report date
  "sources": ["community"],                     // Data source transparency
  "recommendation": "This bank account has been reported 3 times for e-commerce fraud. Proceed with extreme caution."
}
```

**Implementation:**
- Query `ScamReport` table WHERE `target` CONTAINS the input value (case-insensitive)
- Filter by `type` to narrow results (phone → phone reports, bank → bank account reports)
- Count verifications to weight trust level
- Generate recommendation text based on report count + verification count + recency

#### [MODIFY] `ScamReport` model
Add a new field to categorize the target type:

```prisma
model ScamReport {
  // ... existing fields ...
  targetType  String?     // "phone" | "bank_account" | "url" | "merchant" | "duitnow"
}
```

This allows the lookup endpoint to filter by target type for more accurate results.

### Flutter Changes

#### [MODIFY] `fraud_check_screen.dart`
**Option A — Add "Payment" tab** (recommended): Add a 5th tab alongside Phone/URL/Bank/Doc:

```dart
_TabItem(
  label: 'Payment',
  icon: Icons.payment_rounded,
  hint: 'Bank acc, phone, or merchant name',
  type: 'Payment',
),
```

**Option B — Dedicated screen**: Create a standalone `check_before_pay_screen.dart` with a more guided UX:
1. "Who are you paying?" → input field
2. "How?" → dropdown: DuitNow / Bank Transfer / E-wallet
3. "Amount?" → optional, for risk context
4. → Result with community reports + risk level

#### [MODIFY] `risk_evaluator.dart`
Add a new async method `evaluatePayment()` that calls the `/api/reports/lookup` endpoint:

```dart
static Future<RiskResult> evaluatePayment({
  required String value,
  required String paymentMethod, // "bank_transfer" | "duitnow" | "ewallet"
}) async {
  // 1. Call /api/reports/lookup
  // 2. Merge with local heuristic check
  // 3. Return combined RiskResult with sources
}
```

#### [MODIFY] `CheckResultScreen`
Enhance the result screen for payment checks:
- Show "X community reports found" badge
- Display report categories (what type of scam)
- Add "Report This Account" quick action
- Add "Call Bank" / "Call Police" emergency CTA for high-risk results

### UX Flow

```
┌──────────────────────────────────┐
│  🛡️ Check Before You Pay        │
│                                  │
│  [Enter bank account / phone]    │
│  [DuitNow ▾] [Bank Transfer ▾]  │
│                                  │
│  ┌────────────────────────────┐  │
│  │ 🔍 Check Now               │  │
│  └────────────────────────────┘  │
│                                  │
└──────────────────────────────────┘
              ↓
┌──────────────────────────────────┐
│  ⚠️ Caution                      │
│  This account has been reported  │
│  3 times for e-commerce fraud    │
│                                  │
│  📊 Community Reports: 3         │
│  ✅ Verified: 2                   │
│  🕐 Last report: 2 days ago     │
│                                  │
│  Sources:                        │
│  • FraudShield Community DB      │
│                                  │
│  [🚨 Report This Account]       │
│  [📞 Call Bank]  [🚔 Call PDRM] │
└──────────────────────────────────┘
```

---

## Tier 2: Smart Scam Alerts (Est. ~10 hrs)
*"What scams are trending near you?"*

### Concept
Proactive push notifications and in-app alerts based on patterns in community reports. This transforms FraudShield from a reactive checking tool to a proactive warning system.

> **Dependency:** Requires Firebase Cloud Messaging (FCM) setup from Phase 5 of the roadmap.

### Backend Changes

#### [NEW] `GET /api/alerts/trending`
Aggregates recent report data to surface trending scam patterns:

```typescript
// Response
{
  "trending": [
    {
      "category": "e-commerce",
      "title": "Shopee COD scam surge",
      "description": "12 reports in the last 24 hours targeting Shopee sellers",
      "reportCount": 12,
      "timeframe": "24h",
      "affectedArea": "Klang Valley",
      "severity": "high"
    }
  ],
  "nearYou": [
    {
      "reportCount": 5,
      "radius": "10km",
      "topCategory": "phone_scam",
      "message": "5 phone scam reports near your area this week"
    }
  ]
}
```

**Implementation:**
- Aggregate `ScamReport` by `category` with time windows (24h, 7d, 30d)
- Detect spikes: if report count in the last 24h > 2× the 7-day average, flag as trending
- For area-based alerts: use `latitude`/`longitude` with a radius query (PostGIS or Haversine formula)
- Cache results in Redis (5-minute TTL) to avoid repeated aggregation

#### [NEW] `POST /api/alerts/subscribe`
Users subscribe to alert categories and area-based notifications:

```typescript
// Request
{
  "categories": ["e-commerce", "investment", "phone_scam"],
  "locationEnabled": true,
  "latitude": 3.1390,
  "longitude": 101.6869,
  "radiusKm": 15
}
```

#### [NEW] Prisma model: `AlertSubscription`

```prisma
model AlertSubscription {
  id          String   @id @default(uuid())
  userId      String   @unique
  categories  String[] // Subscribed scam categories
  latitude    Float?
  longitude   Float?
  radiusKm    Int      @default(15)
  fcmToken    String?  // Firebase Cloud Messaging token
  isActive    Boolean  @default(true)
  createdAt   DateTime @default(now())
  updatedAt   DateTime @updatedAt
  user        User     @relation(fields: [userId], references: [id])
}
```

#### [NEW] `alert-engine.service.ts`
Background job (runs via Bull/Redis queue) that:
1. Every hour, checks for trending patterns
2. Matches against user subscriptions
3. Sends FCM push notifications to matching users
4. Logs sent alerts to prevent duplicates

### Flutter Changes

#### [NEW] `scam_alerts_screen.dart`
Dedicated screen showing:
- **Trending scam alerts** — cards with category, report count, area
- **Near you** — map-based view of recent reports (reuse `scam_map_screen.dart` data)
- **Alert preferences** — toggle categories, set location radius

#### [NEW] `alert_preferences_screen.dart`
Settings for:
- Category subscriptions (checkboxes)
- Location-based alerts toggle
- Alert radius slider (5km – 50km)
- Quiet hours setting

#### [MODIFY] `home_screen.dart`
Add a "Trending Alerts" card to the home tab:
- Shows top 1-2 trending scam alerts
- Tappable → navigates to `scam_alerts_screen.dart`
- Animated indicator when new alerts arrive

---

## Tier 3: Transaction Journal (Est. ~8 hrs)
*"Track your payment decisions"*

### Concept
Users voluntarily log transactions they're unsure about. This creates a personal history and, if they get scammed, converts directly into a scam report with pre-filled data. It also feeds more data into the community database.

### Backend Changes

#### [MODIFY] Prisma `Transaction` model (already exists, needs enhancement)

```prisma
model Transaction {
  id            String   @id @default(uuid())
  amount        Float
  merchant      String
  decision      String   // "safe" | "suspicious" | "scammed"
  riskScore     Int
  createdAt     DateTime @default(now())
  userId        String
  // NEW fields:
  paymentMethod String?  // "duitnow" | "bank_transfer" | "ewallet" | "cash"
  platform      String?  // "Shopee" | "Carousell" | "WhatsApp" | "Facebook"
  recipientId   String?  // Bank account / phone / DuitNow ID
  notes         String?
  reportId      String?  // Link to ScamReport if converted
  user          User     @relation(fields: [userId], references: [id])
}
```

#### [NEW] `POST /api/transactions/log`
Log a transaction with pre-check:

```typescript
// Request
{
  "amount": 250.00,
  "merchant": "Ali Electronics",
  "paymentMethod": "duitnow",
  "platform": "Carousell",
  "recipientId": "60123456789",
  "notes": "Buying a used iPhone, seller wants direct transfer"
}

// Response (auto-runs lookup)
{
  "transaction": { ... },
  "preCheck": {
    "riskLevel": "medium",
    "communityReports": 1,
    "recommendation": "1 previous report found for this recipient. Consider using platform escrow instead."
  }
}
```

#### [NEW] `POST /api/transactions/:id/convert-to-report`
Converts a logged transaction into a scam report with pre-filled fields:

```typescript
// Automatically fills:
// - type: from paymentMethod
// - target: from recipientId
// - category: inferred from platform
// - evidence: { amount, merchant, platform, originalTransaction }
```

### Flutter Changes

#### [NEW] `transaction_journal_screen.dart`
Replace the empty `transaction_screen.dart` with:
- **Log form**: Amount, recipient, method, platform, optional notes
- **Auto-check**: Badge showing community risk check on recipient
- **Timeline**: Chronological list of logged transactions with status icons
- **Convert button**: "I Got Scammed" → converts to report with pre-filled data

#### [MODIFY] `home_screen.dart`
Add a quick-access "Log Payment" FAB or card on the home screen.

---

## Integration Points (Existing Code)

| Existing Asset | How It's Reused |
|---------------|----------------|
| `searchReports` API | Foundation for `/api/reports/lookup` — same `ScamReport.target` query |
| `RiskEvaluator` | Extended with `evaluatePayment()` method |
| `fraud_check_screen.dart` | Add "Payment" tab or link to dedicated screen |
| `CheckResultScreen` | Enhanced with community report badges + emergency CTAs |
| `scam_map_screen.dart` | Data reused for area-based alert visualization |
| `Transaction` Prisma model | Enhanced with new fields for journal feature |
| `ScamReport.target` field | Already stores phone/bank/URL — queried by lookup |
| Bull/Redis queue | Already configured — used for alert engine background jobs |

---

## Phased Delivery

| Phase | Tier | What Ships | Est. | Dependency |
|-------|------|-----------|------|------------|
| **Sprint 1** | 1 | "Check Before You Pay" + lookup API | ~8 hrs | None |
| **Sprint 2** | 2 | Trending alerts API + in-app alerts screen | ~6 hrs | None |
| **Sprint 3** | 2 | Push notifications + alert subscriptions | ~4 hrs | FCM setup |
| **Sprint 4** | 3 | Transaction journal + convert-to-report | ~8 hrs | Tier 1 |
| **Total** | | | **~26 hrs** | |

---

## Monetization Tie-In

| Feature | Free Tier | Paid Tier (Shield Basic) |
|---------|-----------|--------------------------|
| Pre-transaction check | 3 checks/day | Unlimited |
| Community report count | "Reports found" (yes/no) | Full detail (count, categories, dates) |
| Trending alerts | Top 1 alert | All trending + area-based |
| Push notifications | Weekly digest | Real-time |
| Transaction journal | Last 10 entries | Unlimited history |

This creates a natural conversion funnel: free users see *that* reports exist, paid users see *what* the reports say.

---

## Key Decisions Made

1. **UI Approach:** Add a "Payment" tab to the existing Fraud Check screen.
2. **Alert frequency cap:** Maximum 3 push notifications per day to prevent alert fatigue.
3. **Free tier limits:** Free users get 5 pre-transaction checks per day.
4. **Location granularity:** Area-based alerts will use city-level location to balance relevance with user privacy.
