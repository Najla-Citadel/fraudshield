# Community Feed - Implementation Improvement Plan

**Created:** 2026-03-10
**Based on:** Community Feed Comprehensive Audit
**Current Score:** 6.3/10 (NOT production-safe at scale)
**Target Score:** 8.5+/10 (Production-ready)

---

## Executive Summary

This plan addresses the critical gaps preventing safe production deployment of the Community Feed feature. The audit identified 5 critical weaknesses: unredacted target exposure in the public feed, comment identity leaks, zero comment moderation, verification point farming, and no content safety screening. Implementation is divided into 4 phases, with Phase 1 and 2 being **mandatory** before public release.

**Estimated Timeline:**
- **Phase 1 (Critical):** 1-2 weeks → Fixes privacy and safety blockers
- **Phase 2 (Essential):** 2-4 weeks → Content moderation and abuse prevention
- **Phase 3 (Intelligence):** 4-6 weeks → Automated entity extraction, real-time updates
- **Phase 4 (Scale):** Ongoing → Performance, ML scoring, community governance

---

## Phase 1: Critical Blockers (1-2 weeks)

**Goal:** Fix privacy violations, close the comment attack surface, and stop point farming.

### 1.1 Redact Targets in Public Feed

**Current Issue:** Full phone numbers and bank accounts are decrypted and returned to ALL users in the public feed. The `redactedValue()` function exists at `report.controller.ts:689` but is never called.

**Risk:** Defamation liability, PDPA non-compliance, potential harassment of innocent parties.

**Files to modify:**
- `fraudshield-backend/src/controllers/report.controller.ts`

#### Implementation Steps:

**1.1.1 Apply redaction in `getPublicFeed`**
```typescript
// In getPublicFeed(), line ~280, replace:
//   target: EncryptionUtils.decrypt(report.target || ''),
// With:
target: redactTarget(EncryptionUtils.decrypt(report.target || ''), report.type),
```

**1.1.2 Apply redaction in `searchReports`**
```typescript
// In searchReports(), line ~433, same change:
target: redactTarget(EncryptionUtils.decrypt(report.target || ''), report.type),
```

**1.1.3 Improve the redaction utility**
```typescript
// Replace the existing redactedValue() at line 689 with:
function redactTarget(val: string, type?: string): string {
    if (!val) return '****';

    // Phone: show first 3 + last 2 → "012****89"
    if (type === 'phone' && val.length > 5) {
        return `${val.substring(0, 3)}****${val.substring(val.length - 2)}`;
    }

    // Bank: show last 4 digits → "****1234"
    if (type === 'bank' && val.length > 4) {
        return `****${val.substring(val.length - 4)}`;
    }

    // URL: show domain only → "example.com/****"
    if (type === 'link' || type === 'url') {
        try {
            const url = new URL(val.startsWith('http') ? val : `https://${val}`);
            return `${url.hostname}/****`;
        } catch {
            return val.length > 10 ? `${val.substring(0, 10)}****` : val;
        }
    }

    // Default: show first 3 + last 2
    if (val.length > 5) {
        return `${val.substring(0, 3)}****${val.substring(val.length - 2)}`;
    }
    return '****';
}
```

**1.1.4 Keep full target visible to report owner**
- `getReportDetails` already gates by `isOwner` — no change needed there.
- `getMyReports` returns full target to the owner — correct behavior, no change.

**1.1.5 Update Flutter ScamCard**
- Update `fraudshield/lib/widgets/scam_card.dart` to handle redacted target display gracefully (the card already truncates, but verify it doesn't try to parse redacted phone numbers).

**Verification:** Call `GET /api/v1/reports/public` and confirm phone/bank targets are masked. Call `GET /api/v1/reports/:id` as owner and confirm full target is visible.

---

### 1.2 Fix Comment Identity Leak

**Current Issue:** `comment.controller.ts:25` returns `user.fullName` in comment responses, deanonymizing users on public reports.

**Risk:** Users who comment on scam reports can be identified and potentially targeted.

**Files to modify:**
- `fraudshield-backend/src/controllers/comment.controller.ts`

#### Implementation Steps:

**1.2.1 Anonymize comment responses in `addComment`**
```typescript
// Replace the include block (lines 20-31) with:
include: {
    user: {
        select: {
            profile: {
                select: {
                    avatar: true,
                    preferredName: true,
                    reputation: true,
                }
            }
        }
    }
}
```

**1.2.2 Anonymize `getComments` response**
```typescript
// Same change in getComments include block (lines 47-58)
// Then map the response to strip any remaining user identifiers:
const anonymized = comments.map((c: any) => ({
    id: c.id,
    text: c.text,
    createdAt: c.createdAt,
    reportId: c.reportId,
    commenter: {
        avatar: c.user?.profile?.avatar || 'Felix',
        displayName: c.user?.profile?.preferredName || 'Community Member',
        reputation: c.user?.profile?.reputation || 0,
    },
}));
res.json(anonymized);
```

**1.2.3 Update Flutter `report_details_screen.dart`**
- Update the comment rendering section (~lines 374-518) to use `commenter.displayName` and `commenter.avatar` instead of `user.fullName`.

**Verification:** Call `GET /api/v1/reports/:reportId/comments` and confirm no `fullName`, `email`, or `userId` is present in the response.

---

### 1.3 Basic Comment Safety

**Current Issue:** Comments accept any content with no length limit, no profanity filter, and no URL detection. This is an open attack surface for harassment, phishing links, and spam.

**Files to modify:**
- `fraudshield-backend/src/controllers/comment.controller.ts`

#### Implementation Steps:

**1.3.1 Add input validation**
```typescript
// In addComment(), after the empty check (line 10), add:
const trimmedText = text.trim();

