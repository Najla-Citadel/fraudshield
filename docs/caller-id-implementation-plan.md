# Caller ID Protection - Implementation Improvement Plan

**Created:** 2026-03-09
**Based on:** caller-id-protection-audit.md
**Current Score:** 5.8/10 (NOT production-ready)
**Target Score:** 8.5+/10 (Production-ready)

---

## Executive Summary

This plan addresses the critical gaps preventing production deployment of the Caller ID Protection feature. Implementation is divided into 4 phases over approximately 16-20 weeks, with Phase 1 and 2 being **mandatory** before public release.

**Estimated Timeline:**
- **Phase 1 (Critical):** 2-4 weeks → Makes feature deployable as beta
- **Phase 2 (Essential):** 4-6 weeks → Production-ready quality
- **Phase 3 (Platform Parity):** 8-12 weeks → iOS support + intelligence upgrades
- **Phase 4 (Ongoing):** Continuous improvement

---

## Phase 1: Critical Blockers (2-4 weeks)

**Goal:** Remove Play Store rejection risks, add offline protection, clean production code.

### 1.1 Play Store Compliance - CallScreeningService Migration

**Current Issue:** Using `READ_CALL_LOG` restricted permission via `phone_state` package creates Play Store rejection risk.

**Solution:** Migrate to Android's official `CallScreeningService` API (Android 10+).

#### Implementation Steps:

**1.1.1 Create Native CallScreeningService**
```kotlin
// File: fraudshield/android/app/src/main/kotlin/com/fraudshield/app/CallScreeningServiceImpl.kt
package com.fraudshield.app

import android.telecom.Call
import android.telecom.CallScreeningService
import androidx.annotation.RequiresApi
import android.os.Build

@RequiresApi(Build.VERSION_CODES.N)
class FraudShieldCallScreeningService : CallScreeningService() {

    override fun onScreenCall(callDetails: Call.Details) {
        val phoneNumber = callDetails.handle?.schemeSpecificPart
        val response = CallResponse.Builder()
            .setDisallowCall(false)  // Don't auto-block, just notify
            .setRejectCall(false)
            .setSkipCallLog(false)
            .setSkipNotification(false)
            .build()

        // Send phone number to Flutter via MethodChannel
        sendToFlutter(phoneNumber, callDetails)
        respondToCall(callDetails, response)
    }

    private fun sendToFlutter(number: String?, details: Call.Details) {
        // Use MethodChannel to notify Flutter layer
        // Flutter handles risk evaluation + overlay display
    }
}
```

**1.1.2 Update AndroidManifest.xml**
```xml
<!-- Remove/reduce restricted permissions -->
<uses-permission android:name="android.permission.READ_PHONE_STATE" />
<!-- Remove: android.permission.READ_CALL_LOG -->
<uses-permission android:name="android.permission.READ_PHONE_NUMBERS" />

<!-- Add CallScreeningService -->
<service
    android:name=".FraudShieldCallScreeningService"
    android:permission="android.permission.BIND_SCREENING_SERVICE"
    android:exported="true">
    <intent-filter>
        <action android:name="android.telecom.CallScreeningService" />
    </intent-filter>
</service>
```

**1.1.3 Update Flutter Integration**
- **File:** `fraudshield/lib/services/call_state_service.dart`
- Add MethodChannel handler for CallScreeningService callbacks
- Maintain backward compatibility for Android 9 and below (fallback to phone_state)
- Update initialization logic in `main.dart`

**1.1.4 Remove phone_state Package**
```yaml
# File: fraudshield/pubspec.yaml
# Remove or mark as conditional dependency
dependencies:
  # phone_state: ^1.2.0  # Only for Android < 10
```

**Files to Modify:**
- `fraudshield/android/app/src/main/kotlin/com/fraudshield/app/MainActivity.kt`
- `fraudshield/android/app/src/main/AndroidManifest.xml`
- `fraudshield/lib/services/call_state_service.dart`
- `fraudshield/pubspec.yaml`

**Testing:**
- Test on Android 10, 11, 12, 13, 14
- Verify call screening triggers correctly
- Confirm Play Store policy compliance

---

### 1.2 Offline Scam Number Database

**Current Issue:** Zero protection when internet is unavailable.

**Solution:** Implement local SQLite database with periodic sync of high-confidence scam numbers.

