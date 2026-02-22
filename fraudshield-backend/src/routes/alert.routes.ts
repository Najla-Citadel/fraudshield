import { Router } from 'express';
import { AlertController } from '../controllers/alert.controller';
import { authenticate } from '../middleware/auth.middleware';

const router = Router();

// Public/Aggregate Routes (but still requiring login for the app)
router.get('/trending', authenticate, AlertController.getTrendingAlerts);

// Personal Preferences
router.get('/preferences', authenticate, AlertController.getPreferences);
router.post('/subscribe', authenticate, AlertController.subscribeToAlerts);

export default router;
