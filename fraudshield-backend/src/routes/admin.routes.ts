import { Router } from 'express';
import { AdminController } from '../controllers/admin.controller';
import { isAdmin } from '../middleware/admin.middleware';
import passport from 'passport';

const router = Router();

// Protected admin routes
router.use(passport.authenticate('jwt', { session: false }));
router.use(isAdmin);

router.get('/alerts', AdminController.getAlerts);
router.get('/transactions/:id', AdminController.getTransaction);
router.post('/label-transaction', AdminController.labelTransaction);

// User Management
router.get('/users', AdminController.getUsers);
router.get('/users/:id', AdminController.getUserById);
router.patch('/users/:id/role', AdminController.updateUserRole);
router.patch('/users/:id', AdminController.updateUser);

// Scam Report Management
router.get('/reports', AdminController.getReports);
router.patch('/reports/:id/status', AdminController.updateReportStatus);
router.delete('/reports/:id', AdminController.deleteReport);

// Subscription Plan Management
router.get('/subscription-plans', AdminController.getSubscriptionPlans);
router.post('/subscription-plans', AdminController.createSubscriptionPlan);
router.put('/subscription-plans/:id', AdminController.updateSubscriptionPlan);
router.delete('/subscription-plans/:id', AdminController.deleteSubscriptionPlan);

// Badge Definition Management
router.get('/badges', AdminController.getBadges);
router.post('/badges', AdminController.createBadge);
router.put('/badges/:id', AdminController.updateBadge);
router.delete('/badges/:id', AdminController.deleteBadge);

// Store & Rewards Management
router.get('/rewards', AdminController.getRewards);
router.post('/rewards', AdminController.createReward);
router.put('/rewards/:id', AdminController.updateReward);
router.delete('/rewards/:id', AdminController.deleteReward);
router.get('/redemptions', AdminController.getRedemptions);
router.patch('/redemptions/:id/status', AdminController.updateRedemptionStatus);

// Threat Intelligence Broadcasting
router.get('/broadcasts', AdminController.getBroadcasts);
router.post('/broadcasts', AdminController.createBroadcast);
router.put('/broadcasts/:id', AdminController.updateBroadcast);
router.delete('/broadcasts/:id', AdminController.deleteBroadcast);

// Fraud Analysis & Labeling
router.get('/transactions', AdminController.getTransactions);
router.get('/fraud-labels', AdminController.getFraudLabels);
router.post('/fraud-labels', AdminController.createFraudLabel);
router.delete('/fraud-labels/:id', AdminController.deleteFraudLabel);

// Dashboard Statistics
router.get('/stats', AdminController.getStats);

export default router;