#### Implementation Steps:

**1.2.1 Create Local Database Schema**
```dart
// File: fraudshield/lib/database/scam_numbers_db.dart
import 'package:sqflite/sqflite.dart';

class ScamNumbersDB {
  static const String TABLE_NAME = 'scam_numbers';

  static Future<Database> initDB() async {
    return openDatabase(
      'fraudshield_scam_numbers.db',
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $TABLE_NAME (
            phone_number TEXT PRIMARY KEY,
            risk_score INTEGER NOT NULL,
            report_count INTEGER NOT NULL,
            last_reported INTEGER NOT NULL,
            scam_category TEXT,
            verified BOOLEAN NOT NULL,
            synced_at INTEGER NOT NULL
          )
        ''');

        await db.execute('''
          CREATE INDEX idx_risk_score ON $TABLE_NAME(risk_score);
        ''');

        await db.execute('''
          CREATE INDEX idx_synced_at ON $TABLE_NAME(synced_at);
        ''');
      },
    );
  }

  Future<Map<String, dynamic>?> lookupNumber(String phoneNumber) async {
    final db = await database;
    final results = await db.query(
      TABLE_NAME,
      where: 'phone_number = ?',
      whereArgs: [phoneNumber],
    );
    return results.isNotEmpty ? results.first : null;
  }
}
```

**1.2.2 Create Sync Service**
```dart
// File: fraudshield/lib/services/scam_db_sync_service.dart
class ScamDBSyncService {
  final ApiService _api;
  final ScamNumbersDB _localDB;

  /// Sync top reported scam numbers (verified reports, risk score >= 70)
  Future<void> syncScamNumbers() async {
    try {
      final response = await _api.get('/api/v1/scam-reports/high-confidence');
      final numbers = response.data['numbers'] as List;

      final db = await _localDB.database;
      await db.transaction((txn) async {
        for (var number in numbers) {
          await txn.insert(
            ScamNumbersDB.TABLE_NAME,
            {
              'phone_number': number['phoneNumber'],
              'risk_score': number['riskScore'],
              'report_count': number['reportCount'],
              'last_reported': number['lastReportedAt'],
              'scam_category': number['category'],
              'verified': 1,
              'synced_at': DateTime.now().millisecondsSinceEpoch,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });

      await _cleanOldEntries();
    } catch (e) {
      print('Scam DB sync failed: $e');
    }
  }

  /// Remove entries older than 90 days
  Future<void> _cleanOldEntries() async {
    final cutoff = DateTime.now()
        .subtract(Duration(days: 90))
        .millisecondsSinceEpoch;

    final db = await _localDB.database;
    await db.delete(
      ScamNumbersDB.TABLE_NAME,
      where: 'synced_at < ?',
      whereArgs: [cutoff],
    );
  }
}
```

**1.2.3 Integrate with Risk Evaluation**
```dart
// File: fraudshield/lib/services/risk_evaluator.dart
Future<RiskEvaluationResult> evaluateNumber(String phoneNumber) async {
  // 1. Check contacts (existing logic)
  if (await _isInContacts(phoneNumber)) {
    return RiskEvaluationResult(score: 0, reason: 'Saved Contact');
  }

  // 2. Check local offline database FIRST
  final localResult = await _scamDB.lookupNumber(phoneNumber);
  if (localResult != null) {
    return RiskEvaluationResult(
      score: localResult['risk_score'],
      reason: 'Known Scam (${localResult['report_count']} reports)',
      category: localResult['scam_category'],
      source: 'offline',
    );
  }

  // 3. Try online API (existing logic)
  try {
    return await _apiLookup(phoneNumber);
  } catch (e) {
    // 4. Fallback to neighbor spoofing heuristic
    return _neighborSpoofingCheck(phoneNumber);
  }
}
```

