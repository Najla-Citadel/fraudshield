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
router.patch('/users/:id/role', AdminController.updateUserRole);

// Scam Report Management
router.get('/reports', AdminController.getReports);
router.patch('/reports/:id/status', AdminController.updateReportStatus);

// Dashboard Statistics
router.get('/stats', AdminController.getStats);

export default router;
