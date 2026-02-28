import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
import { BadgeController } from '../controllers/badge.controller';
import { SafeBrowsingController } from '../controllers/safebrowsing.controller';
import { RiskEvaluationController } from '../controllers/risk-evaluation.controller';
import { LeaderboardController } from '../controllers/leaderboard.controller';
import { QuishingController } from '../controllers/quishing.controller';
import { NlpMessageController } from '../controllers/nlp-message.controller';
import { PdfScanController } from '../controllers/pdf-scan.controller';
import { ApkScanController } from '../controllers/apk-scan.controller';
import { VoiceScanController } from '../controllers/voice-scan.controller';
import multer from 'multer';

import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Memory storage: file bytes available as req.file.buffer
const memoryUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max (for APKs)
});

// Protect all feature routes
router.use(authenticate);

// Safe Browsing (legacy single URL check)
router.post('/check-url', SafeBrowsingController.checkUrl);

// 2F: Advanced Link & QR (Quishing) — deep scan with redirect chain + Safe Browsing batch
router.post('/check-link', QuishingController.checkLink);
router.post('/check-qr', QuishingController.checkQr);

// 2H: NLP-based Message Analysis
router.post('/analyze-message', NlpMessageController.analyzeMessage);

// 2E: PDF Document Scanning
router.post('/scan-pdf', memoryUpload.single('file'), PdfScanController.scanPdf);

// 2G: APK & Malicious File Detection
router.post('/scan-apk', memoryUpload.single('file'), ApkScanController.scanApk);

// Voice Scam Detection (Premium only — enforced within controller)
router.post('/analyze-voice', memoryUpload.single('file'), VoiceScanController.analyzeVoice);

// AI Risk Score V2 — Centralized Evaluator
router.post('/evaluate-risk', RiskEvaluationController.evaluate);

// Subscriptions
router.get('/plans', SubscriptionController.getPlans);
router.get('/subscription', SubscriptionController.getMySubscription);
router.post('/subscription', SubscriptionController.createSubscription);

// Points
router.get('/points', PointsController.getMyPoints);
router.post('/points', PointsController.addPoints);

// Leaderboards
router.get('/leaderboard', LeaderboardController.getGlobalLeaderboard);
router.get('/leaderboard/me', LeaderboardController.getMyRank);

// Badges
router.get('/badges', BadgeController.getMyBadges);
router.get('/badges/all', BadgeController.getAllBadges);

router.post('/behavioral', BehavioralController.logEvent);
router.get('/behavioral', BehavioralController.getMyEvents);

export default router;