**1.2.4 Add Backend Endpoint**
```typescript
// File: fraudshield-backend/src/controllers/scam-reports.controller.ts
/**
 * GET /api/v1/scam-reports/high-confidence
 * Returns verified scam numbers with risk score >= 70 for offline DB sync
 */
async getHighConfidenceScamNumbers(req: Request, res: Response) {
  const numbers = await prisma.scamReport.findMany({
    where: {
      status: 'VERIFIED',
      deletedAt: null,
    },
    select: {
      phoneNumber: true,
      reportCount: true,
      lastReportedAt: true,
      category: true,
    },
    take: 5000, // Top 5000 most reported
    orderBy: { reportCount: 'desc' },
  });

  // Decrypt and evaluate risk scores
  const enriched = await Promise.all(
    numbers.map(async (n) => {
      const decrypted = await decrypt(n.phoneNumber);
      const score = await this.riskEvalService.evaluate(decrypted);
      return {
        phoneNumber: decrypted,
        riskScore: score.rawScore,
        reportCount: n.reportCount,
        lastReportedAt: n.lastReportedAt,
        category: n.category,
      };
    })
  );

  res.json({
    numbers: enriched.filter(n => n.riskScore >= 70),
    syncedAt: new Date().toISOString(),
  });
}
```

**1.2.5 Schedule Periodic Sync**
```dart
// File: fraudshield/lib/services/background_sync_service.dart
import 'package:workmanager/workmanager.dart';

class BackgroundSyncService {
  static const SYNC_TASK = 'scam_db_sync';

  static void initialize() {
    Workmanager().initialize(callbackDispatcher);

    // Sync every 12 hours
    Workmanager().registerPeriodicTask(
      SYNC_TASK,
      SYNC_TASK,
      frequency: Duration(hours: 12),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == BackgroundSyncService.SYNC_TASK) {
      await ScamDBSyncService().syncScamNumbers();
    }
    return Future.value(true);
  });
}
```

**Files to Create/Modify:**
- `fraudshield/lib/database/scam_numbers_db.dart` (new)
- `fraudshield/lib/services/scam_db_sync_service.dart` (new)
- `fraudshield/lib/services/background_sync_service.dart` (new)
- `fraudshield/lib/services/risk_evaluator.dart` (modify)
- `fraudshield-backend/src/controllers/scam-reports.controller.ts` (add endpoint)
- `fraudshield-backend/src/routes/scam-reports.routes.ts` (add route)
- `fraudshield/pubspec.yaml` (add sqflite, workmanager dependencies)

**Testing:**
- Test with airplane mode enabled
- Verify sync works on Wi-Fi and cellular
- Test database size limits (max 5000 entries)

---

### 1.3 Remove Debug Code from Production

**Current Issue:** `simulateRinging()` method accessible in production builds.

**Solution:** Remove simulation methods or guard with `kDebugMode` flag.

#### Implementation Steps:

**1.3.1 Guard Simulation Methods**
```dart
// File: fraudshield/lib/services/call_state_service.dart
import 'package:flutter/foundation.dart';

class CallStateService {
  // Remove or guard with debug flag
  void simulateRinging(String phoneNumber) {
    if (kDebugMode) {
      _handleIncomingCall(phoneNumber);
    } else {
      throw UnsupportedError('Simulation only available in debug builds');
    }
  }
}
```

**1.3.2 Add ProGuard Rules (Android)**
```proguard
# File: fraudshield/android/app/proguard-rules.pro
# Remove debug methods in release builds
-assumenosideeffects class com.fraudshield.app.MainActivity {
    *** simulateRinging(...);
}
```

**1.3.3 Strip Mock Semak Mule Hardcoded Patterns**
```typescript
// File: fraudshield-backend/src/services/semak-mule.service.ts
async checkNumber(phoneNumber: string): Promise<SemakMuleResult> {
  // Remove hardcoded patterns in production
  if (process.env.NODE_ENV === 'production') {
    throw new Error('Semak Mule API not configured for production');
  }

  // Keep mock for development/staging only
  if (process.env.NODE_ENV === 'development') {
    return this._mockCheck(phoneNumber);
  }
}
```

**Files to Modify:**
- `fraudshield/lib/services/call_state_service.dart`
- `fraudshield/android/app/proguard-rules.pro`
- `fraudshield-backend/src/services/semak-mule.service.ts`

---

### 1.4 Foreground Service Type Justification

**Current Issue:** Using `specialUse` foreground service type requires Play Store justification.

**Solution:** Switch to `phoneCall` service type or prepare justification document.

#### Implementation Steps:

**1.4.1 Update Foreground Service Type**
```xml
<!-- File: fraudshield/android/app/src/main/AndroidManifest.xml -->
<service
    android:name="com.pravera.flutter_foreground_task.service.ForegroundService"
    android:foregroundServiceType="phoneCall"
    android:exported="false" />
```

