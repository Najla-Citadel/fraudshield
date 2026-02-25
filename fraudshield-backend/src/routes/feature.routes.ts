import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
import { RewardsController } from '../controllers/rewards.controller';
import { BadgeController } from '../controllers/badge.controller';
import { SafeBrowsingController } from '../controllers/safebrowsing.controller';
import { RiskEvaluationController } from '../controllers/risk-evaluation.controller';
import { LeaderboardController } from '../controllers/leaderboard.controller';

import passport from 'passport';

const router = Router();

// Protect all feature routes
router.use(passport.authenticate('jwt', { session: false }));

// Safe Browsing
router.post('/check-url', SafeBrowsingController.checkUrl);

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
