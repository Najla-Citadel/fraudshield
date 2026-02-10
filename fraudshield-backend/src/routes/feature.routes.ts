import { Router } from 'express';
import { SubscriptionController, PointsController, BehavioralController } from '../controllers/feature.controller';
import passport from 'passport';

const router = Router();

// Protect all feature routes
router.use(passport.authenticate('jwt', { session: false }));

// Subscriptions
router.get('/plans', SubscriptionController.getPlans);
router.get('/subscription', SubscriptionController.getMySubscription);
router.post('/subscription', SubscriptionController.createSubscription);

// Points
router.get('/points', PointsController.getMyPoints);
router.post('/points', PointsController.addPoints);

router.post('/behavioral', BehavioralController.logEvent);
router.get('/behavioral', BehavioralController.getMyEvents);

export default router;