**1.4.2 Create Play Store Declaration Document**
```markdown
# File: docs/play-store-declarations.md
## Foreground Service Justification

**Service Type:** phoneCall

**Purpose:** FraudShield requires a persistent foreground service to monitor
incoming calls in real-time and display scam risk warnings to protect users
from fraud. This is a core feature of our anti-scam protection app.

**User Benefit:** Real-time protection against scam calls, bank impersonation,
and government agency fraud.

**Why phoneCall type:** The service actively monitors incoming call state and
displays overlays during active calls.

**Alternative Considered:** We evaluated using CallScreeningService exclusively,
but foreground service is required for overlay management and cross-screen persistence.
```

**Files to Modify:**
- `fraudshield/android/app/src/main/AndroidManifest.xml`
- `docs/play-store-declarations.md` (new)

---

## Phase 2: Essential Production Quality (4-6 weeks)

**Goal:** Integrate real intelligence sources, add user controls, optimize performance.

### 2.1 Real PDRM Semak Mule API Integration

**Current Issue:** Mock API returns fake data.

**Solution:** Integrate with real PDRM API once data sharing agreement is signed.

#### Implementation Steps:

**2.1.1 Create Production API Client**
```typescript
// File: fraudshield-backend/src/services/semak-mule.service.ts
import axios from 'axios';

export class SemakMuleService {
  private apiClient = axios.create({
    baseURL: process.env.PDRM_API_BASE_URL,
    timeout: 5000,
    headers: {
      'Authorization': `Bearer ${process.env.PDRM_API_KEY}`,
      'Content-Type': 'application/json',
    },
  });

  async checkNumber(phoneNumber: string): Promise<SemakMuleResult> {
    try {
      const response = await this.apiClient.post('/check-mule', {
        phoneNumber: this.normalizeNumber(phoneNumber),
        requesterId: process.env.PDRM_REQUESTER_ID,
      });

      return {
        found: response.data.isBlacklisted,
        riskLevel: response.data.riskLevel,
        reportCount: response.data.reportCount,
        lastUpdated: response.data.lastUpdated,
        caseReference: response.data.caseReference,
      };
    } catch (error) {
      // Log error but don't fail the entire risk evaluation
      logger.error('Semak Mule API error', { error, phoneNumber: 'REDACTED' });
      return { found: false };
    }
  }

  private normalizeNumber(phone: string): string {
    // Convert to Malaysian format (+60...)
    return phone.replace(/^0/, '+60');
  }
}
```

**2.1.2 Add Circuit Breaker**
```typescript
// Prevent cascade failures if PDRM API goes down
import CircuitBreaker from 'opossum';

const semakMuleBreaker = new CircuitBreaker(
  async (phoneNumber: string) => semakMuleService.checkNumber(phoneNumber),
  {
    timeout: 5000,
    errorThresholdPercentage: 50,
    resetTimeout: 30000,
  }
);
```

**2.1.3 Update Environment Variables**
```bash
# File: fraudshield-backend/.env.example
PDRM_API_BASE_URL=https://api.pdrm.gov.my/semak-mule
PDRM_API_KEY=your_api_key_here
PDRM_REQUESTER_ID=fraudshield_app
```

**Files to Modify:**
- `fraudshield-backend/src/services/semak-mule.service.ts`
- `fraudshield-backend/.env.example`
- `fraudshield-backend/package.json` (add opossum dependency)

**Testing:**
- Integration tests with PDRM sandbox environment
- Error handling when API is down
- Rate limit compliance

---

### 2.2 Redis Caching for Risk Scores

**Current Issue:** Every call triggers backend API request, causing latency and load.

**Solution:** Cache risk scores in Redis with 5-10 minute TTL.

#### Implementation Steps:

**2.2.1 Add Caching Layer**
```typescript
// File: fraudshield-backend/src/services/risk-evaluation.service.ts
import { redisClient } from '../config/redis';

export class RiskEvaluationService {
  private CACHE_TTL = 600; // 10 minutes

  async evaluatePhoneNumber(phoneNumber: string): Promise<RiskScore> {
    const cacheKey = `risk:${phoneNumber}`;

    // Check cache first
    const cached = await redisClient.get(cacheKey);
    if (cached) {
      return JSON.parse(cached);
    }

    // Compute risk score
    const result = await this._computeRiskScore(phoneNumber);

    // Cache result (only cache if score > 0 to avoid caching unknowns)
    if (result.rawScore > 0) {
      await redisClient.setEx(cacheKey, this.CACHE_TTL, JSON.stringify(result));
    }

    return result;
  }

  // Invalidate cache when new report is submitted
  async invalidateCache(phoneNumber: string): Promise<void> {
    await redisClient.del(`risk:${phoneNumber}`);
  }
}
```

**2.2.2 Invalidate on New Reports**
```typescript
// File: fraudshield-backend/src/controllers/scam-reports.controller.ts
async submitReport(req: Request, res: Response) {
  const report = await this.scamReportService.create(req.body);

  // Invalidate cache for this number
  await this.riskEvalService.invalidateCache(req.body.phoneNumber);

  res.status(201).json(report);
}
```

**Files to Modify:**
- `fraudshield-backend/src/services/risk-evaluation.service.ts`
- `fraudshield-backend/src/controllers/scam-reports.controller.ts`
- `fraudshield-backend/src/controllers/admin-reports.controller.ts` (invalidate on verify)

**Testing:**
- Verify cache hit rate in Redis
- Test TTL expiration
- Confirm invalidation on new reports

---

### 2.3 User Whitelist & False Positive Controls

**Current Issue:** Users cannot mark numbers as safe or whitelist legitimate callers.

**Solution:** Add user-managed whitelist with persistent storage.

#### Implementation Steps:

**2.3.1 Create Whitelist Schema**
```prisma
// File: fraudshield-backend/prisma/schema.prisma
model UserWhitelist {
  id          String   @id @default(cuid())
  userId      String
  phoneNumber String   // Encrypted
  label       String?  // "Doctor's Office", "School", etc.
  addedAt     DateTime @default(now())

  user User @relation(fields: [userId], references: [id], onDelete: Cascade)

  @@unique([userId, phoneNumber])
  @@index([userId])
}
```

**2.3.2 Add Backend Endpoints**
```typescript
// File: fraudshield-backend/src/controllers/whitelist.controller.ts
export class WhitelistController {
  async add(req: Request, res: Response) {
    const { phoneNumber, label } = req.body;
    const userId = req.user!.id;

    const encrypted = await encrypt(phoneNumber);

    const entry = await prisma.userWhitelist.create({
      data: {
        userId,
        phoneNumber: encrypted,
        label: label || null,
      },
    });

    res.status(201).json(entry);
  }

  async list(req: Request, res: Response) {
    const entries = await prisma.userWhitelist.findMany({
      where: { userId: req.user!.id },
      orderBy: { addedAt: 'desc' },
    });

    const decrypted = await Promise.all(
      entries.map(async (e) => ({
        ...e,
        phoneNumber: await decrypt(e.phoneNumber),
      }))
    );

    res.json(decrypted);
  }

  async remove(req: Request, res: Response) {
    await prisma.userWhitelist.delete({
      where: {
        id: req.params.id,
        userId: req.user!.id, // Ensure ownership
      },
    });

    res.status(204).send();
  }
}
```

**2.3.3 Update Risk Evaluation**
```typescript
// File: fraudshield-backend/src/services/risk-evaluation.service.ts
async evaluatePhoneNumber(phoneNumber: string, userId: string): Promise<RiskScore> {
  // Check user whitelist first
  const whitelisted = await prisma.userWhitelist.findFirst({
    where: {
      userId,
      phoneNumber: await encrypt(phoneNumber),
    },
  });

  if (whitelisted) {
    return {
      rawScore: 0,
      reason: whitelisted.label || 'Whitelisted by you',
      source: 'user_whitelist',
    };
  }

  // Continue with normal evaluation...
}
```

**2.3.4 Add Flutter UI**
```dart
// File: fraudshield/lib/screens/whitelist_screen.dart
class WhitelistScreen extends StatelessWidget {
  Future<void> _addToWhitelist(String phoneNumber, String? label) async {
    await _api.post('/api/v1/whitelist', {
      'phoneNumber': phoneNumber,
      'label': label,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added to your safe list')),
    );
  }
}
```

