import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
import { RewardsController } from '../controllers/rewards.controller';
import { BadgeController } from '../controllers/badge.controller';
import { SafeBrowsingController } from '../controllers/safebrowsing.controller';

import passport from 'passport';

const router = Router();

// Protect all feature routes
router.use(passport.authenticate('jwt', { session: false }));

// Safe Browsing
router.post('/check-url', SafeBrowsingController.checkUrl);

// Subscriptions
router.get('/plans', SubscriptionController.getPlans);
router.get('/subscription', SubscriptionController.getMySubscription);
router.post('/subscription', SubscriptionController.createSubscription);

// Points
router.get('/points', PointsController.getMyPoints);
router.post('/points', PointsController.addPoints);

// Rewards
router.get('/rewards', RewardsController.getRewards);
router.post('/rewards/redeem', RewardsController.redeemReward);
router.get('/redemptions', RewardsController.getMyRedemptions);
router.post('/rewards/daily', RewardsController.claimDailyReward);
router.post('/rewards/seed', RewardsController.seedRewards); // Admin/dev only

// Badges
router.get('/badges', BadgeController.getMyBadges);
router.get('/badges/all', BadgeController.getAllBadges);


router.post('/behavioral', BehavioralController.logEvent);
router.get('/behavioral', BehavioralController.getMyEvents);

export default router;