if (trimmedText.length > 500) {
    return res.status(400).json({ message: 'Comment must be 500 characters or less' });
}

if (trimmedText.length < 3) {
    return res.status(400).json({ message: 'Comment is too short' });
}
```

**1.3.2 Create content filter utility**
```typescript
// New file: fraudshield-backend/src/utils/content-filter.ts
export class ContentFilter {
    // URL pattern detection
    private static readonly URL_REGEX = /https?:\/\/[^\s]+|www\.[^\s]+/gi;

    // Basic profanity list (expand as needed, consider a library like 'bad-words')
    private static readonly BLOCKED_PATTERNS = [
        /\b(bodoh|sial|babi|celaka|pukimak)\b/gi,  // Malay profanity
        // Add more patterns as needed
    ];

    static sanitize(text: string): { clean: string; blocked: boolean; reason?: string } {
        // 1. Check for URLs
        if (this.URL_REGEX.test(text)) {
            return { clean: text, blocked: true, reason: 'Comments cannot contain URLs' };
        }

        // 2. Check profanity
        for (const pattern of this.BLOCKED_PATTERNS) {
            if (pattern.test(text)) {
                return { clean: text, blocked: true, reason: 'Comment contains inappropriate language' };
            }
        }

        return { clean: text.trim(), blocked: false };
    }
}
```

**1.3.3 Apply filter in controller**
```typescript
// In addComment(), after length validation:
const filterResult = ContentFilter.sanitize(trimmedText);
if (filterResult.blocked) {
    return res.status(400).json({ message: filterResult.reason });
}
```

**1.3.4 Update Flutter comment input**
- Add `maxLength: 500` to the comment TextField in `report_details_screen.dart`
- Show character counter below the input field

**Verification:** Submit comments with URLs, profanity, and >500 chars — all should be rejected with appropriate error messages.

---

### 1.4 Cap Verification Point Rewards

**Current Issue:** Every vote awards 10 Shield Points unconditionally (`report.controller.ts:504-508`). A user with 20+ reputation can vote on every public report to farm unlimited points.

**Files to modify:**
- `fraudshield-backend/src/controllers/report.controller.ts`
- `fraudshield-backend/src/services/gamification.service.ts`

#### Implementation Steps:

**1.4.1 Add daily verification reward cap**
```typescript
// In verifyReport(), before awarding points (line 503), add:
const today = new Date();
today.setHours(0, 0, 0, 0);

const todayVerifications = await prisma.verification.count({
    where: {
        userId,
        createdAt: { gte: today },
    },
});

const DAILY_VERIFICATION_CAP = 10; // Max 10 rewarded votes per day (100 points)

if (todayVerifications <= DAILY_VERIFICATION_CAP) {
    await GamificationService.awardPoints(
        userId,
        10,
        `Verified report ${reportId}`
    );
}
// Verification still recorded even if points are capped
```

**1.4.2 Add daily reputation gain cap for reporters**
```typescript
// Before the reputation increment (line 512), add a similar daily cap check:
const todayRepGains = await prisma.verification.count({
    where: {
        reportId,
        isSame: true,
        createdAt: { gte: today },
    },
});