**2.3.5 Add "Mark as Safe" in Overlay**
```dart
// File: fraudshield/lib/widgets/caller_risk_overlay.dart
Widget _buildActions() {
  return Row(
    children: [
      // Existing actions...
      TextButton.icon(
        icon: Icon(Icons.check_circle_outline),
        label: Text('Mark as Safe'),
        onPressed: () async {
          await _whitelistService.add(phoneNumber, label: 'Safe Caller');
          Navigator.pop(context);
        },
      ),
    ],
  );
}
```

**Files to Create/Modify:**
- `fraudshield-backend/prisma/schema.prisma` (add model)
- `fraudshield-backend/src/controllers/whitelist.controller.ts` (new)
- `fraudshield-backend/src/routes/whitelist.routes.ts` (new)
- `fraudshield-backend/src/services/risk-evaluation.service.ts` (modify)
- `fraudshield/lib/screens/whitelist_screen.dart` (new)
- `fraudshield/lib/widgets/caller_risk_overlay.dart` (modify)
- `fraudshield/lib/services/whitelist_service.dart` (new)

---

### 2.4 Reduce Default Unknown Score

**Current Issue:** All unknown numbers show score 35 (medium), causing alarm fatigue.

**Solution:** Reduce to 15-20 (low) and only show warnings for confirmed threats.

#### Implementation Steps:

**2.4.1 Update Default Score**
```dart
// File: fraudshield/lib/services/risk_evaluator.dart
class RiskEvaluator {
  static const DEFAULT_UNKNOWN_SCORE = 15; // Was 35

  RiskEvaluationResult _defaultUnknownResult(String phoneNumber) {
    return RiskEvaluationResult(
      score: DEFAULT_UNKNOWN_SCORE,
      reason: 'Unknown Number',
      category: null,
      showWarning: false, // Don't show overlay for low scores
    );
  }
}
```

**2.4.2 Update Overlay Display Logic**
```dart
// File: fraudshield/lib/services/call_state_service.dart
void _handleRiskResult(RiskEvaluationResult result) {
  // Only show overlay if score >= 55 (high) or
  // if explicitly flagged (Semak Mule, high report count)
  if (result.score >= 55 || result.showWarning) {
    _showOverlay(result);
  }
}
```

**Files to Modify:**
- `fraudshield/lib/services/risk_evaluator.dart`
- `fraudshield/lib/services/call_state_service.dart`

---

### 2.5 Data Retention Policy

**Current Issue:** Reports and transaction journals stored indefinitely.

**Solution:** Auto-expire old data after 2 years (configurable).

#### Implementation Steps:

**2.5.1 Create Cleanup Job**
```typescript
// File: fraudshield-backend/src/jobs/data-retention.job.ts
import { prisma } from '../config/database';

export class DataRetentionJob {
  private RETENTION_DAYS = 730; // 2 years

  async cleanOldReports() {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - this.RETENTION_DAYS);

    const result = await prisma.scamReport.updateMany({
      where: {
        createdAt: { lt: cutoff },
        deletedAt: null,
      },
      data: {
        deletedAt: new Date(),
      },
    });

    console.log(`Soft-deleted ${result.count} old scam reports`);
  }

  async cleanOldTransactionJournals() {
    const cutoff = new Date();
    cutoff.setDate(cutoff.getDate() - this.RETENTION_DAYS);

    await prisma.transactionJournal.deleteMany({
      where: {
        createdAt: { lt: cutoff },
      },
    });
  }
}
```

**2.5.2 Schedule with Bull Queue**
```typescript
// File: fraudshield-backend/src/services/alert-worker.service.ts
export class AlertWorkerService {
  initializeJobs() {
    // Existing trending alerts job...

    // Add data retention job (runs daily at 2 AM)
    this.queue.add(
      'data-retention',
      {},
      {
        repeat: { cron: '0 2 * * *' },
        removeOnComplete: true,
      }
    );
  }

  @Process('data-retention')
  async handleDataRetention() {
    const job = new DataRetentionJob();
    await job.cleanOldReports();
    await job.cleanOldTransactionJournals();
  }
}
```

**Files to Create/Modify:**
- `fraudshield-backend/src/jobs/data-retention.job.ts` (new)
- `fraudshield-backend/src/services/alert-worker.service.ts` (add job)

