import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
import { RewardsController } from '../controllers/rewards.controller';
import { BadgeController } from '../controllers/badge.controller';
import { SafeBrowsingController } from '../controllers/safebrowsing.controller';
import { RiskEvaluationController } from '../controllers/risk-evaluation.controller';
import { LeaderboardController } from '../controllers/leaderboard.controller';
import { QuishingController } from '../controllers/quishing.controller';
import { NlpMessageController } from '../controllers/nlp-message.controller';

import passport from 'passport';

const router = Router();

// Protect all feature routes
router.use(passport.authenticate('jwt', { session: false }));

// Safe Browsing (legacy single URL check)
router.post('/check-url', SafeBrowsingController.checkUrl);

// 2F: Advanced Link & QR (Quishing) — deep scan with redirect chain + Safe Browsing batch
router.post('/check-link', QuishingController.checkLink);
router.post('/check-qr', QuishingController.checkQr);

// 2H: NLP-based Message Analysis
router.post('/analyze-message', NlpMessageController.analyzeMessage);

// AI Risk Score V2 — Centralized Evaluator
router.post('/evaluate-risk', RiskEvaluationController.evaluate);

// Subscriptions
router.get('/plans', SubscriptionController.getPlans);
router.get('/subscription', SubscriptionController.getMySubscription);
router.post('/subscription', SubscriptionController.createSubscription);

// Points
router.get('/points', PointsController.getMyPoints);
router.post('/points', PointsController.addPoints);

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
