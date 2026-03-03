import { Router } from 'express';
import { AlertController } from '../controllers/alert.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Public/Aggregate Routes (but still requiring login for the app)
router.get('/trending', authenticate, AlertController.getTrendingAlerts);
<<<<<<< HEAD
=======
router.get('/daily-digest', authenticate, AlertController.getDailyDigest);

// Personal Alerts
router.get('/', authenticate, AlertController.getUserAlerts);
router.patch('/read-all', authenticate, AlertController.markAllAsRead);
router.post('/:id/resolve', authenticate, AlertController.resolveAlert);
router.get('/seed', authenticate, AlertController.seedDemoAlerts);
>>>>>>> dev-ui2

// Personal Preferences
router.get('/preferences', authenticate, AlertController.getPreferences);
router.post('/subscribe', authenticate, AlertController.subscribeToAlerts);

export default router;