---

## Phase 3: Platform Parity & Intelligence Upgrades (8-12 weeks)

**Goal:** iOS support, third-party threat feeds, ML scoring.

### 3.1 iOS CallKit Implementation

**Current Issue:** Zero iOS support.

**Solution:** Implement CallKit Call Directory Extension.

#### High-Level Steps:

1. **Create Call Directory Extension**
   - Add new target in Xcode
   - Implement `CXCallDirectoryProvider`
   - Sync scam database to extension's shared container

2. **Implement Background Sync**
   - Use Background App Refresh to sync scam numbers
   - Store in Core Data (CallKit requires offline DB)

3. **Add Info.plist Permissions**
   - `NSExtensionPointIdentifier`
   - Call directory usage description

4. **Update Flutter Plugin**
   - Create MethodChannel for iOS
   - Handle platform-specific initialization

**Files to Create:**
- `fraudshield/ios/CallDirectoryExtension/` (new extension)
- `fraudshield/ios/Runner/Info.plist` (update)
- `fraudshield/lib/services/call_state_service_ios.dart` (new)

**Timeline:** 4-6 weeks (includes App Store review)

---

### 3.2 Third-Party Threat Intelligence Integration

**Current Issue:** No external threat feeds.

**Solution:** Integrate Hiya or Truecaller Business API.

#### Implementation Steps:

**3.2.1 Add Hiya API Client**
```typescript
// File: fraudshield-backend/src/services/hiya-intelligence.service.ts
export class HiyaIntelligenceService {
  async checkNumber(phoneNumber: string): Promise<HiyaResult> {
    const response = await this.client.get(`/v1/phone/${phoneNumber}`);
    return {
      isSpam: response.data.is_spam,
      category: response.data.category,
      reportCount: response.data.reports,
      confidence: response.data.confidence,
    };
  }
}
```

**3.2.2 Update Risk Scoring**
```typescript
// Blend multiple intelligence sources
const sources = await Promise.all([
  this.communityReports(phoneNumber),
  this.semakMule(phoneNumber),
  this.hiyaIntelligence(phoneNumber),
]);

const finalScore = this.blendScores(sources);
```

**Timeline:** 2-3 weeks (includes API onboarding)

---

### 3.3 ML-Based Risk Scoring

**Current Issue:** Rule-based scoring only.

**Solution:** Train ML model on historical reports.

#### Approach:

1. **Feature Engineering**
   - Number pattern features (length, prefix, area code)
   - Report velocity (reports per day trend)
   - Reporter reputation distribution
   - Time-of-day patterns
   - Call duration statistics

2. **Model Training**
   - Algorithm: Gradient Boosting (XGBoost or LightGBM)
   - Training data: Historical verified scam reports
   - Cross-validation with temporal splits

3. **Deployment**
   - Host model on backend (TensorFlow Serving or FastAPI)
   - Fallback to rule-based if model unavailable

**Timeline:** 4-6 weeks (includes data prep, training, validation)

---

## Phase 4: Continuous Improvement (Ongoing)

### 4.1 OEM-Specific Optimizations

- Battery optimization whitelisting prompts (Xiaomi, OPPO, Huawei)
- Lock screen overlay testing per manufacturer
- Autostart permission handling

### 4.2 Privacy Dashboard

- User data export (GDPR Article 15)
- Self-service data deletion (GDPR Article 17)
- Transparency report on data usage

### 4.3 Advanced Detection

- Number range/prefix risk scoring
- Rotating number pattern detection
- Real-time transcription during calls
- Business number database integration

---

## Implementation Priorities

### Must-Have (Before Public Launch)
- ✅ CallScreeningService migration (1.1)
- ✅ Offline database (1.2)
- ✅ Remove debug code (1.3)
- ✅ Real Semak Mule API (2.1)
- ✅ User whitelist (2.3)

### Should-Have (For Production Quality)
- ✅ Redis caching (2.2)
- ✅ Reduce default score (2.4)
- ✅ Data retention (2.5)
- ✅ Play Store justification docs (1.4)

### Nice-to-Have (Competitive Advantage)
- iOS support (3.1)
- Third-party intelligence (3.2)
- ML scoring (3.3)
- Privacy dashboard (4.2)

---

## Risk Mitigation