const DAILY_REP_CAP = 20; // Max +100 reputation per report per day
if (todayRepGains <= DAILY_REP_CAP) {
    await prisma.profile.upsert({ ... }); // existing reputation increment
}
```

**Verification:** Vote on 15 reports in a day — points should stop accruing after the 10th vote.

---

### 1.5 Validate Evidence JSON Schema

**Current Issue:** The `evidence` field accepts arbitrary JSON with no validation. Could contain oversized data, malicious payloads, or inappropriate content.

**Files to modify:**
- `fraudshield-backend/src/controllers/report.controller.ts`

#### Implementation Steps:

**1.5.1 Add evidence schema validation in `submitReport`**
```typescript
// Before creating the report (line 65), add:
const MAX_EVIDENCE_SIZE = 50 * 1024; // 50KB max
const evidenceStr = JSON.stringify(evidence || {});

if (evidenceStr.length > MAX_EVIDENCE_SIZE) {
    return res.status(400).json({ message: 'Evidence data exceeds maximum size (50KB)' });
}

// Whitelist allowed keys
const ALLOWED_EVIDENCE_KEYS = ['smsContent', 'message', 'callerName', 'screenshots', 'notes'];
if (evidence && typeof evidence === 'object') {
    const keys = Object.keys(evidence);
    const invalidKeys = keys.filter(k => !ALLOWED_EVIDENCE_KEYS.includes(k));
    if (invalidKeys.length > 0) {
        return res.status(400).json({
            message: `Invalid evidence fields: ${invalidKeys.join(', ')}`,
        });
    }

    // Validate screenshots array
    if (evidence.screenshots && (!Array.isArray(evidence.screenshots) || evidence.screenshots.length > 5)) {
        return res.status(400).json({ message: 'Maximum 5 screenshot references allowed' });
    }

    // Validate text field lengths
    if (evidence.smsContent && evidence.smsContent.length > 2000) {
        return res.status(400).json({ message: 'SMS content exceeds maximum length (2000 chars)' });
    }

    if (evidence.message && evidence.message.length > 2000) {
        return res.status(400).json({ message: 'Message content exceeds maximum length (2000 chars)' });
    }
}
```

**Verification:** Submit reports with oversized evidence, unknown keys, and >5 screenshots — all should be rejected.

---

## Phase 2: Content Moderation & Abuse Prevention (2-4 weeks)

**Goal:** Add automated content screening, community flagging, and anti-abuse systems.

### 2.1 AI Content Moderation Pipeline

**Current Issue:** All moderation is manual. Admin must review every report before it becomes public. No automated screening for hate speech, PII, or off-topic content.

**Files to create/modify:**
- `fraudshield-backend/src/services/content-moderation.service.ts` (new)
- `fraudshield-backend/src/controllers/report.controller.ts`

#### Implementation Steps:

**2.1.1 Create moderation service**
```typescript
// New file: fraudshield-backend/src/services/content-moderation.service.ts
import OpenAI from 'openai';

export interface ModerationResult {
    approved: boolean;
    flags: string[];       // e.g., ['pii_detected', 'off_topic']
    piiFound: string[];    // Types of PII detected
    confidence: number;    // 0-1
}

export class ContentModerationService {
    private static openai = new OpenAI();

    /**
     * Pre-screens report description and evidence before entering admin queue.
     * Does NOT auto-approve — sets a moderation score for admin prioritization.
     */
    static async screenReport(description: string, evidence: any): Promise<ModerationResult> {
        const flags: string[] = [];
        const piiFound: string[] = [];

        // 1. OpenAI Moderation API (free tier, checks hate/violence/self-harm)
        const modResult = await this.openai.moderations.create({
            input: description,
        });
        const categories = modResult.results[0]?.categories;
        if (categories?.harassment) flags.push('harassment');
        if (categories?.hate) flags.push('hate_speech');
        if (categories?.['sexual']) flags.push('sexual_content');
        if (categories?.violence) flags.push('violence');

        // 2. Local PII detection (regex-based)
        piiFound.push(...this.detectPII(description));
        if (evidence?.smsContent) {
            piiFound.push(...this.detectPII(evidence.smsContent));
        }
        if (piiFound.length > 0) flags.push('pii_detected');

        // 3. Off-topic detection (basic keyword check)
        if (this.isOffTopic(description)) flags.push('off_topic');

        return {
            approved: flags.length === 0,
            flags,
            piiFound: [...new Set(piiFound)],
            confidence: flags.length === 0 ? 0.9 : 0.7,
        };
    }

