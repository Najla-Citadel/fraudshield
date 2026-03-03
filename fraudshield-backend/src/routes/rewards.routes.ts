import { Router } from 'express';
import { RewardsController } from '../controllers/rewards.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Protect all rewards routes
router.use(authenticate);

// Available rewards
router.get('/', RewardsController.getRewards);

// Redemption
router.post('/redeem', RewardsController.redeemReward);

// User's redemption history
router.get('/redemptions', RewardsController.getMyRedemptions);

// Daily login reward
router.post('/daily', RewardsController.claimDailyReward);

// Seed initial rewards (admin/development only)
router.post('/seed', RewardsController.seedRewards);

export default router;