### Technical Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| CallScreeningService doesn't trigger reliably | Medium | High | Keep phone_state fallback for Android 9, extensive OEM testing |
| PDRM API unavailable/slow | Medium | Medium | Circuit breaker, cache results, graceful degradation |
| Offline DB grows too large | Low | Medium | Limit to 5000 entries, periodic cleanup |
| iOS App Store rejection | Low | High | Follow CallKit guidelines exactly, hire iOS consultant if needed |

### Business Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Play Store policy changes | Low | Critical | Monitor policy updates, maintain compliance docs |
| User complaints about false positives | Medium | Medium | User whitelist, clear "Mark as Safe" UI |
| Battery drain reports | Low | Medium | Performance monitoring, optimize overlay rendering |

---

## Success Metrics

### Phase 1 Completion
- [ ] App passes Play Store review without permission warnings
- [ ] Offline mode detects >80% of known scam numbers
- [ ] Zero simulation methods in production APK

### Phase 2 Completion
- [ ] 90%+ cache hit rate on repeat numbers
- [ ] <5% user-reported false positive rate
- [ ] Semak Mule integration shows real case references

### Phase 3 Completion
- [ ] iOS feature parity with Android
- [ ] Detection rate improves by 20%+ with external feeds
- [ ] ML model outperforms rule-based by 10%+ on validation set

---

## Resource Requirements

### Development Team
- **Android Engineer:** Full-time Phases 1-2, Part-time Phase 3
- **iOS Engineer:** Full-time Phase 3 (can hire contractor)
- **Backend Engineer:** Full-time Phases 1-2, Part-time Phases 3-4
- **ML Engineer:** Full-time Phase 3 only (can hire consultant)
- **QA Engineer:** Part-time throughout, Full-time before launch

### External Dependencies
- PDRM API access (legal/data sharing agreement)
- Hiya/Truecaller Business API subscription
- Google Play Console approval
- Apple Developer Program enrollment

### Infrastructure
- Additional Redis memory for caching layer
- ML model hosting (consider AWS SageMaker or Google Vertex AI)
- iOS app signing certificates

---

## Rollout Strategy

### Beta Testing (Post Phase 1)
- Internal testing: 2 weeks (team + family)
- Closed beta: 4 weeks (200 users via TestFlight/Play Console)
- Metrics: crash rate <0.1%, false positive rate <10%

### Phased Rollout (Post Phase 2)
1. **Week 1-2:** 10% of users (monitor performance)
2. **Week 3-4:** 50% of users (gather feedback)
3. **Week 5+:** 100% rollout

### Feature Flags
- `enable_offline_db` (default: true after Phase 1)
- `enable_ml_scoring` (default: false, gradual rollout in Phase 3)
- `enable_hiya_intelligence` (default: false, A/B test)

---

## Appendix: Key Files Reference

### Critical Flutter Files
- `lib/services/call_state_service.dart` - Core call monitoring
- `lib/services/risk_evaluator.dart` - Risk scoring logic
- `lib/widgets/caller_risk_overlay.dart` - Overlay UI
- `lib/database/scam_numbers_db.dart` - Offline database (new)

### Critical Backend Files
- `src/services/risk-evaluation.service.ts` - Backend risk engine
- `src/services/semak-mule.service.ts` - PDRM API integration
- `src/controllers/scam-reports.controller.ts` - Reports API
- `prisma/schema.prisma` - Database schema

### Configuration Files
- `fraudshield/android/app/src/main/AndroidManifest.xml` - Permissions
- `fraudshield-backend/.env` - Environment variables
- `fraudshield/pubspec.yaml` - Flutter dependencies
- `fraudshield-backend/package.json` - Backend dependencies

---

## Next Steps

1. **Review & Prioritize:** Team reviews this plan, adjusts timeline/scope
2. **Secure PDRM API Access:** Legal team finalizes data sharing agreement
3. **Create Jira/Linear Tickets:** Break down each phase into trackable tasks
4. **Assign Phase 1 Tasks:** Start with CallScreeningService migration (highest priority)
5. **Weekly Check-ins:** Track progress, blockers, adjust timeline as needed

---

**Document Version:** 1.0
**Last Updated:** 2026-03-09
**Owner:** Engineering Team
**Review Cadence:** Weekly during active development