    private static readonly PII_PATTERNS: Array<{ name: string; regex: RegExp }> = [
        { name: 'malaysia_ic', regex: /\b\d{6}-?\d{2}-?\d{4}\b/g },
        { name: 'email', regex: /\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z]{2,}\b/gi },
        { name: 'full_address', regex: /\b(jalan|lorong|taman|no\.\s?\d+|blk\s?\d+)/gi },
    ];

    private static detectPII(text: string): string[] {
        const found: string[] = [];
        for (const { name, regex } of this.PII_PATTERNS) {
            if (regex.test(text)) found.push(name);
            regex.lastIndex = 0; // Reset global regex
        }
        return found;
    }

    private static readonly OFF_TOPIC_KEYWORDS = [
        'politics', 'election', 'vote for', 'parti',
        'buy now', 'discount', 'free gift', 'click here',
    ];

    private static isOffTopic(text: string): boolean {
        const lower = text.toLowerCase();
        return this.OFF_TOPIC_KEYWORDS.some(kw => lower.includes(kw));
    }
}
```

**2.1.2 Integrate into report submission**
```typescript
// In submitReport(), after validation but before DB insert:
const moderation = await ContentModerationService.screenReport(description, evidence);

// Store moderation result as metadata (admin can see flags)
const report = await prisma.scamReport.create({
    data: {
        // ...existing fields...
        evidence: {
            ...(evidence || {}),
            _moderation: {
                flags: moderation.flags,
                piiFound: moderation.piiFound,
                screenedAt: new Date().toISOString(),
            },
        },
    },
});

// If flagged, add to a priority review queue (higher visibility for admin)
// If clean, mark as ready for standard review
```

**2.1.3 Update admin dashboard to show moderation flags**
- In `fraudshield-admin/src/components/ReportDetailModal.tsx`, display `evidence._moderation.flags` as colored badges
- Add filter in `fraudshield-admin/src/pages/Reports.tsx` to sort by "Flagged" reports first

---

### 2.2 Community Flagging System

**Current Issue:** Users can only upvote/downvote (agree/disagree on scam legitimacy). No way to flag posts for harassment, misinformation, or inappropriate content.

**Files to create/modify:**
- `fraudshield-backend/prisma/schema.prisma` (new model)
- `fraudshield-backend/src/controllers/report.controller.ts` (new endpoint)
- `fraudshield-backend/src/routes/report.routes.ts`
- `fraudshield/lib/screens/report_details_screen.dart`

#### Implementation Steps:

**2.2.1 Add ContentFlag model to schema**
```prisma
model ContentFlag {
    id        String   @id @default(uuid())
    type      String   // 'report' | 'comment'
    targetId  String   // reportId or commentId
    userId    String
    reason    String   // 'harassment', 'false_accusation', 'spam', 'inappropriate', 'pii_exposed'
    details   String?  // Optional user description
    status    String   @default("PENDING")  // PENDING | REVIEWED | DISMISSED
    createdAt DateTime @default(now())

    @@unique([targetId, userId, type])  // One flag per user per item
    @@index([status])
    @@index([targetId])
}
```

**2.2.2 Add flag endpoint**
```typescript
// POST /api/v1/reports/flag
static async flagContent(req: Request, res: Response, next: NextFunction) {
    const { type, targetId, reason, details } = req.body;
    const userId = (req.user as any).id;

    const VALID_REASONS = ['harassment', 'false_accusation', 'spam', 'inappropriate', 'pii_exposed'];
    if (!VALID_REASONS.includes(reason)) {
        return res.status(400).json({ message: 'Invalid flag reason' });
    }

    const flag = await prisma.contentFlag.create({
        data: { type, targetId, userId, reason, details },
    });

    // Auto-hide if 3+ unique flags on same target
    const flagCount = await prisma.contentFlag.count({
        where: { targetId, type, status: 'PENDING' },
    });

    if (flagCount >= 3) {
        if (type === 'report') {
            await prisma.scamReport.update({
                where: { id: targetId },
                data: { isPublic: false }, // Hide until admin reviews
            });
        }
        // TODO: Hide comment if type === 'comment'
    }

    res.status(201).json({ message: 'Content flagged for review' });
}
```

**2.2.3 Add admin flag review page**
- New page in `fraudshield-admin/src/pages/ContentFlags.tsx`
- List flags grouped by targetId, with DISMISS / TAKE ACTION buttons
- TAKE ACTION: soft-delete the content + penalize the reporter (-10 reputation)

**2.2.4 Add flag button in Flutter**
- Add a "Report" option (triple-dot menu or flag icon) on `ScamCard` and comment items
- Present a bottom sheet with reason options
- Call `POST /api/v1/reports/flag`

---

### 2.3 Duplicate Report Detection

**Current Issue:** No checks for duplicate submissions. A user (or multiple coordinated users) can submit the same target+description repeatedly.

**Files to modify:**
- `fraudshield-backend/src/controllers/report.controller.ts`

#### Implementation Steps:

**2.3.1 Check for existing reports with same target before insert**
```typescript
// In submitReport(), after encrypting the target:
const encryptedTarget = EncryptionUtils.deterministicEncrypt(target);

