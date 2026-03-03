import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
<<<<<<< HEAD
import { RewardsController } from '../controllers/rewards.controller';
=======
>>>>>>> dev-ui2
import { BadgeController } from '../controllers/badge.controller';
import { SafeBrowsingController } from '../controllers/safebrowsing.controller';
import { RiskEvaluationController } from '../controllers/risk-evaluation.controller';
import { LeaderboardController } from '../controllers/leaderboard.controller';
<<<<<<< HEAD

import passport from 'passport';

const router = Router();

// Protect all feature routes
router.use(passport.authenticate('jwt', { session: false }));

// Safe Browsing
router.post('/check-url', SafeBrowsingController.checkUrl);

// AI Risk Score V2 — Centralized Evaluator
router.post('/evaluate-risk', RiskEvaluationController.evaluate);
=======
import { QuishingController } from '../controllers/quishing.controller';
import { NlpMessageController } from '../controllers/nlp-message.controller';
import { PdfScanController } from '../controllers/pdf-scan.controller';
import { ApkScanController } from '../controllers/apk-scan.controller';
import { VoiceScanController } from '../controllers/voice-scan.controller';
import multer from 'multer';

import { authenticate } from '../middleware/auth.middleware';
import { isAdmin } from '../middleware/admin.middleware';
import { featureLimiter } from '../middleware/rateLimiter';

const router = Router();

// Memory storage: file bytes available as req.file.buffer
const memoryUpload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 50 * 1024 * 1024 }, // 50MB max (for APKs)
});

// Protect all feature routes
router.use(authenticate);

// Safe Browsing (legacy single URL check)
router.post('/check-url', featureLimiter, SafeBrowsingController.checkUrl);

// 2F: Advanced Link & QR (Quishing) — deep scan with redirect chain + Safe Browsing batch
router.post('/check-link', featureLimiter, QuishingController.checkLink);
router.post('/check-qr', featureLimiter, QuishingController.checkQr);

// 2H: NLP-based Message Analysis
router.post('/analyze-message', featureLimiter, NlpMessageController.analyzeMessage);

// 2E: PDF Document Scanning
router.post('/scan-pdf', featureLimiter, memoryUpload.single('file'), PdfScanController.scanPdf);

// 2G: APK & Malicious File Detection
router.post('/scan-apk', featureLimiter, memoryUpload.single('file'), ApkScanController.scanApk);

// Voice Scam Detection (Premium only — enforced within controller)
router.post('/analyze-voice', featureLimiter, memoryUpload.single('file'), VoiceScanController.analyzeVoice);

// AI Risk Score V2 — Centralized Evaluator
router.post('/evaluate-risk', featureLimiter, RiskEvaluationController.evaluate);
>>>>>>> dev-ui2

// Subscriptions
router.get('/plans', SubscriptionController.getPlans);
router.get('/subscription', SubscriptionController.getMySubscription);
router.post('/subscription', SubscriptionController.createSubscription);

// Points
router.get('/points', PointsController.getMyPoints);
<<<<<<< HEAD
router.post('/points', PointsController.addPoints);

// Points
router.get('/points', PointsController.getMyPoints);
router.post('/points', PointsController.addPoints);
=======
router.post('/points', isAdmin, PointsController.addPoints);
>>>>>>> dev-ui2

// Leaderboards
router.get('/leaderboard', LeaderboardController.getGlobalLeaderboard);
router.get('/leaderboard/me', LeaderboardController.getMyRank);

// Badges
router.get('/badges', BadgeController.getMyBadges);
router.get('/badges/all', BadgeController.getAllBadges);

<<<<<<< HEAD

router.post('/behavioral', BehavioralController.logEvent);
=======
router.post('/behavioral', featureLimiter, BehavioralController.logEvent);
>>>>>>> dev-ui2
router.get('/behavioral', BehavioralController.getMyEvents);

export default router;
