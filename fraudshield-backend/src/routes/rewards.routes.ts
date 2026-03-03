import { Router } from 'express';
import { RewardsController } from '../controllers/rewards.controller';
<<<<<<< HEAD
import passport from 'passport';
=======
import { authenticate } from '../middleware/auth.middleware';
>>>>>>> dev-ui2

const router = Router();

// Protect all rewards routes
<<<<<<< HEAD
router.use(passport.authenticate('jwt', { session: false }));
=======
router.use(authenticate);
>>>>>>> dev-ui2

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