// Check for recent duplicate from same user
const recentDuplicate = await prisma.scamReport.findFirst({
    where: {
        userId,
        target: encryptedTarget,
        createdAt: { gte: new Date(Date.now() - 24 * 60 * 60 * 1000) }, // 24 hours
        deletedAt: null,
    },
});

if (recentDuplicate) {
    return res.status(409).json({
        message: 'You have already reported this target in the last 24 hours',
        existingReportId: recentDuplicate.id,
    });
}

// Check for global duplicates (any user, same target, last 7 days)
const globalDuplicateCount = await prisma.scamReport.count({
    where: {
        target: encryptedTarget,
        createdAt: { gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) },
        deletedAt: null,
    },
});

// If many reports already exist, still accept but flag as corroborating
const isCorroborating = globalDuplicateCount > 0;
```

**2.3.2 Update Flutter submission flow**
- If 409 is returned, show "You already reported this — would you like to view your existing report?" with a link.

---

### 2.4 Anti-Bot & Device Fingerprinting

**Current Issue:** No device-level tracking. Multi-account abuse is possible since rate limits are per userId only.

**Files to create/modify:**
- `fraudshield-backend/src/middleware/device-fingerprint.middleware.ts` (new)
- `fraudshield/lib/services/api_service.dart`

#### Implementation Steps:

**2.4.1 Collect device fingerprint from Flutter**
```dart
// In api_service.dart, add to request headers:
headers['X-Device-Id'] = await _getDeviceId(); // Use device_info_plus package
headers['X-App-Hash'] = await _getAppSignatureHash();
```

**2.4.2 Create device fingerprint middleware**
```typescript
// Track submissions per device, not just per user
// Store device ID → userId mappings in Redis
// Flag if one device creates multiple accounts that all submit reports
```

**2.4.3 Add device-based rate limiting**
- Extend `reportLimiter` to also key on `X-Device-Id`
- If a device exceeds 10 reports across ALL accounts in 24 hours, block the device

---

## Phase 3: Intelligence & Real-Time (4-6 weeks)

**Goal:** Automated entity extraction, real-time feed updates, and feedback loops.

### 3.1 Automated Entity Extraction

**Current Issue:** Only the explicitly submitted `target` field is indexed. If a user writes multiple phone numbers or URLs in the description, they are not extracted.

**Files to create:**
- `fraudshield-backend/src/services/entity-extraction.service.ts` (new)

#### Implementation Steps:

**3.1.1 Create extraction service**
```typescript
// New file: fraudshield-backend/src/services/entity-extraction.service.ts
export class EntityExtractionService {
    private static readonly PHONE_REGEX = /(?:\+?6?0)\d{1,2}[-\s]?\d{3,4}[-\s]?\d{4}/g;
    private static readonly BANK_REGEX = /\b\d{10,16}\b/g;
    private static readonly URL_REGEX = /https?:\/\/[^\s<>"{}|\\^`[\]]+/gi;

    static extractAll(text: string): {
        phones: string[];
        bankAccounts: string[];
        urls: string[];
    } {
        return {
            phones: [...new Set((text.match(this.PHONE_REGEX) || []).map(p => p.replace(/[-\s]/g, '')))],
            bankAccounts: [...new Set(text.match(this.BANK_REGEX) || [])],
            urls: [...new Set(text.match(this.URL_REGEX) || [])],
        };
    }
}
```

**3.1.2 Run extraction on report approval**
```typescript
// In admin.controller.ts updateReportStatus(), after approval side-effects:
if (isNowApproved) {
    const decryptedTarget = EncryptionUtils.decrypt(updatedReport.target || '');
    const fullText = `${updatedReport.description} ${decryptedTarget}`;
    const entities = EntityExtractionService.extractAll(fullText);

    // Also extract from evidence
    if (updatedReport.evidence?.smsContent) {
        const smsEntities = EntityExtractionService.extractAll(updatedReport.evidence.smsContent);
        entities.phones.push(...smsEntities.phones);
        entities.urls.push(...smsEntities.urls);
    }

    // Upsert each extracted entity into ScamNumberCache or equivalent
    for (const phone of entities.phones) {
        await prisma.scamNumberCache.upsert({
            where: { phoneNumber: phone },
            update: {
                reportCount: { increment: 1 },
                lastReported: new Date(),
                categories: updatedReport.category,
            },
            create: {
                phoneNumber: phone,
                riskScore: 50,
                reportCount: 1,
                verifiedCount: 0,
                categories: [updatedReport.category],
                lastReported: new Date(),
            },
        });
    }
    // Similar for URLs and bank accounts (needs new cache tables)
}
```

**3.1.3 Create additional cache tables**
```prisma
model ScamUrlCache {
    url           String   @id
    riskScore     Int
    reportCount   Int
    verifiedCount Int
    categories    Json     @default("[]")
    lastReported  DateTime
    updatedAt     DateTime @updatedAt

    @@index([lastReported])
}

model ScamBankCache {
    accountNumber String   @id
    riskScore     Int
    reportCount   Int
    verifiedCount Int
    categories    Json     @default("[]")
    lastReported  DateTime
    updatedAt     DateTime @updatedAt

    @@index([lastReported])
}
```

---

### 3.2 Real-Time Feed Updates via Socket.io

**Current Issue:** Socket.io is initialized in `server.ts` but not used for feed updates. Users must pull-to-refresh.

**Files to modify:**
- `fraudshield-backend/src/controllers/admin.controller.ts`
- `fraudshield-backend/src/server.ts`
- `fraudshield/lib/screens/community_feed_screen.dart`

#### Implementation Steps:

**3.2.1 Emit event on report approval**
```typescript
// In admin.controller.ts updateReportStatus(), after approval:
import { io } from '../server';

if (isNowApproved) {
    io.emit('feed:new-report', {
        id: updatedReport.id,
        category: updatedReport.category,
        type: updatedReport.type,
        description: updatedReport.description.substring(0, 100),
        createdAt: updatedReport.createdAt,
    });
}
```

**3.2.2 Listen in Flutter**
```dart
// In community_feed_screen.dart initState():
SocketService.instance.on('feed:new-report', (data) {
    setState(() {
        _reports.insert(0, data); // Prepend to feed
        _showNewReportBanner = true; // "1 new report — tap to refresh"
    });
});
```

**3.2.3 Add "New reports available" banner**
- Show a dismissible banner at top of feed when new reports arrive
- Tapping it scrolls to top and refreshes

---

### 3.3 Feedback Loop: Lookup → Transaction Outcome

**Current Issue:** When a user checks a number via lookup and then proceeds (indicating false positive), this signal is not captured.

**Files to modify:**
- `fraudshield-backend/src/controllers/report.controller.ts`
- `fraudshield-backend/src/routes/report.routes.ts`

#### Implementation Steps:

**3.3.1 Add feedback endpoint**
```typescript
// POST /api/v1/reports/lookup-feedback
// Body: { target, type, action: 'proceeded' | 'cancelled' | 'reported' }
static async lookupFeedback(req: Request, res: Response, next: NextFunction) {
    const { target, type, action } = req.body;
    const userId = (req.user as any).id;

    await prisma.behavioralEvent.create({
        data: {
            type: 'LOOKUP_FEEDBACK',
            userId,
            metadata: { target, type, action },
        },
    });

    // If many users 'proceeded' after a high-risk lookup, the risk score
    // may need adjustment → feed into RiskEvaluationService tuning
    res.json({ message: 'Feedback recorded' });
}
```

---

### 3.4 OCR Pipeline for Screenshot Evidence

**Current Issue:** Screenshot URLs in evidence are stored but never processed.

**Files to create:**
- `fraudshield-backend/src/services/ocr.service.ts` (new)

#### Implementation Steps:

**3.4.1 Implement OCR on approval**
```typescript
// Use Google Cloud Vision or Tesseract.js for OCR
// On report approval, if evidence.screenshots exists:
// 1. Download each screenshot
// 2. Run OCR to extract text
// 3. Run EntityExtractionService on extracted text
// 4. Append extracted entities to the report's intelligence data
```

**3.4.2 Store extracted text**
```typescript
// Add to evidence JSON:
evidence._ocrResults = [
    { url: 'screenshot1.jpg', extractedText: '...', entities: { phones: [...], urls: [...] } }
];
```

---

## Phase 4: Scale & Governance (Ongoing)

**Goal:** Performance optimization, community governance, and ML-powered scoring.

### 4.1 Performance: Materialized Vote Counts

**Current Issue:** `getPublicFeed` loads ALL verifications per report and counts in-memory. O(n) per report at scale.

**Files to modify:**
- `fraudshield-backend/prisma/schema.prisma`
- `fraudshield-backend/src/controllers/report.controller.ts`

#### Implementation Steps:

**4.1.1 Add counter columns to ScamReport**
```prisma
model ScamReport {
    // ...existing fields...
    upvoteCount   Int @default(0)
    downvoteCount Int @default(0)
}
```

**4.1.2 Update counters in `verifyReport`**
```typescript
// After upsert verification, increment/decrement counters:
await prisma.scamReport.update({
    where: { id: reportId },
    data: {
        upvoteCount: isSame ? { increment: 1 } : undefined,
        downvoteCount: !isSame ? { increment: 1 } : undefined,
    },
});
```

**4.1.3 Remove `include: { verifications: true }` from feed queries**
- Use `upvoteCount` and `downvoteCount` directly instead of loading all verification rows

### 4.2 Full-Text Search Index

**Current Issue:** `description ILIKE '%query%'` performs full table scans.

#### Implementation Steps:

**4.2.1 Add PostgreSQL trgm extension and GIN index**
```sql
-- Migration
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_scam_report_description_trgm ON "ScamReport"
    USING GIN (description gin_trgm_ops);
```

**4.2.2 Use raw query for search**
```typescript
// In searchReports(), use Prisma raw query for trgm search:
const reports = await prisma.$queryRaw`
    SELECT * FROM "ScamReport"
    WHERE description % ${query}
    AND "isPublic" = true AND "deletedAt" IS NULL
    ORDER BY similarity(description, ${query}) DESC
    LIMIT ${limitNum} OFFSET ${offsetNum}
`;
```

### 4.3 Community Moderator Role

**Current Issue:** Only binary roles: user or admin. No intermediate moderator tier.

#### Implementation Steps:

**4.3.1 Add moderator role**
- Users with DIAMOND tier (10,000+ points) and reputation > 200 can be promoted to moderator by admin
- Moderators can: fast-track approve reports (still logged), dismiss flags, but cannot reject or delete

**4.3.2 Schema changes**
```prisma
// Add to User model:
role String @default("user") // 'user' | 'moderator' | 'admin'
```

**4.3.3 Moderator endpoints**
- `POST /api/v1/mod/approve/:reportId` — auto-approve with moderator audit trail
- `POST /api/v1/mod/dismiss-flag/:flagId` — dismiss content flags

### 4.4 Official Advisory Posts

**Current Issue:** No way to distinguish app team alerts from community reports in the feed.

#### Implementation Steps:

**4.4.1 Add `source` field to ScamReport**
```prisma
// Add to ScamReport:
source String @default("community") // 'community' | 'official' | 'law_enforcement'
```

**4.4.2 Admin can create official advisories**
- New admin endpoint: `POST /api/v1/admin/advisory`
- Auto-approved, marked with `source: 'official'`
- Rendered with distinct styling in Flutter (e.g., blue border, shield icon)

### 4.5 Reputation Floor & Recovery

**Current Issue:** Reputation can go negative indefinitely. No recovery mechanism for penalized users.

#### Implementation Steps:

- Set reputation floor to 0: `reputation: { decrement: Math.min(2, currentRep) }`
- Add "reputation recovery" — users regain 1 reputation per day of active, non-flagged participation
- At reputation 0, restrict to read-only for 7 days before allowing new submissions

### 4.6 Right-to-Erasure (PDPA Compliance)

**Current Issue:** No endpoint for users to request deletion of their data.

#### Implementation Steps:

**4.6.1 Add data deletion endpoint**
```typescript
// DELETE /api/v1/profile/data
// Anonymizes all user data:
// - Soft-deletes all reports
// - Replaces comments with "[deleted]"
// - Removes profile data
// - Preserves audit trail with anonymized userId
```

---

## Implementation Priority Matrix

| Task | Phase | Severity | Effort | Impact |
|---|---|---|---|---|
| 1.1 Redact targets in public feed | 1 | **CRITICAL** | Small | Privacy/Legal |
| 1.2 Fix comment identity leak | 1 | **CRITICAL** | Small | Privacy |
| 1.3 Basic comment safety | 1 | **CRITICAL** | Small | Safety |
| 1.4 Cap verification rewards | 1 | **HIGH** | Small | Abuse prevention |
| 1.5 Validate evidence JSON | 1 | **HIGH** | Small | Security |
| 2.1 AI content moderation | 2 | **HIGH** | Medium | Moderation scale |
| 2.2 Community flagging | 2 | **HIGH** | Medium | Safety/Moderation |
| 2.3 Duplicate report detection | 2 | **MEDIUM** | Small | Data quality |
| 2.4 Device fingerprinting | 2 | **MEDIUM** | Medium | Anti-bot |
| 3.1 Entity extraction | 3 | **HIGH** | Medium | Intelligence value |
| 3.2 Real-time feed (Socket.io) | 3 | **MEDIUM** | Medium | User engagement |
| 3.3 Lookup feedback loop | 3 | **LOW** | Small | Scoring accuracy |
| 3.4 OCR pipeline | 3 | **LOW** | Large | Intelligence value |
| 4.1 Materialized vote counts | 4 | **MEDIUM** | Small | Performance |
| 4.2 Full-text search index | 4 | **MEDIUM** | Small | Performance |
| 4.3 Community moderator role | 4 | **LOW** | Medium | Governance |
| 4.4 Official advisory posts | 4 | **LOW** | Small | Trust/Credibility |
| 4.5 Reputation floor | 4 | **LOW** | Small | User experience |
| 4.6 Right-to-erasure | 4 | **MEDIUM** | Medium | PDPA compliance |

---

## Target Scores After Implementation

| Dimension | Current | After Phase 1 | After Phase 2 | After Phase 4 |
|---|---|---|---|---|
| Security | 7 | 8 | 9 | 9 |
| Moderation | 5 | 6 | 8 | 9 |
| Intelligence Value | 7 | 7 | 7 | 9 |
| User Engagement | 7 | 7 | 8 | 9 |
| Privacy Protection | 5 | 8 | 8 | 9 |
| System Scalability | 7 | 7 | 7 | 9 |
| **Overall** | **6.3** | **7.2** | **7.8** | **9.0** |

---

## Success Criteria

**Phase 1 complete when:**
- [ ] `GET /reports/public` returns redacted targets (phone: `012****89`, bank: `****1234`)
- [ ] `GET /reports/:id/comments` returns no `fullName` or `userId`
- [ ] Comments >500 chars, with URLs, or with profanity are rejected
- [ ] Verification points stop after 10 votes per day
- [ ] Evidence with invalid keys or >50KB is rejected
- [ ] All existing tests pass

**Phase 2 complete when:**
- [ ] Reports are auto-screened for hate speech and PII before entering admin queue
- [ ] Users can flag posts/comments with reason codes
- [ ] 3+ flags auto-hide content pending admin review
- [ ] Duplicate reports within 24h from same user are blocked
- [ ] Admin dashboard shows moderation flags and flag review queue

**Production-ready when:**
- [ ] Phase 1 + Phase 2 complete
- [ ] Load tested at 10x expected daily volume
- [ ] Legal review of PDPA compliance completed
- [ ] Defamation disclaimer displayed on all public report views
